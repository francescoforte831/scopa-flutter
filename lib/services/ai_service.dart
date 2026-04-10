import 'package:scopa_flutter/models/card_model.dart';
import 'package:scopa_flutter/services/game_service.dart';

/// The AI's chosen play for a given turn.
class AiPlay {
  const AiPlay({required this.cardToPlay, required this.captureTarget});

  final ScopaCard cardToPlay;

  /// Cards to capture from the table. Empty list = discard.
  final List<ScopaCard> captureTarget;

  bool get isCapture => captureTarget.isNotEmpty;
}

/// Traditional Italian Scopa AI strategy.
///
/// Priority order (from highest to lowest):
///   1. Scopa – always take an opportunity to clear the table.
///   2. Capture settebello (7 of denari).
///   3. Capture the most denari cards.
///   4. Capture the most cards total.
///   5. Play the lowest-value card from hand (discard).
///
/// Within each priority level, ties are broken by:
///   most denari > most cards total > lowest card value played.
class AiService {
  const AiService();

  final GameService _gameService = const GameService();

  /// Determines the best move for the AI given its [hand] and the [tableCards].
  AiPlay choosePlay(List<ScopaCard> hand, List<ScopaCard> tableCards) {
    // Build all possible capture moves.
    final captureMoves = <_Move>[];
    for (final card in hand) {
      final captures = _gameService.findAllCaptures(card, tableCards);
      for (final capture in captures) {
        captureMoves.add(_Move(card, capture, tableCards));
      }
    }

    if (captureMoves.isNotEmpty) {
      return _chooseBestCapture(captureMoves, tableCards);
    }

    // No captures available — discard the lowest card, protecting settebello.
    return _chooseBestDiscard(hand);
  }

  // ── Capture selection ─────────────────────────────────────────────────────

  AiPlay _chooseBestCapture(List<_Move> moves, List<ScopaCard> tableCards) {
    // Priority 1: scopa (clears entire table).
    final scopaMoves = moves.where((m) => m.isScopa).toList();
    if (scopaMoves.isNotEmpty) {
      // All scopa moves are equivalent — pick the one that plays lowest card.
      final best = _minByCardValue(scopaMoves);
      return AiPlay(cardToPlay: best.card, captureTarget: best.capture);
    }

    // Priority 2: captures settebello.
    final settebelloMoves =
        moves.where((m) => m.capture.any((c) => c.isSettebello)).toList();
    if (settebelloMoves.isNotEmpty) {
      final best = _tiebreak(settebelloMoves);
      return AiPlay(cardToPlay: best.card, captureTarget: best.capture);
    }

    // Priority 3 & 4: most denari, then most cards, then lowest played.
    final best = _tiebreak(moves);
    return AiPlay(cardToPlay: best.card, captureTarget: best.capture);
  }

  /// Tiebreak: most denari → most cards → lowest card value.
  _Move _tiebreak(List<_Move> moves) {
    // Most denari captured.
    final maxDenari = moves.map((m) => m.denariCount).reduce(
      (a, b) => a > b ? a : b,
    );
    final byDenari = moves.where((m) => m.denariCount == maxDenari).toList();

    // Most cards captured.
    final maxCards = byDenari.map((m) => m.capture.length).reduce(
      (a, b) => a > b ? a : b,
    );
    final byCards = byDenari.where((m) => m.capture.length == maxCards).toList();

    return _minByCardValue(byCards);
  }

  _Move _minByCardValue(List<_Move> moves) {
    return moves.reduce((a, b) => a.card.value <= b.card.value ? a : b);
  }

  // ── Discard selection ─────────────────────────────────────────────────────

  AiPlay _chooseBestDiscard(List<ScopaCard> hand) {
    // Prefer not discarding settebello.
    final nonSettebello = hand.where((c) => !c.isSettebello).toList();
    final pool = nonSettebello.isNotEmpty ? nonSettebello : hand;

    // Discard the lowest-value card.
    final lowestCard = pool.reduce((a, b) => a.value <= b.value ? a : b);
    return AiPlay(cardToPlay: lowestCard, captureTarget: const []);
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
