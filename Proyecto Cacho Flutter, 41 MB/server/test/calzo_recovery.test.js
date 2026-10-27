// Paridad JS de packages/cacho_engine/test/calzo_recovery_test.dart.
// Regla (usuario, 25-oct): el Calzo exacto solo recupera si el total en
// mesa es ESTRICTAMENTE MÁS de la mitad del total inicial:
// totalActual * 2 > totalInicial. El intento sigue siempre permitido.
import test from 'node:test';
import assert from 'node:assert/strict';
import {
  GameEngine,
  ScriptedDiceRoller,
  configForPreset,
} from '../src/engine.js';

const players = (...ids) => ids.map((id) => ({ id, name: id }));

function game(ids, preset) {
  const g = new GameEngine({
    config: configForPreset(preset),
    roller: new ScriptedDiceRoller([
      6, 1, 2, 3, // desempate: parte A
      ...Array(20).fill(2), // ronda 1 (se sobrescribe en cada test)
      ...Array(80).fill(2), // cola para la ronda siguiente
    ]),
    players: players(...ids),
  });
  g.startGame();
  return g;
}

function setCalzoScenario(g, { hands, counts, bid, calzer }) {
  for (const [id, hand] of Object.entries(hands)) {
    g.playerById(id).hand = [...hand];
  }
  for (const [id, n] of Object.entries(counts)) {
    g.playerById(id).diceCount = n;
  }
  g.currentBid = bid;
  g.currentPlayerId = calzer;
}

test('recuperación: 20 iniciales, 11 en mesa, exacto recupera', () => {
  const g = game(['A', 'B', 'C', 'D'], 'clasico');
  setCalzoScenario(g, {
    hands: { A: [6, 6, 2], B: [6, 3, 3], C: [4, 4, 4], D: [5, 5] },
    counts: { A: 3, B: 3, C: 3, D: 2 },
    bid: { quantity: 3, face: 6 },
    calzer: 'B',
  });
  assert.equal(g.initialTotalDice, 20);
  assert.equal(g.totalDiceInPlay, 11);
  assert.equal(g.calzoRecoveryAllowed, true);
  const res = g.calzo('B');
  assert.equal(res.actualCount, 3);
  assert.equal(res.gainerId, 'B');
  assert.equal(res.loserId, null);
  assert.equal(res.recoveryBlocked, false);
  assert.equal(g.playerById('B').diceCount, 4);
  assert.equal(g.currentPlayerId, 'B');
});

test('recuperación: 20 iniciales, 10 en mesa, exacto NO recupera ni pierde', () => {
  const g = game(['A', 'B', 'C', 'D'], 'clasico');
  setCalzoScenario(g, {
    hands: { A: [6, 6, 2], B: [6, 3], C: [4, 4, 4], D: [5, 5] },
    counts: { A: 3, B: 2, C: 3, D: 2 },
    bid: { quantity: 3, face: 6 },
    calzer: 'B',
  });
  assert.equal(g.totalDiceInPlay, 10);
  assert.equal(g.calzoRecoveryAllowed, false);
  const res = g.calzo('B');
  assert.equal(res.actualCount, 3);
  assert.equal(res.gainerId, null);
  assert.equal(res.loserId, null);
  assert.equal(res.recoveryBlocked, true);
  assert.equal(g.playerById('B').diceCount, 2);
  assert.equal(g.currentPlayerId, 'B');
});

test('recuperación: 20 iniciales, 10 en mesa, calzo fallido pierde siempre', () => {
  const g = game(['A', 'B', 'C', 'D'], 'clasico');
  setCalzoScenario(g, {
    hands: { A: [6, 6, 2], B: [6, 3], C: [4, 4, 4], D: [5, 5] },
    counts: { A: 3, B: 2, C: 3, D: 2 },
    bid: { quantity: 4, face: 6 }, // hay 3: no es exacto
    calzer: 'B',
  });
  const res = g.calzo('B');
  assert.equal(res.actualCount, 3);
  assert.equal(res.loserId, 'B');
  assert.equal(res.recoveryBlocked, false);
  assert.equal(g.playerById('B').diceCount, 1);
});

test('recuperación: intento permitido con total bajo, sin error de bloqueo', () => {
  const g = game(['A', 'B', 'C', 'D'], 'clasico');
  setCalzoScenario(g, {
    hands: { A: [6, 6, 2], B: [6, 3], C: [4, 4], D: [5, 5] },
    counts: { A: 3, B: 2, C: 2, D: 2 },
    bid: { quantity: 4, face: 6 },
    calzer: 'B',
  });
  assert.equal(g.totalDiceInPlay, 9);
  assert.equal(g.canCalzoNow, true);
  const res = g.calzo('B'); // legal: resuelve, no lanza
  assert.equal(res.type, 'calzo');
  assert.equal(res.loserId, 'B');
});

test('recuperación: 15 iniciales, 8 en mesa recupera y 7 no recupera', () => {
  const g8 = game(['A', 'B', 'C'], 'clasico');
  setCalzoScenario(g8, {
    hands: { A: [6, 6, 2], B: [6, 3, 3], C: [4, 4] },
    counts: { A: 3, B: 3, C: 2 },
    bid: { quantity: 3, face: 6 },
    calzer: 'B',
  });
  assert.equal(g8.initialTotalDice, 15);
  assert.equal(g8.totalDiceInPlay, 8);
  const r8 = g8.calzo('B');
  assert.equal(r8.gainerId, 'B');
  assert.equal(r8.recoveryBlocked, false);
  assert.equal(g8.playerById('B').diceCount, 4);

  const g7 = game(['A', 'B', 'C'], 'clasico');
  setCalzoScenario(g7, {
    hands: { A: [6, 6, 2], B: [6, 3], C: [4, 4] },
    counts: { A: 3, B: 2, C: 2 },
    bid: { quantity: 3, face: 6 },
    calzer: 'B',
  });
  assert.equal(g7.totalDiceInPlay, 7);
  const r7 = g7.calzo('B');
  assert.equal(r7.gainerId, null);
  assert.equal(r7.loserId, null);
  assert.equal(r7.recoveryBlocked, true);
  assert.equal(g7.playerById('B').diceCount, 2);
});

test('recuperación CalzoPaso: 10 en mesa verdadero no gana, falso pierde, 14 gana', () => {
  const setup = (handA, counts) => {
    const g = game(['A', 'B', 'C', 'D'], 'completo');
    g.playerById('A').hand = [...handA];
    g.playerById('B').hand = [2, 2];
    g.playerById('C').hand = [3, 3];
    g.playerById('D').hand = [4];
    for (const [id, n] of Object.entries(counts)) {
      g.playerById(id).diceCount = n;
    }
    g.pendingPasoPlayerId = 'A';
    g.currentPlayerId = 'B';
    return g;
  };
  const low = { A: 5, B: 2, C: 2, D: 1 };
  const gTrue = setup([1, 2, 3, 4, 5], low);
  assert.equal(gTrue.totalDiceInPlay, 10);
  const rTrue = gTrue.calzoPaso('B');
  assert.equal(rTrue.gainerId, null);
  assert.equal(rTrue.loserId, null);
  assert.equal(rTrue.recoveryBlocked, true);
  assert.equal(gTrue.playerById('B').diceCount, 2);

  const gFalse = setup([2, 2, 2, 2, 3], low);
  const rFalse = gFalse.calzoPaso('B');
  assert.equal(rFalse.loserId, 'B');
  assert.equal(rFalse.recoveryBlocked, false);
  assert.equal(gFalse.playerById('B').diceCount, 1);

  const gHigh = setup([1, 2, 3, 4, 5], { A: 5, B: 3, C: 3, D: 3 });
  assert.equal(gHigh.totalDiceInPlay, 14);
  const rHigh = gHigh.calzoPaso('B');
  assert.equal(rHigh.gainerId, 'B');
  assert.equal(rHigh.recoveryBlocked, false);
  assert.equal(gHigh.playerById('B').diceCount, 4);
});

test('C11 (a): perfecto con 17 de 20, los demás pierden un dado y el calzador no gana', () => {
  const g = game(['A', 'B', 'C', 'D'], 'clasico');
  setCalzoScenario(g, {
    hands: { A: [6, 6, 2, 2, 2], B: [6, 3, 3, 3], C: [4, 4, 4, 4], D: [5, 5, 5, 5] },
    counts: { A: 5, B: 4, C: 4, D: 4 },
    bid: { quantity: 3, face: 6 },
    calzer: 'A',
  });
  assert.equal(g.totalDiceInPlay, 17);
  assert.equal(g.calzoRecoveryAllowed, true);
  const res = g.calzo('A');
  assert.equal(res.actualCount, 3);
  assert.deepEqual(res.massLoserIds, ['B', 'C', 'D']);
  assert.equal(res.gainerId, null);
  assert.equal(res.recoveryBlocked, false);
  assert.equal(g.playerById('A').diceCount, 5);
  assert.equal(g.playerById('B').diceCount, 3);
  assert.equal(g.playerById('C').diceCount, 3);
  assert.equal(g.playerById('D').diceCount, 3);
  assert.equal(g.currentPlayerId, 'A'); // parte quien calzó
});

test('C11 (b): perfecto con 10 de 20 BLOQUEADO, nadie gana ni pierde, recoveryBlocked, el calzador parte', () => {
  // C11 (decisión 26-oct) reemplaza la postura anterior (25-oct) que
  // mantenía el perfecto con total bajo: ahora queda bloqueado, igual
  // que el exacto sin recuperación (C4). Preset completo (no clásico)
  // para que la oferta de Kamikaze a D esté activa en el cierre.
  const g = game(['A', 'B', 'C', 'D'], 'completo');
  setCalzoScenario(g, {
    hands: { A: [6, 6, 2, 2, 2], B: [6, 3], C: [4, 4], D: [5] },
    counts: { A: 5, B: 2, C: 2, D: 1 },
    bid: { quantity: 3, face: 6 },
    calzer: 'A',
  });
  assert.equal(g.totalDiceInPlay, 10);
  assert.equal(g.calzoRecoveryAllowed, false);
  const res = g.calzo('A');
  assert.equal(res.actualCount, 3);
  assert.deepEqual(res.massLoserIds, []);
  assert.equal(res.gainerId, null);
  assert.equal(res.loserId, null);
  assert.equal(res.recoveryBlocked, true);
  assert.equal(g.playerById('A').diceCount, 5);
  assert.equal(g.playerById('B').diceCount, 2);
  assert.equal(g.playerById('C').diceCount, 2);
  assert.equal(g.playerById('D').diceCount, 1);
  // D queda con 1 dado: se le ofrece el Kamikaze y, al rechazarlo, la
  // ronda siguiente la parte el calzador.
  assert.equal(g.phase, 'kamikazeOffer');
  assert.equal(g.kamikazeOfferPlayerId, 'D');
  g.respondKamikaze('D', false);
  assert.equal(g.phase, 'playing');
  assert.equal(g.currentPlayerId, 'A');
});

// P11/P13 en JS (paridad con packages/cacho_engine/test/paso_test.dart).
// NOTA DE UBICACIÓN: engine.test.js queda fuera de los archivos de este
// frente, así que estos dos tests viven aquí de forma provisional; el
// coordinador puede moverlos a engine.test.js sin cambiar su contenido.
// P12 (paso_primera_jugada) ya está cubierto en engine.test.js.
test('P11/P13: máximo 1 Paso por ronda y no dos veces seguidas (mismo jugador)', () => {
  const build = (overrides) => {
    const g = new GameEngine({
      config: configForPreset('completo', overrides),
      roller: new ScriptedDiceRoller([
        6, 1, 1, 1, // parte A
        ...Array(20).fill(2), // ronda 1: 4 jugadores x 5
      ]),
      players: players('A', 'B', 'C', 'D'),
    });
    g.startGame();
    g.bid('A', { quantity: 1, face: 6 });
    g.paso('B');
    g.bid('C', { quantity: 2, face: 6 });
    g.bid('D', { quantity: 3, face: 6 });
    g.bid('A', { quantity: 4, face: 6 });
    return g; // turno de B por segunda vez en la ronda
  };
  const code = (fn) => {
    try { fn(); } catch (e) { return e.code; }
    throw new Error('se esperaba que lanzara IllegalMove');
  };
  // P11, default maxPasosPerPlayerPerRound = 1.
  assert.equal(code(() => build({}).paso('B')), 'paso_limite_ronda');
  // P13, con límite 3 manda la regla de no repetir.
  assert.equal(
    code(() => build({ maxPasosPerPlayerPerRound: 3 }).paso('B')),
    'paso_dos_veces_seguidas');
});

test('oferta diferida tras calzo con total sobre la mitad', () => {
  // B y C con 1 dado a la vez, sin oferta previa (estado posterior a un
  // Kamikaze simultáneo), pero con el total sobre la mitad: 4 jugadores,
  // 20 iniciales, 12 en mesa. B calza exacto, recupera y C queda único
  // con 1 dado -> oferta diferida a C.
  const g = game(['A', 'B', 'C', 'D'], 'completo');
  g.playerById('A').hand = [6, 6, 2, 2, 2];
  g.playerById('B').hand = [6];
  g.playerById('C').hand = [4];
  g.playerById('D').hand = [5, 5, 5, 5, 5];
  g.playerById('A').diceCount = 5;
  g.playerById('B').diceCount = 1;
  g.playerById('C').diceCount = 1;
  g.playerById('D').diceCount = 5;
  g.currentBid = { quantity: 3, face: 6 }; // hay exactamente 3 seises
  g.currentPlayerId = 'B';
  assert.equal(g.totalDiceInPlay, 12);
  const res = g.calzo('B');
  assert.equal(res.gainerId, 'B');
  assert.equal(res.recoveryBlocked, false);
  assert.equal(g.playerById('B').diceCount, 2);
  assert.equal(g.phase, 'kamikazeOffer');
  assert.equal(g.kamikazeOfferPlayerId, 'C');
  g.respondKamikaze('C', false);
  assert.equal(g.phase, 'playing');
  assert.equal(g.currentPlayerId, 'B');
});
