import 'package:cacho_app/state/match_controller.dart';
import 'package:cacho_app/texts.dart';
import 'package:cacho_engine/bots.dart';
import 'package:cacho_engine/cacho_engine.dart';
import 'package:flutter_test/flutter_test.dart';

/// Conexión UI de la regla del Calzo (25-oct): el flag
/// recoveryBlocked viaja del motor a la resolución de la UI y el
/// veredicto corto es "exacto pero sin recuperación" — sin inferir
/// "falló" de gainerId == null (en exacto bloqueado gainerId y
/// loserId son null: no gana ni pierde nadie).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MatchController localController() {
    final c = MatchController.local(
      nickname: 'Ana',
      botCount: 1,
      difficulty: BotDifficulty.media,
      config: GameConfig.clasico(),
      roller: ScriptedDiceRoller([
        6, 1,
        2, 2, 2, 2, 2,
        3, 3, 3, 3, 3,
      ]),
      useTurnTimer: false,
    );
    c.startLocal();
    return c;
  }

  test('veredicto calzo bloqueado: exacto pero sin recuperación', () {
    final c = localController();
    addTearDown(c.dispose);
    final r = UiResolution(
      type: 'calzo',
      challengerId: 'yo',
      recoveryBlocked: true,
    );
    expect(r.gainerId, isNull);
    expect(r.loserId, isNull);
    expect(verdictText(c, r), 'exacto pero sin recuperación');
  });

  test('veredicto calzoPaso bloqueado: mismo texto, no es un fallo', () {
    final c = localController();
    addTearDown(c.dispose);
    final r = UiResolution(
      type: 'calzoPaso',
      challengerId: 'yo',
      recoveryBlocked: true,
    );
    expect(verdictText(c, r), 'exacto pero sin recuperación');
  });

  test('calzo normal con gainer no cambia', () {
    final c = localController();
    addTearDown(c.dispose);
    final r = UiResolution(
      type: 'calzo',
      challengerId: 'yo',
      gainerId: 'yo',
    );
    expect(verdictText(c, r), contains('recupera 1 dado'));
  });

  test('fromEngine y fromJson preservan recoveryBlocked', () {
    const engineRes = Resolution(
      type: ResolutionType.calzo,
      recoveryBlocked: true,
    );
    final fromEngine = UiResolution.fromEngine(engineRes);
    expect(fromEngine.recoveryBlocked, isTrue);
    expect(fromEngine.gainerId, isNull);
    expect(fromEngine.loserId, isNull);

    final fromJson = UiResolution.fromJson({
      'type': 'calzoPaso',
      'recoveryBlocked': true,
    });
    expect(fromJson.recoveryBlocked, isTrue);
    final missing = UiResolution.fromJson({'type': 'calzo'});
    expect(missing.recoveryBlocked, isFalse);
  });
}
