// Paridad con el motor Dart: mismos guiones, mismos resultados esperados
// que packages/cacho_engine/test/.
import test from 'node:test';
import assert from 'node:assert/strict';
import {
  GameEngine,
  ScriptedDiceRoller,
  IllegalMove,
  raiseError,
  countForBid,
  isPasoHand,
  configForPreset,
  calzoThreshold,
} from '../src/engine.js';

const players = (...ids) => ids.map((id) => ({ id, name: id }));
const code = (fn) => {
  try {
    fn();
  } catch (e) {
    assert.ok(e instanceof IllegalMove, `se esperaba IllegalMove, llegó: ${e}`);
    return e.code;
  }
  throw new Error('se esperaba que lanzara IllegalMove');
};

test('subida clásica y ases (paridad Dart)', () => {
  assert.equal(raiseError(null, { quantity: 3, face: 1 }, 20), 'ases_para_partir');
  assert.equal(raiseError({ quantity: 3, face: 4 }, { quantity: 4, face: 2 }, 20), null);
  assert.equal(raiseError({ quantity: 3, face: 4 }, { quantity: 3, face: 5 }, 20), null);
  assert.equal(raiseError({ quantity: 3, face: 4 }, { quantity: 3, face: 3 }, 20), 'apuesta_no_supera');
  assert.equal(raiseError({ quantity: 5, face: 3 }, { quantity: 3, face: 1 }, 20), null);
  assert.equal(raiseError({ quantity: 5, face: 3 }, { quantity: 2, face: 1 }, 20), 'ases_mitad');
  assert.equal(raiseError({ quantity: 2, face: 1 }, { quantity: 5, face: 4 }, 20), null);
  assert.equal(raiseError({ quantity: 2, face: 1 }, { quantity: 4, face: 4 }, 20), 'salida_ases_doble_mas_uno');
  assert.equal(raiseError({ quantity: 3, face: 4 }, { quantity: 21, face: 4 }, 20), 'cantidad_supera_total');
});

test('regla de ases: ejemplos del usuario y desactivación (paridad Dart)', () => {
  // De 8 Cuadras -> 4 ases; de 7 Cuadras -> 4 ases; de 4 ases -> 9 de otra pinta.
  assert.equal(raiseError({ quantity: 8, face: 4 }, { quantity: 4, face: 1 }, 30), null);
  assert.equal(raiseError({ quantity: 7, face: 4 }, { quantity: 4, face: 1 }, 30), null);
  assert.equal(raiseError({ quantity: 4, face: 1 }, { quantity: 9, face: 6 }, 30), null);
  assert.equal(raiseError({ quantity: 4, face: 1 }, { quantity: 8, face: 6 }, 30), 'salida_ases_doble_mas_uno');
  // Desactivada: los ases son una pinta más, sin conversión.
  assert.equal(raiseError({ quantity: 5, face: 3 }, { quantity: 3, face: 1 }, 20, false), 'apuesta_no_supera');
  assert.equal(raiseError({ quantity: 5, face: 3 }, { quantity: 6, face: 1 }, 20, false), null);
  assert.equal(raiseError({ quantity: 2, face: 1 }, { quantity: 2, face: 4 }, 20, false), null);
});

test('regla de ases desactivada: los 1 no cuentan como comodines', () => {
  const g = new GameEngine({
    config: configForPreset('clasico', { acesRuleEnabled: false }),
    roller: new ScriptedDiceRoller([
      6, 1,
      1, 1, 1, 1, 1, // A: puros ases
      6, 2, 2, 2, 2, // B: un solo 6 real
      2, 2, 2, 2,
      3, 3, 3, 3, 3,
    ]),
    players: players('A', 'B'),
  });
  g.startGame();
  g.bid('A', { quantity: 5, face: 6 });
  const res = g.dudo('B');
  assert.equal(res.actualCount, 1);
  assert.equal(res.loserId, 'A');
});

test('conteo con comodines y mano de Paso', () => {
  const hands = [[6, 6, 1, 2, 3], [6, 5, 4, 3, 2]];
  assert.equal(countForBid(hands, { quantity: 4, face: 6 }, true), 4);
  assert.equal(countForBid(hands, { quantity: 4, face: 6 }, false), 3);
  assert.equal(countForBid(hands, { quantity: 1, face: 1 }, true), 1);
  assert.equal(isPasoHand([1, 2, 3, 4, 5]), true);
  assert.equal(isPasoHand([2, 2, 3, 3, 3]), true);
  assert.equal(isPasoHand([1, 1, 2, 3, 4]), false);
  assert.equal(isPasoHand([2, 2, 2, 2, 3]), false);
});

test('umbral de Calzo fijo y presets', () => {
  const c = configForPreset('completo');
  assert.equal(calzoThreshold(c, 20), 10);
  assert.equal(calzoThreshold(c, 25), 13);
  const clasico = configForPreset('clasico');
  assert.equal(clasico.pasoEnabled, false);
  assert.equal(clasico.kamikazeEnabled, false);
});

test('dudo con guion: apuesta cierta, pierde quien duda', () => {
  const g = new GameEngine({
    config: configForPreset('clasico'),
    roller: new ScriptedDiceRoller([
      6, 1,
      6, 6, 6, 1, 2,
      6, 5, 4, 3, 2,
      2, 2, 2, 2, 2,
      3, 3, 3, 3,
    ]),
    players: players('A', 'B'),
  });
  assert.equal(g.startGame(), 'A');
  g.bid('A', { quantity: 4, face: 6 });
  const res = g.dudo('B');
  assert.equal(res.actualCount, 5);
  assert.equal(res.loserId, 'B');
  assert.equal(g.playerById('B').diceCount, 4);
  assert.equal(g.currentPlayerId, 'B');
});

test('paso bloqueado con menos de 5 y como primera jugada (códigos Dart)', () => {
  const g = new GameEngine({
    config: configForPreset('completo'),
    roller: new ScriptedDiceRoller([6, 1, 1, ...Array(15).fill(2)]),
    players: players('A', 'B', 'C'),
  });
  g.startGame();
  assert.equal(code(() => g.paso('A')), 'paso_primera_jugada');
});

test('kamikaze: empate sin ganador si todos quedan sin dados', () => {
  const config = configForPreset('completo', { dicePerPlayer: 2 });
  const g = new GameEngine({
    config,
    roller: new ScriptedDiceRoller([
      6, 1,
      2, 2, 2, 2, // ronda 1
      6, // kamikaze A
      6, 6, // kamikaze B
    ]),
    players: players('A', 'B'),
  });
  g.startGame();
  g.bid('A', { quantity: 1, face: 6 });
  g.dudo('B'); // A baja a 1, único -> oferta
  assert.equal(g.phase, 'kamikazeOffer');
  assert.equal(g.kamikazeOfferPlayerId, 'A');
  g.respondKamikaze('A', true);
  g.chooseKamikazeFace('A', 6);
  assert.equal(g.phase, 'finished');
  assert.equal(g.isDraw, true);
  assert.equal(g.winnerId, null);
});

test('kamikaze simultáneo: la oportunidad queda pendiente y se ofrece después', () => {
  const config = configForPreset('completo', { dicePerPlayer: 2 });
  const g = new GameEngine({
    config,
    roller: new ScriptedDiceRoller([
      6, 1, 1,
      2, 2, 2, 2, 2, 2, // ronda 1
      3, 2, 5, 2, 5, // kamikaze de A eligiendo Pato(2)
      3, 4, 5, // ronda siguiente, 1 dado c/u
      2, 2, 2, 2, // ronda tras oferta diferida (A1 B2 C1)
    ]),
    players: players('A', 'B', 'C'),
  });
  g.startGame();
  g.bid('A', { quantity: 1, face: 6 });
  g.dudo('B');
  g.respondKamikaze('A', true);
  const res = g.chooseKamikazeFace('A', 2);
  assert.deepEqual(res.kamikazeLosses, { A: 0, B: 1, C: 1 });
  assert.equal(g.phase, 'playing'); // B y C con 1 a la vez: sin oferta
  assert.equal(g.playerById('B').kamikazeOfferedOnce, false);
  assert.equal(g.playerById('C').kamikazeOfferedOnce, false);
  g.bid('A', { quantity: 1, face: 3 });
  // B calza exacto (hay un solo Tren) pero el total en mesa es 3 de 6
  // iniciales (la mitad exacta): desde el 25-oct la recuperación exige
  // ESTRICTAMENTE más de la mitad, así que B NO recupera y los tres
  // quedan con 1 dado: sigue sin oferta para nadie (pendiente).
  const resCalzo = g.calzo('B');
  assert.equal(resCalzo.recoveryBlocked, true);
  assert.equal(g.playerById('B').diceCount, 1);
  assert.equal(g.phase, 'playing');
  assert.equal(g.kamikazeOfferPlayerId, null);
  assert.equal(g.playerById('B').kamikazeOfferedOnce, false);
  assert.equal(g.playerById('C').kamikazeOfferedOnce, false);
});
