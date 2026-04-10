import 'package:scopa_flutter/models/card_model.dart';

/// Responsible for creating and shuffling the Scopa deck.
class DeckService {
  /// Creates a full 40-card Scopa deck (4 suits × 10 values) and shuffles it.
  List<ScopaCard> createShuffledDeck() {
    final deck = [
      for (final suit in Suit.values)
        for (int v = 1; v <= 10; v++) ScopaCard(suit: suit, value: v),
    ];
    deck.shuffle();
    return deck;
  }
}
