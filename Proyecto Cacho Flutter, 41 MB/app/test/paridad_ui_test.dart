import 'package:cacho_app/state/match_controller.dart';
import 'package:cacho_engine/bots.dart';
import 'package:cacho_engine/cacho_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MatchController local() => MatchController.local(
        nickname: 'Ana',
        botCount: 1,
        difficulty: BotDifficulty.media,
        config: GameConfig.clasico(),
        useTurnTimer: false,
      );

  test('emotes locales: mostrar, secuencia y retirada por secuencia', () {
    final c = local();
    c.startLocal();
    expect(c.emoteGlyph, isNull);
    expect(c.sendEmote('😂'), isTrue);
    expect(c.emotePlayerId, 'yo');
    expect(c.emoteGlyph, '😂');
    final seq = c.emoteSeq;
    expect(seq, greaterThan(0));
    // Una retirada con secuencia vieja no borra la reacción nueva.
    c.sendEmote('🔥');
    c.clearEmote(seq);
    expect(c.emoteGlyph, '🔥');
    c.clearEmote(c.emoteSeq);
    expect(c.emoteGlyph, isNull);
    expect(c.emotePlayerId, isNull);
    c.dispose();
  });

  test('emotes: glifo fuera del conjunto se ignora', () {
    final c = local();
    c.startLocal();
    c.sendEmote('🤔');
    expect(c.emoteGlyph, isNull);
    expect(c.emoteSeq, 0);
    expect(MatchController.emotes.length, 5);
    c.dispose();
  });

  test('emotes recibidas: showEmote acepta cualquier remitente', () {
    // Es el camino que usará el caso 'emote' del servidor cuando el
    // relay exista; hoy no se dispara porque el servidor aún no lo
    // difunde (no se prueba la red aquí).
    final c = local();
    c.startLocal();
    c.showEmote('bot1', '👏');
    expect(c.emotePlayerId, 'bot1');
    expect(c.emoteGlyph, '👏');
    c.dispose();
  });
}
