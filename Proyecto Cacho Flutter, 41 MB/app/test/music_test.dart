import 'package:cacho_app/state/music.dart';
import 'package:cacho_app/state/youtube_api.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('sincronía de la música', () {
    test('la posición corre en tiempo real desde el ancla del servidor', () {
      // El estado llegó cuando el servidor marcaba sentAt=10000 y el
      // tema partió en startedAt=4000: al llegar iba en 6000 ms.
      final pos = anchoredPositionMs(
        startedAt: 4000,
        pausedAt: null,
        sentAt: 10000,
        receiptLocalMs: 500,
        nowLocalMs: 2500,
      );
      expect(pos, 8000); // 6000 + 2000 transcurridos
    });

    test('en pausa la posición queda congelada donde se pausó', () {
      final pos = anchoredPositionMs(
        startedAt: 4000,
        pausedAt: 9000,
        sentAt: 20000,
        receiptLocalMs: 500,
        nowLocalMs: 999999,
      );
      expect(pos, 5000);
    });

    test('el reloj local desfasado no descuadra: manda el del servidor', () {
      // Mismo ancla, otro teléfono con el reloj corrido: la posición
      // al recibir es la misma porque depende de sentAt-startedAt.
      final pos = anchoredPositionMs(
        startedAt: 4000,
        pausedAt: null,
        sentAt: 10000,
        receiptLocalMs: 777000,
        nowLocalMs: 777000,
      );
      expect(pos, 6000);
    });
  });

  group('volumen bajo las voces', () {
    test('sin micrófonos, suena al volumen elegido', () {
      expect(duckedVolume(30, false), 30);
      expect(duckedVolume(50, false), 50);
    });
    test('con un micrófono abierto baja a 11 como máximo', () {
      expect(duckedVolume(30, true), 11);
      expect(duckedVolume(50, true), 11);
      expect(duckedVolume(8, true), 8); // si ya estaba bajo, no sube
    });
  });

  group('duraciones de YouTube', () {
    test('ISO-8601 a segundos', () {
      expect(YoutubeApi.parseDuration('PT3M25S'), 205);
      expect(YoutubeApi.parseDuration('PT1H2M3S'), 3723);
      expect(YoutubeApi.parseDuration('PT45S'), 45);
      expect(YoutubeApi.parseDuration('PT10M'), 600);
    });
    test('etiqueta legible', () {
      expect(YoutubeApi.durationLabel(205), '3:25');
      expect(YoutubeApi.durationLabel(3723), '1:02:03');
      expect(YoutubeApi.durationLabel(0), '');
    });
  });
}
