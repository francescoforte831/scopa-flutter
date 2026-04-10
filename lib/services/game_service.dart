import 'package:scopa_flutter/models/card_model.dart';
import 'package:scopa_flutter/models/game_state.dart';
import 'package:scopa_flutter/models/player_model.dart';

/// Pure game-rule functions. No state, no side-effects.
///
/// All methods are static for easy testing and use from any layer.
class GameService {
  const GameService();

  // ── Deck dealing ──────────────────────────────────────────────────────────

  /// Deals [count] cards from the front of [deck].
  ///
  /// Returns a named record with the dealt cards and the remaining deck.
  ({List<ScopaCard> dealt, List<ScopaCard> remaining}) dealCards(
    List<ScopaCard> deck,
    int count,
  ) {
    assert(deck.length >= count, 'Not enough cards in deck');
    return (
      dealt: List.unmodifiable(deck.take(count).toList()),
      remaining: List.unmodifiable(deck.skip(count).toList()),
    );
  }

  /// Returns true if the initial 4 table cards should trigger a re-deal.
  ///
  /// Traditional rule: if 3 or more cards share the same suit, re-deal.
  bool shouldRedeal(List<ScopaCard> tableCards) {
    for (final suit in Suit.values) {
      if (tableCards.where((c) => c.suit == suit).length >= 3) return true;
    }
    return false;
  }

  // ── Capture logic ─────────────────────────────────────────────────────────

  /// Returns all valid capture sets for [played] against [table].
  ///
  /// **Single-card priority rule**: if any single table card matches
  /// [played.value], only those single-card captures are valid — the player
  /// cannot choose a multi-card combination summing to the same value.
  List<List<ScopaCard>> findAllCaptures(
    ScopaCard played,
    List<ScopaCard> table,
  ) {
    if (table.isEmpty) return [];

    // Check for single-card matches first (priority rule).
    final singleMatches = table.where((c) => c.value == played.value).toList();
    if (singleMatches.isNotEmpty) {
      // Only single-card captures are allowed when a direct match exists.
      return singleMatches.map((c) => [c]).toList();
    }

    // No single match — find all subset combinations that sum to played.value.
    return _findSubsetSums(played.value, table);
  }

  /// Validates whether [target] is a legal capture for [played] given [table].
  bool isValidPlay(
    ScopaCard played,
    List<ScopaCard> target,
    List<ScopaCard> table,
  ) {
    if (target.isEmpty) {
      // Discard is only valid if no capture exists.
      return findAllCaptures(played, table).isEmpty;
    }

    final validCaptures = findAllCaptures(played, table);
    return validCaptures.any((capture) => _setsEqual(capture, target));
  }

  /// Returns true if the played card clears the entire table (= scopa).
  ///
  /// [isLastCaptureOfHand] must be true when this is the very last capture
  /// of the final hand — in that case it is NOT a scopa by traditional rules.
  bool isScopa(List<ScopaCard> tableCards, bool isLastCaptureOfHand) {
    if (isLastCaptureOfHand) return false;
    // Table was already cleared: captured == all tableCards.
    return tableCards.isEmpty;
  }

  // ── Hand scoring ──────────────────────────────────────────────────────────

  /// Computes the full scoring breakdown for a completed hand.
  ///
  /// [remainingTableCards] are any cards left on the table after the final
  /// card is played — they go to the last captor but do NOT count as a scopa.
  HandScoringResult scoreHand({
    required Player human,
    required Player ai,
    required int humanGameScore,
    required int aiGameScore,
    required int winningScore,
  }) {
    // Carte – most captured cards.
    final humanCarte = human.capturedCount > ai.capturedCount ? 1 : 0;
    final aiCarte = ai.capturedCount > human.capturedCount ? 1 : 0;

    // Denari – most coins cards.
    final humanDenari = human.denariCount > ai.denariCount ? 1 : 0;
    final aiDenari = ai.denariCount > human.denariCount ? 1 : 0;

    // Settebello – 7 of denari.
    final humanSettebello = human.hasCapturedSettebello ? 1 : 0;
    final aiSettebello = ai.hasCapturedSettebello ? 1 : 0;

    // Primiera.
    final humanPrimScore = _primieraScore(human.captured);
    final aiPrimScore = _primieraScore(ai.captured);
    final humanPrimiera = (humanPrimScore > 0 && humanPrimScore > aiPrimScore) ? 1 : 0;
    final aiPrimiera = (aiPrimScore > 0 && aiPrimScore > humanPrimScore) ? 1 : 0;

    // Scope (accumulated during play).
    final humanScope = human.scopeCount;
    final aiScope = ai.scopeCount;

    final humanHandTotal =
        humanCarte + humanDenari + humanSettebello + humanPrimiera + humanScope;
    final aiHandTotal =
        aiCarte + aiDenari + aiSettebello + aiPrimiera + aiScope;

    final newHumanTotal = humanGameScore + humanHandTotal;
    final newAiTotal = aiGameScore + aiHandTotal;

    final gameOver = newHumanTotal >= winningScore || newAiTotal >= winningScore;
    String? winner;
    if (gameOver) {
      if (newHumanTotal > newAiTotal) {
        winner = 'human';
      } else if (newAiTotal > newHumanTotal) {
        winner = 'ai';
      } else {
        winner = 'draw';
      }
    }

    return HandScoringResult(
      humanCarte: humanCarte,
      humanDenari: humanDenari,
      humanSettebello: humanSettebello,
      humanPrimiera: humanPrimiera,
      humanScope: humanScope,
      aiCarte: aiCarte,
      aiDenari: aiDenari,
      aiSettebello: aiSettebello,
      aiPrimiera: aiPrimiera,
      aiScope: aiScope,
      humanHandTotal: humanHandTotal,
      aiHandTotal: aiHandTotal,
      humanGameTotal: newHumanTotal,
      aiGameTotal: newAiTotal,
      isGameOver: gameOver,
      winner: winner,
    );
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  /// Finds all subsets of [cards] whose values sum to [target].
  List<List<ScopaCard>> _findSubsetSums(int target, List<ScopaCard> cards) {
    final results = <List<ScopaCard>>[];
    _subsetsHelper(target, cards, 0, [], results);
    return results;
  }

  void _subsetsHelper(
    int remaining,
    List<ScopaCard> cards,
    int startIndex,
    List<ScopaCard> current,
    List<List<ScopaCard>> results,
  ) {
    if (remaining == 0 && current.isNotEmpty) {
      results.add(List.of(current));
      return;
    }
    for (int i = startIndex; i < cards.length; i++) {
      if (cards[i].value <= remaining) {
        current.add(cards[i]);
        _subsetsHelper(remaining - cards[i].value, cards, i + 1, current, results);
        current.removeLast();
      }
    }
  }

  bool _setsEqual(List<ScopaCard> a, List<ScopaCard> b) {
    if (a.length != b.length) return false;
    final sortedA = [...a]..sort((x, y) => x.toString().compareTo(y.toString()));
    final sortedB = [...b]..sort((x, y) => x.toString().compareTo(y.toString()));
    for (int i = 0; i < sortedA.length; i++) {
      if (sortedA[i] != sortedB[i]) return false;
    }
    return true;
  }

  /// Calculates the primiera score for a set of captured cards.
  ///
  /// For each suit, take the highest-primiera-valued card. Sum all four.
  /// Returns -1 if the player has no card in at least one suit (loses primiera).
  int _primieraScore(List<ScopaCard> captured) {
    int total = 0;
    for (final suit in Suit.values) {
      final suitCards = captured.where((c) => c.suit == suit).toList();
      if (suitCards.isEmpty) return -1; // Missing suit — cannot win primiera.
      final best = suitCards.map((c) => c.primieraScore).reduce(
        (a, b) => a > b ? a : b,
      );
      total += best;
    }
    return total;
  }
}
