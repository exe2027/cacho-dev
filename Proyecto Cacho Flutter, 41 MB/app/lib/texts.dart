import 'package:cacho_engine/cacho_engine.dart';

import 'state/match_controller.dart';

/// Lenguaje de la mesa (master prompt §7): español de Chile, frases
/// cortas, pluralización correcta. Los nombres de pintas salen del motor
/// (única fuente: enum Pinta) y aquí solo se pluralizan.

String faceName(int face) => Pinta.fromValor(face).nombre;

String facePlural(int face) => switch (face) {
      1 => 'Ases',
      2 => 'Patos',
      3 => 'Trenes',
      4 => 'Cuadras',
      5 => 'Quintas',
      _ => 'Sextas',
    };

String diceWord(int n) => n == 1 ? '1 dado' : '$n dados';

/// "4 Cuadras" — forma corta de una apuesta (sin el dado gráfico).
String bidShort(Bid b) => '${b.quantity} ${facePlural(b.face)}';

/// Etiqueta de globo para la última jugada de un jugador.
String eventLabel(UiEvent e) => switch (e.type) {
      'bid' => e.bid != null ? bidShort(e.bid!) : 'Apostó',
      'paso' => 'Paso',
      'dudo' => '¡Dudo!',
      'calzo' => '¡Calzo!',
      'dudoPaso' => 'Dudó el Paso',
      'calzoPaso' => 'Calzó el Paso',
      _ => e.type,
    };

String nameOr(MatchController c, String? id, {String fallback = 'Alguien'}) {
  if (id == null) return fallback;
  if (id == c.myId) return 'Tú';
  return c.playerById(id)?.nickname ?? fallback;
}

/// Nombre corto para espacios angostos (sin el prefijo "Bot ").
String shortNameOf(MatchController c, String? id) {
  final n = nameOr(c, id);
  return n.startsWith('Bot ') ? n.substring(4) : n;
}

String nameOfPlain(MatchController c, String? id) {
  if (id == null) return 'alguien';
  if (id == c.myId) return 'tú';
  return c.playerById(id)?.nickname ?? 'alguien';
}

/// Banner fijo de estado: qué pasó y qué me toca (master prompt §7).
String verdictText(MatchController c, UiResolution r) {
  final challenger = nameOr(c, r.challengerId);
  switch (r.type) {
    case 'dudo':
      return '${nameOr(c, r.loserId)} pierde 1 dado.';
    case 'calzo':
      // Exacto bloqueado (25-oct): no gana ni pierde nadie, así
      // que gainerId y loserId son null. El flag manda sobre la
      // inferencia "gainerId == null ⇒ falló".
      if (r.recoveryBlocked) {
        return 'exacto pero sin recuperación';
      }
      if (r.massLoserIds.isNotEmpty) {
        // Calzo perfecto con los 5 dados: pierden todos los demás.
        return '¡Calzo perfecto! Todos los demás pierden 1 dado.';
      }
      if (r.gainerId != null) {
        return '¡Exacto! $challenger recupera 1 dado.';
      }
      return '$challenger pierde 1 dado.';
    case 'dudoPaso':
      final pasoName = nameOr(c, r.pasoPlayerId);
      final hand = r.revealed[r.pasoPlayerId] ?? const <int>[];
      final wasTrue = hand.length == 5 && GameEngine.isPasoHand(hand);
      return wasTrue
          ? '$challenger pierde 1 dado.'
          : '$pasoName pierde 1 dado.';
    case 'calzoPaso':
      // Igual que en calzo: exacto bloqueado no es un fallo
      // (nadie pierde), aunque gainerId sea null.
      if (r.recoveryBlocked) {
        return 'exacto pero sin recuperación';
      }
      if (r.gainerId != null) {
        final atCap = (r.revealed[r.gainerId]?.length ?? 0) >= 5;
        return atCap
            ? '$challenger ya tenía 5 dados.'
            : '¡Exacto! $challenger recupera 1 dado.';
      }
      return '$challenger pierde 1 dado.';
    case 'kamikaze':
      final parts = r.kamikazeLosses.entries
          .where((e) => e.value > 0)
          .map((e) => '${nameOr(c, e.key)} perdió ${diceWord(e.value)}')
          .join(', ');
      return parts.isEmpty
          ? 'Nadie tenía el ${r.kamikazeFace != null ? faceName(r.kamikazeFace!) : ''}.'
          : '$parts.';
    case 'abandono':
      return '${nameOr(c, r.loserId)} quedó eliminado por no jugar.';
    default:
      return '';
  }
}

/// Encabezado de la revelación (paso 1 de la secuencia).
/// Título corto de la revelación: solo la acción.
String revealTitle(UiResolution r) {
  return switch (r.type) {
    'dudo' => '¡DUDO!',
    'calzo' => '¡CALZO!',
    'dudoPaso' => '¡PASO EN DUDA!',
    'calzoPaso' => '¡CALZO AL PASO!',
    'kamikaze' => '¡KAMIKAZE!',
    'abandono' => '¡ELIMINADO!',
    _ => 'Revelación',
  };
}

String revealHeader(MatchController c, UiResolution r) {
  final challenger = nameOr(c, r.challengerId);
  final bidder = nameOr(c, r.bidderId);
  final bid = r.bid != null ? bidShort(r.bid!) : '';
  return switch (r.type) {
    'dudo' => '$challenger dudó · $bid de $bidder',
    'calzo' => '$challenger calzó · $bid de $bidder',
    'dudoPaso' =>
      '$challenger dudó el Paso de ${nameOr(c, r.pasoPlayerId)}',
    'calzoPaso' =>
      '$challenger calzó el Paso de ${nameOr(c, r.pasoPlayerId)}',
    'kamikaze' =>
      '${nameOr(c, r.challengerId ?? r.bidderId)} eligió el '
          '${r.kamikazeFace != null ? faceName(r.kamikazeFace!) : ''}',
    'abandono' =>
      '${nameOr(c, r.loserId)} dejó vencer el tiempo 3 turnos seguidos',
    _ => '',
  };
}
