// Sonido de ruleta al seleccionar salas (menú/lobby).
// No depende de hardware de audio: AudioService.debugPlayListener
// registra cada intento real de sonar (después del guard de efectos).
import 'package:flutter_test/flutter_test.dart';
import 'package:cacho_app/state/audio.dart';
import 'package:cacho_app/state/settings.dart';

void main() {
  // audioplayers necesita ServicesBinding (en la app real siempre
  // existe; en un test() plano no). Sin esto, AudioPlayer() filtra
  // un error asíncrono no capturado y el test falla aunque _play
  // ya atrape los errores de canal.
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

  test('la ruleta desacelera y no dura más que el cambio (~342 ms)', () {
    final intervals = AudioService.rouletteIntervalsMs;
    expect(intervals.length, 5); // 6 ticks, 5 intervalos entre ellos
    for (var i = 1; i < intervals.length; i++) {
      expect(intervals[i], greaterThan(intervals[i - 1]));
    }
    final total = intervals.reduce((a, b) => a + b) + 50; // último tick
    expect(total, lessThanOrEqualTo(350));
  });

  test('roulette con efectos ON dispara 6 ticks de tick.wav', () async {
    final played = <String>[];
    AudioService.debugPlayListener = played.add;
    await AudioService.instance.roulette();
    expect(played, List.filled(6, 'tick.wav'));
  });

  test('roulette con efectos OFF no dispara ningún sonido', () async {
    Settings.instance.soundEffects = false;
    final played = <String>[];
    AudioService.debugPlayListener = played.add;
    await AudioService.instance.roulette();
    expect(played, isEmpty);
  });

  test('roulette suena aunque la música esté OFF (manda el de efectos)',
      () async {
    Settings.instance.music = false;
    Settings.instance.soundEffects = true;
    final played = <String>[];
    AudioService.debugPlayListener = played.add;
    await AudioService.instance.roulette();
    expect(played.length, 6);
  });

  test('una selección nueva corta la ruleta anterior (no se apilan)',
      () async {
    final played = <String>[];
    AudioService.debugPlayListener = played.add;
    final first = AudioService.instance.roulette();
    await Future.delayed(const Duration(milliseconds: 60));
    await AudioService.instance.roulette();
    await first;
    // 2 secuencias completas serían 12 ticks; al cortarse, < 12.
    expect(played.length, lessThan(12));
    expect(played.length, greaterThanOrEqualTo(6));
  });
}
