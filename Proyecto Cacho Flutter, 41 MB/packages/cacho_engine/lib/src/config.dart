/// Configuración de una sala/partida de Cacho.
///
/// Valores por defecto = decisiones cerradas el 22-oct-2026
/// (ver docs/01-arquitectura-y-decisiones.md).
class GameConfig {
  /// Los 1 cuentan como la pinta apostada (salvo apuesta de ases).
  final bool wildcardsEnabled;

  /// Regla de ases completa: conversión mitad / doble+1 al entrar y
  /// salir de ases, y 1 como comodín. Si se desactiva, los ases son una
  /// pinta más: sin conversión y sin comodines (manda sobre
  /// [wildcardsEnabled]).
  final bool acesRuleEnabled;

  /// Comodines efectivos al contar una apuesta.
  bool get wildcardsEffective => wildcardsEnabled && acesRuleEnabled;

  /// Regla especial Paso activa.
  final bool pasoEnabled;

  /// Regla especial Kamikaze activa.
  final bool kamikazeEnabled;

  /// Calzo activo (normal y del Paso).
  final bool calzoEnabled;

  /// Fracción de los dados originales que deben quedar en juego para calzar.
  /// Fija para toda la partida: el umbral se calcula una sola vez al inicio.
  final double calzoMinFraction;

  /// Máximo de Pasos por jugador en una misma ronda.
  final int maxPasosPerPlayerPerRound;

  /// Permitir Paso como primera jugada de la ronda.
  final bool pasoAsFirstPlayAllowed;

  /// Permitir que un mismo jugador pase dos veces seguidas (sus dos
  /// acciones personales consecutivas dentro de la ronda).
  final bool pasoTwiceInARowAllowed;

  /// Dados con los que parte cada jugador (5 en el juego clásico).
  final int dicePerPlayer;

  final int minPlayers;
  final int maxPlayers;

  /// Solo lo usa la capa de red/UI; el motor no impone tiempos.
  final int turnTimerSeconds;

  const GameConfig({
    this.wildcardsEnabled = true,
    this.acesRuleEnabled = true,
    this.pasoEnabled = true,
    this.kamikazeEnabled = true,
    this.calzoEnabled = true,
    this.calzoMinFraction = 0.5,
    this.maxPasosPerPlayerPerRound = 1,
    this.pasoAsFirstPlayAllowed = false,
    this.pasoTwiceInARowAllowed = false,
    this.dicePerPlayer = 5,
    this.minPlayers = 2,
    this.maxPlayers = 6, // Máximo 6 por orden del usuario 26-oct 09:35 ("me equivoqué eran 6", reemplaza el 5 de la decisión 07:32).
    this.turnTimerSeconds = 60,
  });

  /// Preset Clásico: sin Paso ni Kamikaze; Calzo y comodines sí.
  factory GameConfig.clasico() =>
      const GameConfig(pasoEnabled: false, kamikazeEnabled: false);

  /// Preset Cacho completo: todas las reglas especiales activas.
  factory GameConfig.cachoCompleto() => const GameConfig();

  /// Umbral de Calzo para una partida: la mitad (hacia arriba) de los
  /// dados originales. Se calcula UNA vez, al crear la partida.
  int calzoThreshold(int initialTotalDice) =>
      (initialTotalDice * calzoMinFraction).ceil();

  /// Descripción en palabras de esta configuración, generada desde los
  /// valores reales (para el "Ver qué cambia" de los presets).
  List<String> describe() {
    final lines = <String>[];
    lines.add(wildcardsEffective
        ? 'Comodines: los 1 valen por cualquier pinta (salvo en apuesta de Ases).'
        : 'Sin comodines: cada dado vale solo por su pinta.');
    lines.add(acesRuleEnabled
        ? 'Ases: entrar cuesta la mitad hacia arriba y salir el doble + 1.'
        : 'Ases como una pinta más: sin conversión de mitad/doble+1.');
    lines.add(calzoEnabled
        ? 'Calzo activo: si aciertas la cantidad exacta recuperas un dado; solo con más de la mitad de los dados originales en juego.'
        : 'Calzo desactivado.');
    lines.add(pasoEnabled
        ? 'Paso activo: con tus 5 dados distintos o un Full; máximo $maxPasosPerPlayerPerRound por ronda${pasoAsFirstPlayAllowed ? '' : ', nunca como primera jugada'}.'
        : 'Paso desactivado.');
    lines.add(kamikazeEnabled
        ? 'Kamikaze activo: una sola vez, la primera vez que quedes con 1 dado siendo el único.'
        : 'Kamikaze desactivado.');
    lines.add('Temporizador de turno: $turnTimerSeconds segundos.');
    return lines;
  }

  GameConfig copyWith({
    bool? wildcardsEnabled,
    bool? acesRuleEnabled,
    bool? pasoEnabled,
    bool? kamikazeEnabled,
    bool? calzoEnabled,
    double? calzoMinFraction,
    int? maxPasosPerPlayerPerRound,
    bool? pasoAsFirstPlayAllowed,
    bool? pasoTwiceInARowAllowed,
    int? dicePerPlayer,
    int? turnTimerSeconds,
  }) {
    return GameConfig(
      wildcardsEnabled: wildcardsEnabled ?? this.wildcardsEnabled,
      acesRuleEnabled: acesRuleEnabled ?? this.acesRuleEnabled,
      pasoEnabled: pasoEnabled ?? this.pasoEnabled,
      kamikazeEnabled: kamikazeEnabled ?? this.kamikazeEnabled,
      calzoEnabled: calzoEnabled ?? this.calzoEnabled,
      calzoMinFraction: calzoMinFraction ?? this.calzoMinFraction,
      maxPasosPerPlayerPerRound:
          maxPasosPerPlayerPerRound ?? this.maxPasosPerPlayerPerRound,
      pasoAsFirstPlayAllowed:
          pasoAsFirstPlayAllowed ?? this.pasoAsFirstPlayAllowed,
      pasoTwiceInARowAllowed:
          pasoTwiceInARowAllowed ?? this.pasoTwiceInARowAllowed,
      dicePerPlayer: dicePerPlayer ?? this.dicePerPlayer,
      minPlayers: minPlayers,
      maxPlayers: maxPlayers,
      turnTimerSeconds: turnTimerSeconds ?? this.turnTimerSeconds,
    );
  }
}
