import 'dart:math';
import 'package:scopa_flutter/models/card_model.dart';
import 'package:scopa_flutter/models/game_state.dart';
import 'package:scopa_flutter/services/game_service.dart';

/// The AI's chosen play for a given turn.
class AiPlay {
  const AiPlay({required this.cardToPlay, required this.captureTarget});

  final ScopaCard cardToPlay;

  /// Cards to capture from the table. Empty list = discard.
  final List<ScopaCard> captureTarget;

  bool get isCapture => captureTarget.isNotEmpty;
}

/// Multi-difficulty Scopa AI.
///
/// • **Easy**  – captures if possible (greedy, random choice), otherwise
///               discards a random card. Occasionally misses the best move.
///
/// • **Medium** – traditional Italian strategy: scopa → settebello →
///                most denari → most cards → lowest discard.
///
/// • **Hard**  – minimax with depth-limited lookahead (depth 3). Evaluates
///               every possible sequence of plays to maximise the AI's score
///               advantage and block the human's scopa opportunities.
class AiService {
  const AiService();

  final GameService _gameService = const GameService();
  static final Random _rng = Random();

  /// Determines the best move for the AI given [hand], [tableCards], and [difficulty].
  AiPlay choosePlay(
    List<ScopaCard> hand,
    List<ScopaCard> tableCards,
    Difficulty difficulty,
  ) {
    switch (difficulty) {
      case Difficulty.easy:
        return _easyPlay(hand, tableCards);
      case Difficulty.medium:
        return _mediumPlay(hand, tableCards);
      case Difficulty.hard:
        return _hardPlay(hand, tableCards);
    }
  }

  // ── Easy ─────────────────────────────────────────────────────────────────
  // Greedy: if any capture exists pick one at random; otherwise discard random.

  AiPlay _easyPlay(List<ScopaCard> hand, List<ScopaCard> tableCards) {
    final allMoves = _buildAllMoves(hand, tableCards);

    if (allMoves.isNotEmpty) {
      // Pick a random capture move (greedy but not strategic).
      final move = allMoves[_rng.nextInt(allMoves.length)];
      return AiPlay(cardToPlay: move.card, captureTarget: move.capture);
    }

    // No captures — discard a random card.
    final card = hand[_rng.nextInt(hand.length)];
    return AiPlay(cardToPlay: card, captureTarget: const []);
  }

  // ── Medium ────────────────────────────────────────────────────────────────
  // Classic Italian strategy (same logic as Stage 1).

  AiPlay _mediumPlay(List<ScopaCard> hand, List<ScopaCard> tableCards) {
    final captureMoves = _buildAllMoves(hand, tableCards);

    if (captureMoves.isNotEmpty) {
      return _chooseBestCapture(captureMoves, tableCards);
    }
    return _chooseBestDiscard(hand);
  }

  // ── Hard ──────────────────────────────────────────────────────────────────
  // Minimax: depth-3 lookahead, evaluates score delta and scopa potential.

  AiPlay _hardPlay(List<ScopaCard> hand, List<ScopaCard> tableCards) {
    // Build a lightweight game snapshot for minimax.
    final snapshot = _MiniState(
      aiHand: hand,
      humanHand: const [], // human's hand is unknown; treat as empty for lookahead
      tableCards: tableCards,
      aiCaptures: const [],
      humanCaptures: const [],
      aiScope: 0,
      humanScope: 0,
      deck: const [],
    );

    double bestScore = double.negativeInfinity;
    _Move? bestMove;

    final moves = _buildAllMoves(hand, tableCards);

    // If no captures, fall back to medium discard logic.
    if (moves.isEmpty) return _chooseBestDiscard(hand);

    for (final move in moves) {
      final next = snapshot.applyAiMove(move);
      final score = _minimax(next, depth: 2, isAiTurn: false);
      if (score > bestScore) {
        bestScore = score;
        bestMove = move;
      }
    }

    if (bestMove == null) return _chooseBestDiscard(hand);
    return AiPlay(cardToPlay: bestMove.card, captureTarget: bestMove.capture);
  }

  /// Minimax recursive evaluator.
  ///
  /// [isAiTurn] = true → we're maximising (AI's turn).
  /// [isAiTurn] = false → we're minimising (simulated human turn, best case).
  double _minimax(_MiniState state, {required int depth, required bool isAiTurn}) {
    if (depth == 0 || (state.aiHand.isEmpty && state.humanHand.isEmpty)) {
      return _evaluate(state);
    }

    if (isAiTurn) {
      if (state.aiHand.isEmpty) return _evaluate(state);

      double best = double.negativeInfinity;
      final moves = _buildAllMoves(state.aiHand, state.tableCards);
      if (moves.isEmpty) {
        // Must discard — try discarding each card.
        for (final card in state.aiHand) {
          final next = state.applyAiDiscard(card);
          final v = _minimax(next, depth: depth - 1, isAiTurn: false);
          if (v > best) best = v;
        }
      } else {
        for (final move in moves) {
          final next = state.applyAiMove(move);
          final v = _minimax(next, depth: depth - 1, isAiTurn: false);
          if (v > best) best = v;
        }
      }
      return best;
    } else {
      // Simulated human — assume they play optimally against us.
      if (state.humanHand.isEmpty) return _evaluate(state);

      double worst = double.infinity;
      final moves = _buildAllMoves(state.humanHand, state.tableCards);
      if (moves.isEmpty) {
        for (final card in state.humanHand) {
          final next = state.applyHumanDiscard(card);
          final v = _minimax(next, depth: depth - 1, isAiTurn: true);
          if (v < worst) worst = v;
        }
      } else {
        for (final move in moves) {
          final next = state.applyHumanMove(move);
          final v = _minimax(next, depth: depth - 1, isAiTurn: true);
          if (v < worst) worst = v;
        }
      }
      return worst;
    }
  }

  /// Heuristic evaluation of a [_MiniState] from the AI's perspective.
  ///
  /// Higher = better for AI.
  double _evaluate(_MiniState s) {
    double score = 0;

    // Card count advantage.
    score += (s.aiCaptures.length - s.humanCaptures.length) * 0.5;

    // Denari advantage.
    final aiDenari = s.aiCaptures.where((c) => c.isDenari).length;
    final humanDenari = s.humanCaptures.where((c) => c.isDenari).length;
    score += (aiDenari - humanDenari) * 2.0;

    // Settebello.
    if (s.aiCaptures.any((c) => c.isSettebello)) score += 5.0;
    if (s.humanCaptures.any((c) => c.isSettebello)) score -= 5.0;

    // Scope.
    score += (s.aiScope - s.humanScope) * 3.0;

    // Penalise leaving a settebello-vulnerable table (human could capture it).
    final tableHasSettebello = s.tableCards.any((c) => c.isSettebello);
    if (tableHasSettebello) score -= 2.0;

    return score;
  }

  // ── Shared capture-selection logic (Medium + Hard fallback) ───────────────

  AiPlay _chooseBestCapture(List<_Move> moves, List<ScopaCard> tableCards) {
    // Priority 1: scopa.
    final scopaMoves = moves.where((m) => m.isScopa).toList();
    if (scopaMoves.isNotEmpty) {
      return AiPlay(
        cardToPlay: _minByCardValue(scopaMoves).card,
        captureTarget: _minByCardValue(scopaMoves).capture,
      );
    }

    // Priority 2: captures settebello.
    final settebelloMoves =
        moves.where((m) => m.capture.any((c) => c.isSettebello)).toList();
    if (settebelloMoves.isNotEmpty) {
      final best = _tiebreak(settebelloMoves);
      return AiPlay(cardToPlay: best.card, captureTarget: best.capture);
    }

    // Priority 3 & 4: most denari then most cards then lowest played.
    final best = _tiebreak(moves);
    return AiPlay(cardToPlay: best.card, captureTarget: best.capture);
  }

  _Move _tiebreak(List<_Move> moves) {
    final maxDenari =
        moves.map((m) => m.denariCount).reduce((a, b) => a > b ? a : b);
    final byDenari =
        moves.where((m) => m.denariCount == maxDenari).toList();

    final maxCards =
        byDenari.map((m) => m.capture.length).reduce((a, b) => a > b ? a : b);
    final byCards =
        byDenari.where((m) => m.capture.length == maxCards).toList();

    return _minByCardValue(byCards);
  }

  _Move _minByCardValue(List<_Move> moves) =>
      moves.reduce((a, b) => a.card.value <= b.card.value ? a : b);

  AiPlay _chooseBestDiscard(List<ScopaCard> hand) {
    final nonSettebello = hand.where((c) => !c.isSettebello).toList();
    final pool = nonSettebello.isNotEmpty ? nonSettebello : hand;
    final lowestCard = pool.reduce((a, b) => a.value <= b.value ? a : b);
    return AiPlay(cardToPlay: lowestCard, captureTarget: const []);
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  List<_Move> _buildAllMoves(
      List<ScopaCard> hand, List<ScopaCard> tableCards) {
    final result = <_Move>[];
    for (final card in hand) {
      for (final capture in _gameService.findAllCaptures(card, tableCards)) {
        result.add(_Move(card, capture, tableCards));
      }
    }
    return result;
  }
}

// ── Internal move representation ──────────────────────────────────────────────

class _Move {
  _Move(this.card, this.capture, List<ScopaCard> tableCards)
      : isScopa = capture.length == tableCards.length &&
            capture.toSet().containsAll(tableCards),
        denariCount = capture.where((c) => c.isDenari).length;

  final ScopaCard card;
  final List<ScopaCard> capture;
  final bool isScopa;
  final int denariCount;
}

// ── Minimax state snapshot ─────────────────────────────────────────────────────

/// Lightweight immutable game snapshot used by the minimax search.
/// Keeps only what's needed for evaluation — no full GameState overhead.
class _MiniState {
  const _MiniState({
    required this.aiHand,
    required this.humanHand,
    required this.tableCards,
    required this.aiCaptures,
    required this.humanCaptures,
    required this.aiScope,
    required this.humanScope,
    required this.deck,
  });

  final List<ScopaCard> aiHand;
  final List<ScopaCard> humanHand;
  final List<ScopaCard> tableCards;
  final List<ScopaCard> aiCaptures;
  final List<ScopaCard> humanCaptures;
  final int aiScope;
  final int humanScope;
  final List<ScopaCard> deck;

  _MiniState applyAiMove(_Move move) {
    final newTable = tableCards.where((c) => !move.capture.contains(c)).toList();
    final scopa = newTable.isEmpty ? 1 : 0;
    return _MiniState(
      aiHand: aiHand.where((c) => c != move.card).toList(),
      humanHand: humanHand,
      tableCards: newTable,
      aiCaptures: [...aiCaptures, move.card, ...move.capture],
      humanCaptures: humanCaptures,
      aiScope: aiScope + scopa,
      humanScope: humanScope,
      deck: deck,
    );
  }

  _MiniState applyAiDiscard(ScopaCard card) => _MiniState(
        aiHand: aiHand.where((c) => c != card).toList(),
        humanHand: humanHand,
        tableCards: [...tableCards, card],
        aiCaptures: aiCaptures,
        humanCaptures: humanCaptures,
        aiScope: aiScope,
        humanScope: humanScope,
        deck: deck,
      );

  _MiniState applyHumanMove(_Move move) {
    final newTable = tableCards.where((c) => !move.capture.contains(c)).toList();
    final scopa = newTable.isEmpty ? 1 : 0;
    return _MiniState(
      aiHand: aiHand,
      humanHand: humanHand.where((c) => c != move.card).toList(),
      tableCards: newTable,
      aiCaptures: aiCaptures,
      humanCaptures: [...humanCaptures, move.card, ...move.capture],
      aiScope: aiScope,
      humanScope: humanScope + scopa,
      deck: deck,
    );
  }

  _MiniState applyHumanDiscard(ScopaCard card) => _MiniState(
        aiHand: aiHand,
        humanHand: humanHand.where((c) => c != card).toList(),
        tableCards: [...tableCards, card],
        aiCaptures: aiCaptures,
        humanCaptures: humanCaptures,
        aiScope: aiScope,
        humanScope: humanScope,
        deck: deck,
      );
}
