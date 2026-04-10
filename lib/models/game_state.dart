import 'package:equatable/equatable.dart';
import 'package:scopa_flutter/models/card_model.dart';
import 'package:scopa_flutter/models/player_model.dart';

/// All phases the game can be in.
enum GamePhase {
  /// Cards are being dealt (animation state).
  dealing,

  /// Waiting for the human player to act.
  playerTurn,

  /// The AI is computing and playing its move.
  aiTurn,

  /// Both hands are empty and the deck is exhausted — ready for scoring.
  handOver,

  /// At least one player has reached the winning score.
  gameOver,
}

/// Records the most recent action so the UI can trigger animations.
///
/// Reset to null by the UI once animations are complete.
class LastAction extends Equatable {
  const LastAction({
    required this.actorId,
    required this.cardPlayed,
    required this.captured,
    required this.wasScopa,
  });

  /// 'human' or 'ai'.
  final String actorId;
  final ScopaCard cardPlayed;

  /// Cards removed from the table (empty = discard).
  final List<ScopaCard> captured;

  /// Whether this action emptied the table (= scopa).
  final bool wasScopa;

  bool get isCapture => captured.isNotEmpty;

  @override
  List<Object?> get props => [actorId, cardPlayed, captured, wasScopa];
}

/// Complete snapshot of the game at any point in time.
///
/// All fields are immutable; state transitions create new instances via [copyWith].
class GameState extends Equatable {
  const GameState({
    required this.humanPlayer,
    required this.aiPlayer,
    required this.tableCards,
    required this.deck,
    required this.handNumber,
    required this.phase,
    required this.humanScore,
    required this.aiScore,
    this.lastAction,
  });

  final Player humanPlayer;
  final Player aiPlayer;
  final List<ScopaCard> tableCards;

  /// Remaining cards in the draw deck.
  final List<ScopaCard> deck;

  /// Number of full hands played so far (increments at start of each new hand).
  final int handNumber;

  final GamePhase phase;

  /// Cumulative game score (across all hands) for the human.
  final int humanScore;

  /// Cumulative game score (across all hands) for the AI.
  final int aiScore;

  /// The most recently completed action, used to trigger UI animations.
  final LastAction? lastAction;

  // ── Computed helpers ─────────────────────────────────────────────────────

  bool get isPlayerTurn => phase == GamePhase.playerTurn;
  bool get isAiTurn => phase == GamePhase.aiTurn;
  bool get isHandOver => phase == GamePhase.handOver;
  bool get isGameOver => phase == GamePhase.gameOver;

  // ── Immutable update ─────────────────────────────────────────────────────

  GameState copyWith({
    Player? humanPlayer,
    Player? aiPlayer,
    List<ScopaCard>? tableCards,
    List<ScopaCard>? deck,
    int? handNumber,
    GamePhase? phase,
    int? humanScore,
    int? aiScore,
    LastAction? lastAction,
    bool clearLastAction = false,
  }) {
    return GameState(
      humanPlayer: humanPlayer ?? this.humanPlayer,
      aiPlayer: aiPlayer ?? this.aiPlayer,
      tableCards: tableCards ?? this.tableCards,
      deck: deck ?? this.deck,
      handNumber: handNumber ?? this.handNumber,
      phase: phase ?? this.phase,
      humanScore: humanScore ?? this.humanScore,
      aiScore: aiScore ?? this.aiScore,
      lastAction: clearLastAction ? null : (lastAction ?? this.lastAction),
    );
  }

  @override
  List<Object?> get props => [
    humanPlayer, aiPlayer, tableCards, deck,
    handNumber, phase, humanScore, aiScore, lastAction,
  ];
}

// ── Scoring result ────────────────────────────────────────────────────────────

/// Per-hand scoring breakdown passed to ScoringScreen.
class HandScoringResult extends Equatable {
  const HandScoringResult({
    required this.humanCarte,
    required this.humanDenari,
    required this.humanSettebello,
    required this.humanPrimiera,
    required this.humanScope,
    required this.aiCarte,
    required this.aiDenari,
    required this.aiSettebello,
    required this.aiPrimiera,
    required this.aiScope,
    required this.humanHandTotal,
    required this.aiHandTotal,
    required this.humanGameTotal,
    required this.aiGameTotal,
    required this.isGameOver,
    this.winner,
  });

  // Per-hand points (each is 0 or 1, scope can be >1)
  final int humanCarte;
  final int humanDenari;
  final int humanSettebello;
  final int humanPrimiera;
  final int humanScope;

  final int aiCarte;
  final int aiDenari;
  final int aiSettebello;
  final int aiPrimiera;
  final int aiScope;

  final int humanHandTotal;
  final int aiHandTotal;

  /// Cumulative game totals after this hand.
  final int humanGameTotal;
  final int aiGameTotal;

  final bool isGameOver;

  /// 'human', 'ai', or null if game is still in progress.
  final String? winner;

  @override
  List<Object?> get props => [
    humanCarte, humanDenari, humanSettebello, humanPrimiera, humanScope,
    aiCarte, aiDenari, aiSettebello, aiPrimiera, aiScope,
    humanHandTotal, aiHandTotal, humanGameTotal, aiGameTotal,
    isGameOver, winner,
  ];
}
