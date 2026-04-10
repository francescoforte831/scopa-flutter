// Game constants and configuration for Scopa.

/// Score needed to win the game.
const int kWinningScore = 11;

/// Cards dealt to each player at the start of each hand.
const int kHandSize = 3;

/// Total cards in a Scopa deck (4 suits × 10 values).
const int kDeckSize = 40;

/// Cards placed face-up on the table at the start of each hand.
const int kInitialTableCards = 4;

/// Primiera point values per card value.
/// The player who accumulates the highest primiera score wins the primiera point.
/// One card per suit is selected (the highest-scoring in that suit).
const Map<int, int> kPrimieraValues = {
  7: 21,
  6: 18,
  1: 16,
  5: 15,
  4: 14,
  3: 13,
  2: 12,
  8: 10,
  9: 10,
  10: 10,
};

/// Display names for face card values.
const Map<int, String> kValueNames = {
  1: 'A',
  8: 'F',  // Fante (Jack)
  9: 'C',  // Cavallo (Knight)
  10: 'R', // Re (King)
};

/// Animation durations.
const Duration kCardFlyDuration = Duration(milliseconds: 500);
const Duration kScopaFlashDuration = Duration(milliseconds: 900);
const Duration kAiThinkDuration = Duration(milliseconds: 900);
const Duration kDealStaggerDelay = Duration(milliseconds: 100);
