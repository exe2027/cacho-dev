import 'config.dart';
import 'models.dart';

/// Motor de Cacho (Dudo chileno). Dart puro: sin UI, sin red, sin reloj.
///
/// Reglas fijadas en docs/01-arquitectura-y-decisiones.md. Toda jugada pasa
/// por validación aquí; en línea, el servidor es quien posee la instancia
/// (autoridad) y cada cliente recibe solo su propia mano.
class GameEngine {
  final GameConfig config;
  final DiceRoller roller;
  final List<PlayerState> players;

  /// Dados totales al inicio (jugadores × dados por jugador).
  late final int initialTotalDice;

  /// Umbral fijo de Calzo, calculado una sola vez al crear la partida.
  late final int calzoThresholdDice;

  GamePhase phase = GamePhase.lobby;
  int roundNumber = 0;
  Bid? currentBid;
  String? lastBidderId;
  String? currentPlayerId;

  /// Jugador cuyo Paso está pendiente de desafío (solo lo puede desafiar
  /// el jugador en turno, que es el inmediatamente siguiente).
  String? pendingPasoPlayerId;

  String? kamikazeOfferPlayerId;
  String? kamikazeActivatorId;

  String? winnerId;
  bool isDraw = false;
  Resolution? lastResolution;

  final List<GameEvent> history = [];
  final List<GameEvent> _roundHistory = [];
  List<GameEvent> get roundHistory => List.unmodifiable(_roundHistory);

  final Map<String, int> _pasosThisRound = {};
  final Map<String, ActionType> _lastActionThisRound = {};
  int _actionsThisRound = 0;
  String? _pendingStarterId;

  GameEngine({
    required this.config,
    required this.roller,
    required List<({String id, String name})> playerList,
  }) : players = [
          for (final p in playerList)
            PlayerState(p.id, p.name, config.dicePerPlayer)
        ] {
    if (playerList.length < config.minPlayers ||
        playerList.length > config.maxPlayers) {
      throw ArgumentError(
          'jugadores fuera de rango: ${playerList.length} (permitido ${config.minPlayers}..${config.maxPlayers})');
    }
    final ids = playerList.map((p) => p.id).toSet();
    if (ids.length != playerList.length) {
      throw ArgumentError('ids de jugador duplicados');
    }
    initialTotalDice = playerList.length * config.dicePerPlayer;
    calzoThresholdDice = config.calzoThreshold(initialTotalDice);
  }

  // ---------- consultas ----------

  PlayerState playerById(String id) =>
      players.firstWhere((p) => p.id == id, orElse: () => throw ArgumentError('jugador desconocido: $id'));

  List<PlayerState> get alivePlayers => [for (final p in players) if (p.alive) p];

  int get totalDiceInPlay =>
      alivePlayers.fold(0, (sum, p) => sum + p.diceCount);

  /// ¿Se puede calzar ahora? Desde el 24-oct, por orden del
  /// usuario tras probarlo: SIN umbral de dados — se puede calzar
  /// siempre que el Calzo esté activo (el umbral fijo de la mitad
  /// de los dados originales dejaba el final de partida sin Calzo,
  /// justo cuando alguien quedaba con un dado).
  /// El 25-oct separó intento de recuperación: el intento sigue
  /// siempre permitido; solo la GANANCIA queda condicionada (ver
  /// [calzoRecoveryAllowed]).
  bool get canCalzoNow => config.calzoEnabled;

  /// ¿Un Calzo exacto recupera un dado ahora? (25-oct, ejemplo del
  /// usuario: 4 jugadores = 20 iniciales, con 11+ se recupera, con
  /// 10 o menos no). Condición ESTRICTA, medida ANTES de aplicar
  /// ganancia/pérdida: totalActual * 2 > totalInicial.
  /// NO usar config.calzoThreshold() (= ceil(inicial * 0.5)): para
  /// 20 daría 10 y el usuario exige 11. Para totales impares
  /// coincide con el ceil (15 -> 8), para pares es uno más (20 -> 11).
  bool get calzoRecoveryAllowed => totalDiceInPlay * 2 > initialTotalDice;

  /// Copia de la mano de un jugador. USO DEL SERVIDOR: entregar solo al dueño.
  List<int> handOf(String playerId) => List.of(playerById(playerId).hand);

  String nextAliveAfter(String id) {
    final idx = players.indexWhere((p) => p.id == id);
    for (var i = 1; i <= players.length; i++) {
      final p = players[(idx + i) % players.length];
      if (p.alive) return p.id;
    }
    throw StateError('no quedan jugadores vivos');
  }

  // ---------- reglas puras (compartidas con bots y tests) ----------

  /// Valida una subida según la regla clásica fijada:
  /// - Sin apuesta vigente: cualquier cantidad 1..total, pero NUNCA ases
  ///   (regla del usuario, 22-oct: no se puede partir con ases).
  /// - Sin ases de por medio: sube la cantidad (cualquier pinta) o, con la
  ///   misma cantidad, sube la pinta.
  /// - Entrar a ases: al menos la mitad de la cantidad, hacia arriba.
  /// - Salir de ases: al menos el doble + 1.
  /// - De ases a ases: solo sube la cantidad.
  /// Devuelve el código de error, o null si la apuesta es legal.
  static String? raiseError(Bid? current, Bid next, int totalDiceInPlay,
      {bool acesRuleEnabled = true}) {
    if (next.face < 1 || next.face > 6) return 'pinta_invalida';
    if (next.quantity < 1) return 'cantidad_invalida';
    if (next.quantity > totalDiceInPlay) return 'cantidad_supera_total';
    if (current == null) {
      return next.face == 1 ? 'ases_para_partir' : null;
    }
    // Sin regla de ases, los ases son una pinta más: manda la clásica.
    if (!acesRuleEnabled || (current.face != 1 && next.face != 1)) {
      if (next.quantity > current.quantity) return null;
      if (next.quantity == current.quantity && next.face > current.face) {
        return null;
      }
      return 'apuesta_no_supera';
    }
    if (current.face != 1 && next.face == 1) {
      final minQty = (current.quantity + 1) ~/ 2; // mitad hacia arriba
      return next.quantity >= minQty ? null : 'ases_mitad';
    }
    if (current.face == 1 && next.face != 1) {
      final minQty = current.quantity * 2 + 1; // doble + 1
      return next.quantity >= minQty ? null : 'salida_ases_doble_mas_uno';
    }
    // ases -> ases
    return next.quantity > current.quantity ? null : 'apuesta_no_supera';
  }

  /// Conteo real de una apuesta sobre todas las manos. Los 1 son comodines
  /// salvo si la apuesta es de ases o si los comodines están desactivados.
  static int countForBid(
      Iterable<List<int>> hands, Bid bid, bool wildcardsEnabled) {
    var total = 0;
    for (final hand in hands) {
      for (final die in hand) {
        if (die == bid.face) {
          total++;
        } else if (wildcardsEnabled && bid.face != 1 && die == 1) {
          total++;
        }
      }
    }
    return total;
  }

  /// Desglose de una apuesta sobre las manos reveladas, para la pantalla
  /// de revelación: marca cada dado como el que cuenta (exacto), comodín
  /// (un 1 que vale por la pinta) o el que no cuenta.
  static BidEvaluation evaluateBid(
      Map<String, List<int>> hands, Bid bid, bool wildcardsEnabled) {
    final marks = <String, List<DieMark>>{};
    var exact = 0;
    var wild = 0;
    hands.forEach((id, hand) {
      final list = <DieMark>[];
      for (final die in hand) {
        if (die == bid.face) {
          list.add(DieMark.exact);
          exact++;
        } else if (wildcardsEnabled && bid.face != 1 && die == 1) {
          list.add(DieMark.wild);
          wild++;
        } else {
          list.add(DieMark.miss);
        }
      }
      marks[id] = list;
    });
    return BidEvaluation(marks: marks, exact: exact, wild: wild);
  }

  /// Mano de Paso: cinco distintos, o Full (3+2). Sin comodines.
  static bool isPasoHand(List<int> hand) {
    if (hand.length != 5) return false;
    if (hand.toSet().length == 5) return true;
    final counts = <int, int>{};
    for (final die in hand) {
      counts[die] = (counts[die] ?? 0) + 1;
    }
    final sorted = counts.values.toList()..sort();
    return sorted.length == 2 && sorted[0] == 2 && sorted[1] == 3;
  }

  // ---------- flujo ----------

  /// Desempate por dado mayor y primera ronda. Devuelve quién parte.
  String startGame() {
    if (phase != GamePhase.lobby) {
      throw const IllegalMove('fase_invalida', 'la partida ya comenzó');
    }
    var candidates = [for (final p in players) p.id];
    late String starter;
    while (true) {
      final rolls = {for (final id in candidates) id: roller.rollDie()};
      final maxRoll = rolls.values.reduce((a, b) => a > b ? a : b);
      final tied = [
        for (final e in rolls.entries)
          if (e.value == maxRoll) e.key
      ];
      if (tied.length == 1) {
        starter = tied.first;
        break;
      }
      candidates = tied;
    }
    _beginRound(starter);
    return starter;
  }

  void _beginRound(String starterId) {
    roundNumber++;
    for (final p in players) {
      p.hand = p.alive
          ? [for (var i = 0; i < p.diceCount; i++) roller.rollDie()]
          : <int>[];
    }
    currentBid = null;
    lastBidderId = null;
    pendingPasoPlayerId = null;
    kamikazeOfferPlayerId = null;
    kamikazeActivatorId = null;
    _pasosThisRound.clear();
    _lastActionThisRound.clear();
    _roundHistory.clear();
    _actionsThisRound = 0;
    currentPlayerId = starterId;
    phase = GamePhase.playing;
  }

  PlayerState _requireTurn(String playerId) {
    if (phase != GamePhase.playing) {
      throw const IllegalMove('fase_invalida', 'no hay ronda en curso');
    }
    if (currentPlayerId != playerId) {
      throw const IllegalMove('no_es_tu_turno', 'todavía no es tu turno');
    }
    final p = playerById(playerId);
    if (p.eliminated) {
      throw const IllegalMove('jugador_eliminado', 'ese jugador ya salió');
    }
    return p;
  }

  void _record(String playerId, ActionType type, [Bid? bid]) {
    final e = GameEvent(
        round: roundNumber, playerId: playerId, type: type, bid: bid);
    history.add(e);
    _roundHistory.add(e);
    _lastActionThisRound[playerId] = type;
    _actionsThisRound++;
  }

  void _advanceTurn() {
    currentPlayerId = nextAliveAfter(currentPlayerId!);
  }

  // ---------- acciones ----------

  /// Subir la apuesta. Si había un Paso pendiente, queda firme.
  void bid(String playerId, Bid next) {
    _requireTurn(playerId);
    final error = raiseError(currentBid, next, totalDiceInPlay,
        acesRuleEnabled: config.acesRuleEnabled);
    if (error != null) {
      throw IllegalMove(error, 'apuesta ilegal: $next sobre $currentBid');
    }
    pendingPasoPlayerId = null;
    currentBid = next;
    lastBidderId = playerId;
    _record(playerId, ActionType.bid, next);
    _advanceTurn();
  }

  /// Declarar Paso. No cambia la apuesta vigente. Se puede declarar con
  /// mano falsa (farol): solo un desafío lo verifica.
  void paso(String playerId) {
    final p = _requireTurn(playerId);
    if (!config.pasoEnabled) {
      throw const IllegalMove('paso_deshabilitado', 'el Paso no está activo en esta sala');
    }
    if (p.diceCount != config.dicePerPlayer || p.diceCount != 5) {
      throw const IllegalMove(
          'paso_requiere_5_dados', 'solo puedes pasar con tus 5 dados completos');
    }
    if (_actionsThisRound == 0 && !config.pasoAsFirstPlayAllowed) {
      throw const IllegalMove(
          'paso_primera_jugada', 'no se puede pasar como primera jugada de la ronda');
    }
    if ((_pasosThisRound[playerId] ?? 0) >= config.maxPasosPerPlayerPerRound) {
      throw const IllegalMove('paso_limite_ronda', 'ya usaste tu Paso de esta ronda');
    }
    if (!config.pasoTwiceInARowAllowed &&
        _lastActionThisRound[playerId] == ActionType.paso) {
      throw const IllegalMove(
          'paso_dos_veces_seguidas', 'no puedes pasar dos veces seguidas');
    }
    // Un Paso anterior que nadie desafió queda firme.
    pendingPasoPlayerId = playerId;
    _pasosThisRound[playerId] = (_pasosThisRound[playerId] ?? 0) + 1;
    _record(playerId, ActionType.paso);
    _advanceTurn();
  }

  /// Dudar la apuesta vigente. Termina la ronda.
  Resolution dudo(String playerId) {
    _requireTurn(playerId);
    final bidNow = currentBid;
    if (bidNow == null) {
      throw const IllegalMove('sin_apuesta', 'no hay apuesta que dudar');
    }
    pendingPasoPlayerId = null;
    final actual = countForBid(
        [for (final p in alivePlayers) p.hand], bidNow, config.wildcardsEffective);
    final bidder = lastBidderId!;
    // Si la apuesta era cierta, pierde quien dudó; si no, quien apostó.
    final loser = actual >= bidNow.quantity ? playerId : bidder;
    final revealed = {
      for (final p in alivePlayers) p.id: List<int>.of(p.hand)
    };
    _record(playerId, ActionType.dudo);
    _applyLoss(loser);
    final res = Resolution(
      type: ResolutionType.dudo,
      loserId: loser,
      revealedHands: revealed,
      actualCount: actual,
    );
    _finishResolution(starterCandidateId: loser, res: res);
    return res;
  }

  /// Calzar la apuesta vigente: afirmar que la cantidad es exacta.
  /// Termina la ronda.
  Resolution calzo(String playerId) {
    _requireTurn(playerId);
    final bidNow = currentBid;
    if (bidNow == null) {
      throw const IllegalMove('sin_apuesta', 'no hay apuesta que calzar');
    }
    if (!config.calzoEnabled) {
      throw const IllegalMove('calzo_deshabilitado', 'el Calzo no está activo en esta sala');
    }
    pendingPasoPlayerId = null;
    final actual = countForBid(
        [for (final p in alivePlayers) p.hand], bidNow, config.wildcardsEffective);
    final revealed = {
      for (final p in alivePlayers) p.id: List<int>.of(p.hand)
    };
    _record(playerId, ActionType.calzo);
    final exact = actual == bidNow.quantity;
    // Total ANTES de aplicar ganancia/pérdida (25-oct).
    final recoveryAllowed = calzoRecoveryAllowed;
    var massLosers = const <String>[];
    if (exact) {
      if (playerById(playerId).diceCount >= config.dicePerPlayer &&
          recoveryAllowed) {
        // Calzo perfecto con los dados completos (regla del usuario,
        // 22-oct): no cabe recuperar un dado más, así que en vez de
        // eso pierden un dado TODOS los demás jugadores vivos.
        // C11 (decisión 26-oct): el perfecto solo aplica cuando la
        // recuperación está permitida (totalActual × 2 > totalInicial,
        // medido antes de aplicar ganancia/pérdida). Con total bajo el
        // perfecto queda BLOQUEADO: nadie gana ni pierde, la ronda
        // termina y el calzador parte la siguiente.
        massLosers = [
          for (final p in alivePlayers)
            if (p.id != playerId) p.id,
        ];
        for (final id in massLosers) {
          _applyLoss(id);
        }
      } else if (recoveryAllowed) {
        _applyGain(playerId);
      }
      // Exacto sin recuperación: no gana ni pierde (25-oct).
    } else {
      _applyLoss(playerId);
    }
    final res = Resolution(
      type: ResolutionType.calzo,
      loserId: exact ? null : playerId,
      gainerId:
          exact && massLosers.isEmpty && recoveryAllowed ? playerId : null,
      revealedHands: revealed,
      actualCount: actual,
      massLoserIds: massLosers,
      recoveryBlocked: exact && massLosers.isEmpty && !recoveryAllowed,
    );
    // Acierte o falle, parte quien calzó (recuperó o perdió el dado).
    _finishResolution(starterCandidateId: playerId, res: res);
    return res;
  }

  /// Dudar el Paso pendiente. Revela SOLO los dados de quien pasó.
  /// Termina la ronda.
  Resolution dudoPaso(String playerId) {
    _requireTurn(playerId);
    final pasoId = pendingPasoPlayerId;
    if (pasoId == null) {
      throw const IllegalMove('sin_paso_pendiente', 'no hay Paso que dudar');
    }
    final pasoPlayer = playerById(pasoId);
    final truth = isPasoHand(pasoPlayer.hand);
    final revealed = {pasoId: List<int>.of(pasoPlayer.hand)};
    _record(playerId, ActionType.dudoPaso);
    final loser = truth ? playerId : pasoId;
    _applyLoss(loser);
    final res = Resolution(
      type: ResolutionType.dudoPaso,
      loserId: loser,
      revealedHands: revealed,
    );
    _finishResolution(starterCandidateId: loser, res: res);
    return res;
  }

  /// Calzar el Paso pendiente: afirmar que el Paso es verdadero.
  /// Revela SOLO los dados de quien pasó. Termina la ronda.
  Resolution calzoPaso(String playerId) {
    _requireTurn(playerId);
    final pasoId = pendingPasoPlayerId;
    if (pasoId == null) {
      throw const IllegalMove('sin_paso_pendiente', 'no hay Paso que calzar');
    }
    if (!config.calzoEnabled) {
      throw const IllegalMove('calzo_deshabilitado', 'el Calzo no está activo en esta sala');
    }
    final pasoPlayer = playerById(pasoId);
    final truth = isPasoHand(pasoPlayer.hand);
    final revealed = {pasoId: List<int>.of(pasoPlayer.hand)};
    _record(playerId, ActionType.calzoPaso);
    // Misma regla de recuperación que el Calzo (25-oct): total ANTES
    // de aplicar ganancia/pérdida, estricto sobre la mitad inicial.
    final recoveryAllowed = calzoRecoveryAllowed;
    if (truth) {
      if (recoveryAllowed) {
        _applyGain(playerId);
      }
      // Verdadero sin recuperación: no gana ni pierde.
    } else {
      _applyLoss(playerId);
    }
    final res = Resolution(
      type: ResolutionType.calzoPaso,
      loserId: truth ? null : playerId,
      gainerId: truth && recoveryAllowed ? playerId : null,
      revealedHands: revealed,
      recoveryBlocked: truth && !recoveryAllowed,
    );
    _finishResolution(starterCandidateId: playerId, res: res);
    return res;
  }

  // ---------- Kamikaze ----------

  /// Respuesta a la oferta de Kamikaze (fase kamikazeOffer, entre rondas).
  void respondKamikaze(String playerId, {required bool accept}) {
    if (phase != GamePhase.kamikazeOffer) {
      throw const IllegalMove('fase_invalida', 'no hay oferta de Kamikaze');
    }
    if (kamikazeOfferPlayerId != playerId) {
      throw const IllegalMove('no_es_tu_oferta', 'el Kamikaze no te fue ofrecido a ti');
    }
    final p = playerById(playerId);
    p.kamikazeOfferedOnce = true; // acepte o rechace, la oferta no se repite
    if (!accept) {
      kamikazeOfferPlayerId = null;
      _beginRound(_pendingStarterId!);
      return;
    }
    p.kamikazeUsed = true;
    kamikazeActivatorId = playerId;
    kamikazeOfferPlayerId = null;
    phase = GamePhase.kamikazeChoice;
    currentPlayerId = playerId;
  }

  /// El activador elige el número y TODOS vuelven a lanzar. Cada jugador
  /// pierde los dados que muestren ese número (sin comodines). Puede morir
  /// el propio activador. Si todos quedan sin dados: empate sin ganador.
  Resolution chooseKamikazeFace(String playerId, int face) {
    if (phase != GamePhase.kamikazeChoice) {
      throw const IllegalMove('fase_invalida', 'no hay Kamikaze en elección');
    }
    if (kamikazeActivatorId != playerId) {
      throw const IllegalMove('no_es_tu_oferta', 'solo el activador elige el número');
    }
    if (face < 1 || face > 6) {
      throw const IllegalMove('pinta_invalida', 'el número debe ser 1..6');
    }
    _record(playerId, ActionType.kamikaze);
    final revealed = <String, List<int>>{};
    final losses = <String, int>{};
    for (final p in alivePlayers) {
      final roll = [for (var i = 0; i < p.diceCount; i++) roller.rollDie()];
      p.hand = roll;
      revealed[p.id] = List.of(roll);
      final lost = roll.where((d) => d == face).length;
      losses[p.id] = lost;
      p.diceCount -= lost;
    }
    final res = Resolution(
      type: ResolutionType.kamikaze,
      revealedHands: revealed,
      kamikazeFace: face,
      kamikazeLosses: losses,
    );
    _finishResolution(starterCandidateId: playerId, res: res);
    return res;
  }

  /// Elimina a un jugador de la partida de inmediato (abandono:
  /// dejó vencer el tiempo de su turno 3 veces seguidas — regla del
  /// usuario, 22-oct, para quien se salió, perdió internet o dejó de
  /// jugar). La ronda en curso se corta, su mano se revela, y parte
  /// la ronda siguiente el siguiente jugador vivo en el reloj.
  Resolution forceEliminate(String playerId) {
    if (phase == GamePhase.finished) {
      throw const IllegalMove(
          'partida_terminada', 'la partida ya terminó');
    }
    final p = playerById(playerId);
    if (!p.alive) {
      throw const IllegalMove(
          'jugador_eliminado', 'ese jugador ya estaba eliminado');
    }
    final revealed = {playerId: List<int>.of(p.hand)};
    p.diceCount = 0;
    p.hand = <int>[];
    if (kamikazeOfferPlayerId == playerId) kamikazeOfferPlayerId = null;
    if (kamikazeActivatorId == playerId) kamikazeActivatorId = null;
    final res = Resolution(
      type: ResolutionType.abandono,
      loserId: playerId,
      revealedHands: revealed,
    );
    // Si había una oferta de Kamikaze en curso, la ronda siguiente la
    // parte quien ya estaba designado (si sigue vivo y no es él).
    var candidate = playerId;
    final pending = _pendingStarterId;
    if (phase == GamePhase.kamikazeOffer &&
        pending != null &&
        pending != playerId &&
        playerById(pending).alive) {
      candidate = pending;
    }
    _finishResolution(starterCandidateId: candidate, res: res);
    return res;
  }

  // ---------- cierre de resolución ----------

  void _applyLoss(String playerId) {
    final p = playerById(playerId);
    if (p.diceCount > 0) p.diceCount--;
  }

  void _applyGain(String playerId) {
    final p = playerById(playerId);
    if (p.diceCount < config.dicePerPlayer) p.diceCount++;
  }

  /// Tras cualquier resolución: revisa fin de partida, luego oferta de
  /// Kamikaze (solo si hay exactamente UN jugador con 1 dado que nunca
  /// recibió la oferta), y si no, parte la ronda siguiente.
  void _finishResolution(
      {required String starterCandidateId, required Resolution res}) {
    lastResolution = res;
    pendingPasoPlayerId = null;
    currentPlayerId = null;
    final alive = alivePlayers;
    if (alive.isEmpty) {
      phase = GamePhase.finished;
      isDraw = true;
      winnerId = null;
      return;
    }
    if (alive.length == 1) {
      phase = GamePhase.finished;
      winnerId = alive.first.id;
      return;
    }
    final starter = playerById(starterCandidateId).alive
        ? starterCandidateId
        : nextAliveAfter(starterCandidateId);
    if (config.kamikazeEnabled) {
      final candidates = [
        for (final p in alive)
          if (p.diceCount == 1 && !p.kamikazeOfferedOnce) p
      ];
      if (candidates.length == 1) {
        phase = GamePhase.kamikazeOffer;
        kamikazeOfferPlayerId = candidates.first.id;
        _pendingStarterId = starter;
        return;
      }
      // Si hay 2+ con 1 dado, nadie recibe oferta y la oportunidad
      // de todos ellos queda pendiente (no se marca offeredOnce).
    }
    _beginRound(starter);
  }
}
