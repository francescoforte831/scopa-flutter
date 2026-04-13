# Scopa — Il Gioco di Carte Italiano

> A beautiful, production-quality implementation of the classic Italian card game **Scopa**, built with Flutter.

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart)
![Riverpod](https://img.shields.io/badge/Riverpod-2.x-20232A)
![License](https://img.shields.io/badge/License-MIT-green)

---

## Screenshots

> _Coming soon — run on your device to see the Italian-themed UI in action._

---

## Features

### Stage 1 — Single Player vs AI ✅
- **Complete Scopa rule engine** — full capture logic (single-card priority rule, subset-sum multi-card captures), scopa detection, last-capture sweep
- **Traditional AI opponent** — prioritises scopa opportunities → settebello → most denari → most cards → lowest discard
- **Draggable card play** — drag-and-drop from hand to table, or tap to select + tap table card
- **Multi-capture selection** — bottom sheet picker when multiple valid captures exist
- **Smooth animations** — card deal stagger, scopa flash overlay, capture feedback (flutter_animate)
- **Full end-of-hand scoring** — Carte, Denari, Settebello, Primiera, Scope with per-category breakdown
- **Cumulative game scoring** — first to 11 points wins; game-over screen with result
- **Premium Italian UI** — deep green felt table, gold accents, Cinzel font (Google Fonts), dark navy menu
- **No image assets required** — fully playable with code-rendered card faces; drop PNGs into `assets/images/cards/` to upgrade

### Stage 2 — Difficulty Levels ✅
- **Easy** — greedy AI: captures when possible (random choice), otherwise discards a random card
- **Medium** — traditional Italian strategy (Stage 1 AI, now the default)
- **Hard** — minimax with depth-3 lookahead; evaluates score delta, denari advantage, settebello control, and scopa blocking
- **Difficulty badge** in the HUD so you always know what you're up against
- **Animated difficulty selector** on the menu with colour-coded buttons (green / gold / red)

### Stage 3 — Multi-Computer 🔜
- Play against 1–4 computer opponents
- Correct multi-player dealing and turn order

### Stage 4 — Online Multiplayer 🔜
- Firebase Firestore real-time sync
- Private rooms with 6-character share codes
- Anonymous auth — no sign-up required

---

## Tech Stack

| Layer | Technology |
|---|---|
| UI Framework | Flutter 3.x |
| State Management | Riverpod 2.x (StateNotifier) |
| Navigation | GoRouter 14.x |
| Animations | flutter_animate 4.x |
| Fonts | Google Fonts — Cinzel |
| Multiplayer (Stage 4) | Firebase Firestore + Anonymous Auth |
| AI (Stage 2+) | Minimax with alpha-beta pruning |

---

## Project Structure

```
lib/
├── main.dart                    # App entry, ProviderScope, orientation lock
├── core/
│   ├── constants.dart           # Game constants, primiera values, durations
│   ├── theme.dart               # ScopaTheme — colours, typography, button styles
│   └── router.dart              # GoRouter: /, /game, /scoring
├── models/
│   ├── card_model.dart          # ScopaCard (40-card Italian deck)
│   ├── player_model.dart        # Player (hand, captured, scopeCount)
│   └── game_state.dart          # GameState, GamePhase, LastAction, HandScoringResult
├── providers/
│   ├── game_provider.dart       # GameNotifier — all state transitions
│   └── providers.dart           # Service provider registrations
├── services/
│   ├── deck_service.dart        # Deck creation and shuffle
│   ├── game_service.dart        # Pure rule functions (captures, scopa, scoring)
│   └── ai_service.dart          # Traditional AI strategy engine
├── screens/
│   ├── menu_screen.dart         # Animated main menu
│   ├── game_screen.dart         # Game table, HUD, animation orchestration
│   └── scoring_screen.dart      # Per-hand breakdown + cumulative scores
└── widgets/
    ├── card_widget.dart          # Face-up / face-down card rendering + fallback
    ├── table_area_widget.dart    # DragTarget, capture picker, table display
    ├── hand_widget.dart          # Draggable player hand
    ├── ai_hand_widget.dart       # Face-down AI cards
    └── score_display_widget.dart # Real-time HUD (scope, cards, game score)
```

---

## Getting Started

### Requirements
- Flutter SDK ≥ 3.11
- Xcode (for iOS) or Android Studio (for Android)

### Install & Run

```bash
# Clone
git clone https://github.com/YOUR_USERNAME/scopa-flutter.git
cd scopa-flutter

# Install dependencies
flutter pub get

# Run on connected device or simulator
flutter run
```

### Run on iPhone (Physical Device)

```bash
# List connected devices
flutter devices

# Run on your iPhone
flutter run -d <your-iphone-device-id>
```

Open `ios/Runner.xcworkspace` in Xcode to configure your signing team if needed.

---

## Card Images (Optional)

The app renders cards using Flutter primitives — **no image assets are required** to play.

To add authentic Neapolitan/Piacentine card art:

1. Obtain card PNGs (e.g. public-domain Piacentine deck from [Wikimedia Commons](https://commons.wikimedia.org/wiki/Category:Piacentine_playing_cards))
2. Name them: `{suit}_{value}.png` — e.g. `denari_7.png`, `coppe_1.png`, `spade_10.png`
   - Suits: `coppe`, `denari`, `spade`, `bastoni`
   - Values: `1`–`10`
3. Place them in `assets/images/cards/`
4. Hot-restart — the app picks them up automatically

---

## Scopa Rules Implemented

- **40-card deck**: Asso (1) through Re (10) in 4 suits — Coppe, Denari, Spade, Bastoni
- **Capture logic**: match a single table card by value, OR sum any combination of table cards to your card's value
- **Single-card priority**: if a direct match exists, multi-card combinations are not allowed
- **Scopa**: capturing all table cards in one play earns a bonus point (not awarded on the final capture of a hand)
- **Re-deal rule**: if 3+ of the initial 4 table cards share a suit, the hand is re-dealt
- **Scoring**: Carte · Denari · Settebello (7♦) · Primiera · Scope
- **Primiera**: best per-suit card (7=21, 6=18, A=16, 5=15, 4=14, 3=13, 2=12, face=10); player missing any suit cannot win

---

## License

MIT © 2026 Francesco Forte
