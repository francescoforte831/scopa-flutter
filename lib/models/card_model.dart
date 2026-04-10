import 'package:equatable/equatable.dart';
import 'package:scopa_flutter/core/constants.dart';

/// The four suits of a Neapolitan/Piacentine deck.
enum Suit {
  coppe,   // Cups
  denari,  // Coins
  spade,   // Swords
  bastoni, // Clubs/Batons
}

/// A single card in a 40-card Italian Scopa deck.
///
/// Values: 1–10 where:
///   1  = Asso (Ace)
///   2–7 = face value
///   8  = Fante (Jack)
///   9  = Cavallo (Knight)
///   10 = Re (King)
class ScopaCard extends Equatable {
  const ScopaCard({required this.suit, required this.value});

  final Suit suit;

  /// Card value 1–10.
  final int value;

  // ── Computed properties ──────────────────────────────────────────────────

  /// True if this is the 7 of Denari — the most valuable card in Scopa.
  bool get isSettebello => suit == Suit.denari && value == 7;

  /// True for coins suit cards (used for the denari scoring category).
  bool get isDenari => suit == Suit.denari;

  /// Expected asset path for this card's PNG image.
  /// Falls back to ColoredCardFace widget if the image is not present.
  String get assetPath => 'assets/images/cards/${suit.name}_$value.png';

  /// Primiera scoring value for this card (used when calculating primiera).
  int get primieraScore => kPrimieraValues[value] ?? 10;

  /// Short display label: 'A', '2'–'7', 'F', 'C', 'R'.
  String get displayLabel => kValueNames[value] ?? '$value';

  /// Unicode symbol for the suit (used in ColoredCardFace fallback).
  String get suitSymbol {
    switch (suit) {
      case Suit.coppe:   return '🏆';
      case Suit.denari:  return '⬡';
      case Suit.spade:   return '⚔';
      case Suit.bastoni: return '♣';
    }
  }

  /// ASCII suit symbol (for compact HUD display).
  String get suitLabel {
    switch (suit) {
      case Suit.coppe:   return 'C';
      case Suit.denari:  return 'D';
      case Suit.spade:   return 'S';
      case Suit.bastoni: return 'B';
    }
  }

  @override
  List<Object?> get props => [suit, value];

  @override
  String toString() => '$displayLabel$suitLabel';
}
