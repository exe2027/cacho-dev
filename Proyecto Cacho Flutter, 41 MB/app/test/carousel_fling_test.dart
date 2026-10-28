// Fling multi-sala del carrusel: pasos por velocidad, umbrales de
// sensibilidad, tack por sala y física multi-página de Buscar salas.
// No depende de hardware de audio: AudioService.debugPlayListener
// registra cada intento real de sonar.
import 'package:cacho_app/state/audio.dart';
import 'package:cacho_app/state/settings.dart';
import 'package:cacho_app/widgets/carousel_fling.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

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

  group('pasos por velocidad y sensibilidad', () {
    test('toque o arrastre mínimo no cambia de sala', () {
      expect(carouselFlingSteps(velocity: 0, offset: 0), 0);
      expect(carouselFlingSteps(velocity: 100, offset: 0.05), 0);
      expect(carouselFlingSteps(velocity: 0, offset: 0.07), 0);
    });

    test('movimiento ligero y rápido ya mueve 1 sala (umbral 150)', () {
      expect(carouselFlingSteps(velocity: 160, offset: 0), 1);
      expect(carouselFlingSteps(velocity: 0, offset: 0.08), 1);
      expect(carouselFlingSteps(velocity: 300, offset: 0), 1);
    });

    test('velocidad alta atraviesa varias salas', () {
      expect(carouselFlingSteps(velocity: 700, offset: 0), 2);
      expect(carouselFlingSteps(velocity: 1500, offset: 0), 3);
      expect(carouselFlingSteps(velocity: 3000, offset: 0), 4);
    });

    test('los pasos nunca dan la vuelta completa', () {
      expect(
        carouselFlingSteps(velocity: 3000, offset: 0, itemCount: 3),
        2,
      );
      expect(
        carouselFlingSteps(velocity: 3000, offset: 0, itemCount: 6),
        4,
      );
    });

    test('cada paso dura 120 ms', () {
      expect(carouselStepDurationMs, 120);
    });
  });

  group('tack frente a ráfaga', () {
    test('un tack cancela la ráfaga pendiente sin cortarse a sí mismo',
        () async {
      final played = <String>[];
      AudioService.debugPlayListener = played.add;
      final burst = AudioService.instance.roulette();
      await Future.delayed(const Duration(milliseconds: 60));
      AudioService.instance.tack();
      await burst;
      await Future.delayed(const Duration(milliseconds: 400));
      // Ráfaga completa serían 6 ticks; al cortarla con el tack,
      // quedan los 2 primeros de la ráfaga + el tack, no 6.
      expect(played.length, lessThan(6));
      expect(played.length, greaterThanOrEqualTo(3));
      expect(played, everyElement('tick.wav'));
    });

    test('tack con efectos OFF no suena', () {
      Settings.instance.soundEffects = false;
      final played = <String>[];
      AudioService.debugPlayListener = played.add;
      AudioService.instance.tack();
      expect(played, isEmpty);
    });
  });

  group('física multi-página (Buscar salas)', () {
    PageMetrics metrics(double pixels, double velocityUnused) {
      return PageMetrics(
        minScrollExtent: 0,
        maxScrollExtent: 4 * 880.0,
        pixels: pixels,
        viewportDimension: 1000,
        axisDirection: AxisDirection.right,
        viewportFraction: 0.88,
        devicePixelRatio: 1.0,
      );
    }

    double simulateToEnd(Simulation sim) {
      var t = 0.0;
      var x = sim.x(0);
      while (!sim.isDone(t) && t < 5.0) {
        t += 0.016;
        x = sim.x(t);
      }
      return x;
    }

    test('fling fuerte desde la página 0 llega a la página 3', () {
      const physics = MultiPageScrollPhysics(itemCount: 5, activePage: 0);
      final sim = physics.createBallisticSimulation(metrics(0, 0), 2000);
      expect(sim, isNotNull);
      expect(simulateToEnd(sim!), closeTo(3 * 880.0, 50));
    });

    test('arrastre corto (0.11 de página) con velocidad 0 avanza 1', () {
      const physics = MultiPageScrollPhysics(itemCount: 5, activePage: 0);
      // Página 0.11 = 0.11 * 880 ≈ 97 px.
      final sim = physics.createBallisticSimulation(metrics(97, 0), 0);
      expect(sim, isNotNull);
      expect(simulateToEnd(sim!), closeTo(880.0, 50));
    });

    test('arrastre mínimo (0.05 de página) vuelve a la página activa', () {
      const physics = MultiPageScrollPhysics(itemCount: 5, activePage: 0);
      final sim = physics.createBallisticSimulation(metrics(44, 0), 0);
      // O bien no hay simulación (ya está en su sitio) o termina en 0.
      if (sim != null) {
        expect(simulateToEnd(sim), closeTo(0, 50));
      }
    });

    test('fling no pasa del último índice', () {
      const physics = MultiPageScrollPhysics(itemCount: 5, activePage: 4);
      final sim = physics.createBallisticSimulation(metrics(4 * 880.0, 0), 0);
      // En el borde, la física delega al padre o devuelve null.
      expect(sim == null || simulateToEnd(sim) <= 4 * 880.0 + 50, isTrue);
    });
  });
}
