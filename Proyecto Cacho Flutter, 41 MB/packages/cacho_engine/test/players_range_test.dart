import 'package:cacho_engine/cacho_engine.dart';
import 'package:test/test.dart';

/// Partidas de 2 a 6 jugadores (corrección del usuario, 26-oct 09:35
/// "me equivoqué eran 6", reemplaza el máximo 5 de la decisión 07:32):
/// el motor acepta 6 y rechaza 7 y 8.
void main() {
  test('6 jugadores: parte y se juega una resolución', () {
    final ids = [for (var i = 1; i <= 6; i++) 'J$i'];
    final g = GameEngine(
      config: GameConfig.cachoCompleto(),
      playerList: [for (final id in ids) (id: id, name: id)],
      roller: ScriptedDiceRoller(
          [6, 1, 2, 3, 4, for (var i = 0; i < 200; i++) (i % 6) + 1]),
    );
    g.startGame();
    expect(g.players.length, 6);
    expect(g.totalDiceInPlay, 30);
    final starter = g.currentPlayerId!;
    g.bid(starter, const Bid(3, 6));
    final res = g.dudo(g.currentPlayerId!);
    expect(res.type, ResolutionType.dudo);
    expect(g.totalDiceInPlay, 29);
  });

  test('5 jugadores: sigue válido dentro del rango 2..6', () {
    final ids = [for (var i = 1; i <= 5; i++) 'J$i'];
    final g = GameEngine(
      config: GameConfig.cachoCompleto(),
      playerList: [for (final id in ids) (id: id, name: id)],
      roller: ScriptedDiceRoller(
          [6, 1, 2, 3, 4, for (var i = 0; i < 200; i++) (i % 6) + 1]),
    );
    g.startGame();
    expect(g.players.length, 5);
    expect(g.totalDiceInPlay, 25);
  });

  test('2 jugadores: mínimo válido, parte y juega', () {
    final g = GameEngine(
      config: GameConfig.cachoCompleto(),
      playerList: const [(id: 'A', name: 'A'), (id: 'B', name: 'B')],
      roller: ScriptedDiceRoller(
          [6, 1, for (var i = 0; i < 100; i++) (i % 6) + 1]),
    );
    g.startGame();
    expect(g.players.length, 2);
    expect(g.totalDiceInPlay, 10);
  });

  test('7 y 8 jugadores: fuera de rango', () {
    for (final n in [7, 8]) {
      final ids = [for (var i = 1; i <= n; i++) 'J$i'];
      expect(
        () => GameEngine(
          config: GameConfig.cachoCompleto(),
          playerList: [for (final id in ids) (id: id, name: id)],
          roller: ScriptedDiceRoller([1]),
        ),
        throwsArgumentError,
        reason: '$n jugadores deben rechazarse con máximo 6',
      );
    }
  });
}
