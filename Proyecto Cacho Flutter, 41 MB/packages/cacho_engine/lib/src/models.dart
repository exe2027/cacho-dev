import 'dart:collection';
import 'dart:math';

/// Pintas con sus nombres chilenos (decisión 14).
enum Pinta {
  as(1, 'As'),
  pato(2, 'Pato'),
  tren(3, 'Tren'),
  cuadra(4, 'Cuadra'),
  quinta(5, 'Quinta'),
  sexta(6, 'Sexta');

  final int valor;
  final String nombre;
  const Pinta(this.valor, this.nombre);

  static Pinta fromValor(int v) => values.firstWhere((p) => p.valor == v,
      orElse: () => throw ArgumentError('pinta inválida: $v'));
}

/// Cómo cuenta un dado al resolver una apuesta.
enum DieMark { exact, wild, miss }

/// Resultado de evaluar una apuesta sobre las manos reveladas:
/// marcas por jugador y totales (para la pantalla de revelación).
class BidEvaluation {
  final Map<String, List<DieMark>> marks;
  final int exact;
  final int wild;
  const BidEvaluation(
      {required this.marks, required this.exact, required this.wild});
  int get total => exact + wild;
}

/// Una apuesta: [quantity] dados de la pinta [face] (1..6) sobre la mesa.
class Bid {
  final int quantity;
  final int face;
  const Bid(this.quantity, this.face);

  @override
  bool operator ==(Object other) =>
      other is Bid && other.quantity == quantity && other.face == face;

  @override
  int get hashCode => Object.hash(quantity, face);

  @override
  String toString() => '$quantity ${Pinta.fromValor(face).nombre}';
}

/// Jugada ilegal. [code] es estable y lo consumen UI, bots y servidor.
class IllegalMove implements Exception {
  final String code;
  final String message;
  const IllegalMove(this.code, this.message);
  @override
  String toString() => 'IllegalMove($code): $message';
}

/// Fuente de tiradas de dados. El motor NUNCA tira por su cuenta:
/// producción inyecta azar seguro; los tests, un guion exacto.
abstract interface class DiceRoller {
  int rollDie();
}

class RandomDiceRoller implements DiceRoller {
  final Random _random;
  RandomDiceRoller([Random? random]) : _random = random ?? Random.secure();
  @override
  int rollDie() => _random.nextInt(6) + 1;
}

/// Rodador guionado para tests deterministas.
class ScriptedDiceRoller implements DiceRoller {
  final Queue<int> _queue;
  ScriptedDiceRoller(Iterable<int> values) : _queue = Queue.of(values);
  @override
  int rollDie() {
    if (_queue.isEmpty) {
      throw StateError('ScriptedDiceRoller agotado: faltan valores en el guion');
    }
    return _queue.removeFirst();
  }

  void addAll(Iterable<int> values) => _queue.addAll(values);
  int get remaining => _queue.length;
}

enum GamePhase { lobby, playing, kamikazeOffer, kamikazeChoice, finished }

enum ActionType { bid, dudo, calzo, paso, dudoPaso, calzoPaso, kamikaze }

enum ResolutionType { dudo, calzo, dudoPaso, calzoPaso, kamikaze, abandono }

/// Lo que ocurrió al resolver una jugada. Las manos reveladas aquí ya son
/// públicas; antes de una resolución, ninguna mano sale del motor excepto
/// hacia el servidor, que la entrega solo a su dueño.
class Resolution {
  final ResolutionType type;

  /// Quién perdió un dado (si alguien perdió).
  final String? loserId;

  /// Quién recuperó un dado (si alguien recuperó; puede no ganar si ya tenía 5).
  final String? gainerId;

  /// Manos reveladas por esta resolución (copias).
  final Map<String, List<int>> revealedHands;

  /// Conteo real para Dudo/Calzo.
  final int? actualCount;

  /// Número elegido en el Kamikaze.
  final int? kamikazeFace;

  /// Dados perdidos por jugador en el Kamikaze.
  final Map<String, int> kamikazeLosses;

  /// Otros jugadores que también perdieron un dado en esta resolución
  /// (Calzo perfecto con los dados completos: pierden todos los demás).
  final List<String> massLoserIds;

  /// Calzo/CalzoPaso exacto pero SIN recuperación (25-oct): el calzador
  /// no ganó ni perdió porque los dados totales en juego no superaban
  /// estrictamente la mitad del total inicial. La UI lo usa para mostrar
  /// "exacto pero sin recuperación". Falso en perfecto con total alto
  /// (ahí no hay ganancia que bloquear: pierden los demás) y en fallos;
  /// verdadero también en perfecto bloqueado con total bajo (C11, 26-oct).
  final bool recoveryBlocked;

  const Resolution({
    required this.type,
    this.loserId,
    this.gainerId,
    this.revealedHands = const {},
    this.actualCount,
    this.kamikazeFace,
    this.kamikazeLosses = const {},
    this.massLoserIds = const [],
    this.recoveryBlocked = false,
  });
}

class GameEvent {
  final int round;
  final String playerId;
  final ActionType type;
  final Bid? bid;
  const GameEvent({
    required this.round,
    required this.playerId,
    required this.type,
    this.bid,
  });
  @override
  String toString() => 'r$round $playerId ${type.name}${bid != null ? ' $bid' : ''}';
}

class PlayerState {
  final String id;
  final String name;
  int diceCount;

  /// Mano actual. Privada por diseño: solo el servidor la lee, para
  /// entregarla únicamente a su dueño.
  List<int> hand = [];

  /// El Kamikaze se ofrece una sola vez por partida. Si varios jugadores
  /// quedan con 1 dado a la vez, NO se marca: la oportunidad queda pendiente.
  bool kamikazeOfferedOnce = false;
  bool kamikazeUsed = false;

  PlayerState(this.id, this.name, this.diceCount);

  bool get eliminated => diceCount <= 0;
  bool get alive => !eliminated;
}
