import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scopa_flutter/core/constants.dart';
import 'package:scopa_flutter/models/card_model.dart';
import 'package:scopa_flutter/models/game_state.dart';
import 'package:scopa_flutter/models/player_model.dart';
import 'package:scopa_flutter/providers/providers.dart';
import 'package:scopa_flutter/services/ai_service.dart';
import 'package:scopa_flutter/services/deck_service.dart';
import 'package:scopa_flutter/services/game_service.dart';

/// Provider for the primary game state.
final gameProvider = StateNotifierProvider<GameNotifier, GameState>((ref) {
  return GameNotifier(
    deckService: ref.read(deckServiceProvider),
    gameService: ref.read(gameServiceProvider),
    aiService: ref.read(aiServiceProvider),
  );
});

/// Manages all Scopa game state transitions.
///
/// The UI should call public methods to drive state forward; it should never
/// mutate state directly. Side effects (navigation, animations) are triggered
/// by observing [GameState.phase] and [GameState.lastAction] from the UI.
class GameNotifier extends StateNotifier<GameState> {
  GameNotifier({
    required DeckService deckService,
    required GameService gameService,
    required AiService aiService,
  })  : _deck = deckService,
        _game = gameService,
        _ai = aiService,
        super(_emptyState());

  final DeckService _deck;
  final GameService _game;
  final AiService _ai;

  /// ID of the last player to have captured cards (for end-of-hand table sweep).
  String? _lastCaptorId;

  // ── Game lifecycle ────────────────────────────────────────────────────────

  /// Starts a fresh game with the selected [difficulty].
  void startNewGame({Difficulty difficulty = Difficulty.medium}) {
    _lastCaptorId = null;
    state = _emptyState().copyWith(
      phase: GamePhase.dealing,
      difficulty: difficulty,
    );
    _dealHand(resetScores: true);
  }

  /// Starts the next hand in an ongoing game, preserving cumulative scores.
  void startNewHand() {
    _lastCaptorId = null;
    _dealHand(resetScores: false);
  }

  /// Computes the score for the completed hand, awards remaining table cards
  /// to the last captor, updates cumulative scores, and returns a full result.
  HandScoringResult acknowledgeHandEnd() {
    // Award remaining table cards to the last captor (NOT a scopa).
    Player human = state.humanPlayer;
    Player ai = state.aiPlayer;

    if (state.tableCards.isNotEmpty && _lastCaptorId != null) {
      if (_lastCaptorId == 'human') {
        human = human.copyWith(
          captured: [...human.captured, ...state.tableCards],
        );
      } else {
        ai = ai.copyWith(
          captured: [...ai.captured, ...state.tableCards],
        );
      }
    }

    final result = _game.scoreHand(
      human: human,
      ai: ai,
      humanGameScore: state.humanScore,
      aiGameScore: state.aiScore,
      winningScore: kWinningScore,
    );

    state = state.copyWith(
      humanPlayer: human,
      aiPlayer: ai,
      tableCards: [],
      humanScore: result.humanGameTotal,
      aiScore: result.aiGameTotal,
      phase: result.isGameOver ? GamePhase.gameOver : GamePhase.handOver,
    );

    return result;
  }

  // ── Player actions ────────────────────────────────────────────────────────

  /// Called when the human player plays [card], optionally capturing [target].
  ///
  /// [target] is empty when the player is discarding (no capture).
  void humanPlayCard(ScopaCard card, List<ScopaCard> target) {
    if (!state.isPlayerTurn) return;
    if (!state.humanPlayer.hand.contains(card)) return;

    _processPlay(actorId: 'human', card: card, target: target);
  }

  /// Called by GameScreen (via ref.listen) when phase == aiTurn.
  ///
  /// Runs after a brief artificial delay to give the impression of thought.
  Future<void> resolveAiTurn() async {
    if (!state.isAiTurn) return;
    await Future<void>.delayed(kAiThinkDuration);
    if (!mounted || !state.isAiTurn) return;

    final play = _ai.choosePlay(
      state.aiPlayer.hand,
      state.tableCards,
      state.difficulty,
    );
    _processPlay(
      actorId: 'ai',
      card: play.cardToPlay,
      target: play.captureTarget,
    );
  }

  /// Clears [GameState.lastAction] after the UI has finished animating.
  void clearLastAction() {
    state = state.copyWith(clearLastAction: true);
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  void _processPlay({
    required String actorId,
    required ScopaCard card,
    required List<ScopaCard> target,
  }) {
    Player human = state.humanPlayer;
    Player ai = state.aiPlayer;
    List<ScopaCard> table = List.of(state.tableCards);
    List<ScopaCard> deck = List.of(state.deck);

    final isHuman = actorId == 'human';
    Player actor = isHuman ? human : ai;

    // Remove played card from hand.
    final newHand = List.of(actor.hand)..remove(card);

    bool wasScopa = false;

    if (target.isNotEmpty) {
      // Capture: remove target cards from table, add all to actor's pile.
      for (final c in target) {
        table.remove(c);
      }
      final newCaptured = [...actor.captured, card, ...target];

      // Detect scopa: table is now empty — but only if it's not the last
      // capture of the last hand (deck empty, after this no more cards dealt).
      final isLastCaptureOfHand =
          deck.isEmpty && newHand.isEmpty &&
          (isHuman ? ai.hand.isEmpty : human.hand.isEmpty);
      wasScopa = table.isEmpty && !isLastCaptureOfHand;

      actor = actor.copyWith(
        hand: newHand,
        captured: newCaptured,
        scopeCount: actor.scopeCount + (wasScopa ? 1 : 0),
      );
      _lastCaptorId = actorId;
    } else {
      // Discard: add card to table.
      table.add(card);
      actor = actor.copyWith(hand: newHand);
    }

    if (isHuman) {
      human = actor;
    } else {
      ai = actor;
    }

    final lastAction = LastAction(
      actorId: actorId,
      cardPlayed: card,
      captured: target,
      wasScopa: wasScopa,
    );

    // Determine next phase.
    GamePhase nextPhase;
    if (human.hand.isEmpty && ai.hand.isEmpty) {
      if (deck.isEmpty) {
        nextPhase = GamePhase.handOver;
      } else {
        // Deal 3 more to each player.
        final humanDeal = _game.dealCards(deck, kHandSize);
        deck = List.of(humanDeal.remaining);
        human = human.copyWith(hand: List.of(humanDeal.dealt));

        final aiDeal = _game.dealCards(deck, kHandSize);
        deck = List.of(aiDeal.remaining);
        ai = ai.copyWith(hand: List.of(aiDeal.dealt));

        nextPhase = GamePhase.playerTurn;
      }
    } else {
      nextPhase = isHuman ? GamePhase.aiTurn : GamePhase.playerTurn;
    }

    state = state.copyWith(
      humanPlayer: human,
      aiPlayer: ai,
      tableCards: table,
      deck: deck,
      phase: nextPhase,
      lastAction: lastAction,
    );
  }

  void _dealHand({required bool resetScores}) {
    List<ScopaCard> deck;
    List<ScopaCard> tableCards;
    Player human;
    Player ai;

    // Keep re-dealing if the 3-of-a-suit rule triggers.
    do {
      deck = _deck.createShuffledDeck();
      final tableDeal = _game.dealCards(deck, kInitialTableCards);
      tableCards = List.of(tableDeal.dealt);
      deck = List.of(tableDeal.remaining);
    } while (_game.shouldRedeal(tableCards));

    // Deal hands.
    final humanDeal = _game.dealCards(deck, kHandSize);
    deck = List.of(humanDeal.remaining);

    final aiDeal = _game.dealCards(deck, kHandSize);
    deck = List.of(aiDeal.remaining);

    human = (resetScores
            ? const Player(id: 'human', name: 'You')
            : state.humanPlayer)
        .copyWith(
      hand: List.of(humanDeal.dealt),
      captured: const [],
      scopeCount: 0,
    );

    ai = (resetScores
            ? const Player(id: 'ai', name: 'Computer')
            : state.aiPlayer)
        .copyWith(
      hand: List.of(aiDeal.dealt),
      captured: const [],
      scopeCount: 0,
    );

    state = state.copyWith(
      humanPlayer: human,
      aiPlayer: ai,
      tableCards: tableCards,
      deck: deck,
      handNumber: resetScores ? 1 : state.handNumber + 1,
      phase: GamePhase.playerTurn,
      humanScore: resetScores ? 0 : state.humanScore,
      aiScore: resetScores ? 0 : state.aiScore,
      clearLastAction: true,
    );
  }

  static GameState _emptyState() => const GameState(
        humanPlayer: Player(id: 'human', name: 'You'),
        aiPlayer: Player(id: 'ai', name: 'Computer'),
        tableCards: [],
        deck: [],
        handNumber: 0,
        phase: GamePhase.playerTurn,
        humanScore: 0,
        aiScore: 0,
      );
}
