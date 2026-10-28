// Desbloqueo de audio del carrusel en iOS/Safari (28-oct).
// Causa raíz: los ticks del carrusel usan un pool de reproductores
// distinto del reproductor principal, y cada reproductor web crea
// su propio AudioContext, que nace suspendido y solo se reanuda
// dentro de un gesto del usuario. El pool se creaba perezosamente
// en el primer tack (callback de animación, fuera del gesto), así
// que en iPhone el tack quedaba mudo aunque todo estuviera
// encendido. unlock() debe precalentar el pool completo.
// No depende de hardware de audio real: en tests los plays se
// atrapan como en los demás tests de audio.
import 'package:flutter_test/flutter_test.dart';
import 'package:cacho_app/state/audio.dart';
import 'package:cacho_app/state/settings.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    Settings.instance.soundEffects = true;
    Settings.instance.music = true;
  });
  tearDown(() {
    Settings.instance.soundEffects = true;
    Settings.instance.music = true;
    AudioService.debugPlayListener = null;
  });

  test('unlock() precalienta el pool de ticks completo (4)', () async {
    await AudioService.instance.unlock();
    expect(AudioService.instance.tickPoolSize, 4);
  });

  test('tras unlock(), un tack sigue intentando sonar (tick.wav)', () async {
    await AudioService.instance.unlock();
    final played = <String>[];
    AudioService.debugPlayListener = played.add;
    AudioService.instance.tack();
    // _playTick es async: darle un respiro al intento.
    await Future.delayed(const Duration(milliseconds: 50));
    expect(played, contains('tick.wav'));
  });

  test('unlock() repetido no rompe el pool ni los tacks', () async {
    await AudioService.instance.unlock();
    await AudioService.instance.unlock();
    expect(AudioService.instance.tickPoolSize, 4);
    final played = <String>[];
    AudioService.debugPlayListener = played.add;
    AudioService.instance.tack();
    await Future.delayed(const Duration(milliseconds: 50));
    expect(played, contains('tick.wav'));
  });

  test('con efectos apagados, ningún tack suena tras unlock()', () async {
    // El respeto al interruptor (si el usuario apagó "Sonidos" a
    // propósito, sigue apagado) ya lo cubre _warmTickPool en
    // código; aquí solo se fija el efecto observable: silencio.
    Settings.instance.soundEffects = false;
    await AudioService.instance.unlock();
    final played = <String>[];
    AudioService.debugPlayListener = played.add;
    AudioService.instance.tack();
    await Future.delayed(const Duration(milliseconds: 50));
    expect(played, isEmpty);
  });
}
