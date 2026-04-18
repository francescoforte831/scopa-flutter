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
- **Drag-and-drop card play** — drag from hand to table, or tap a hand card to play it immediately (no second tap required)
- **Multi-capture selection** — scrollable bottom sheet picker when multiple valid captures exist; auto-applies when only one is valid
- **Auto-discard** — playing a card with no valid captures discards it immediately, no confirmation dialog
- **Full end-of-hand scoring** — Carte, Denari, Settebello, Primiera, Scope with per-category breakdown
- **Cumulative game scoring** — first to 11 points wins; game-over screen with final result
- **View captured cards** — tap the button on the scoring screen to browse each player's captured pile in a tabbed sheet
- **Premium Italian UI** — deep green felt table, gold accents, Cinzel font (Google Fonts), dark navy menu
- **Card images** — supports authentic Piacentine PNGs in `assets/images/cards/`; falls back gracefully to code-rendered card faces

### Stage 2 — Difficulty Levels ✅
- **Easy** — greedy AI: captures when possible (random choice), otherwise discards a random card
- **Medium** — traditional Italian strategy (Stage 1 AI, now the default)
- **Hard** — minimax with depth-3 lookahead; evaluates score delta, denari advantage, settebello control, and scopa blocking
- **Difficulty badge** in the HUD so you always know what you're up against
- **Animated difficulty selector** on the menu with colour-coded buttons (green / gold / red)
- **QUIT button** in the HUD centre with confirmation dialog — exit at any point without losing your way back to the menu

### Card Animations ✅
- **Tap-to-play fly** — tapping a hand card dims it to a ghost and launches a flying copy toward the table edge (700 ms, scale-pulse arc); ghost clears when the card lands
- **AI card reveal** — when the computer plays, a full-size face-up card flies from the AI hand area to the top edge of the table, pauses for 1.2 s so the move is readable, then resolves
- **Stable table positions** — each card is assigned a fixed slot when it lands; existing cards never shift or reflow when a new card is added or removed; slight random offset (±6 px) and rotation (±1.7°) give a natural "placed on felt" look
- **Edge approach** — played cards float to the near edge of the table (bottom for human, top for AI) rather than the centre, so they never obscure cards already on the table
- **Capture glow** — before sweeping to the pile, all involved cards (played + captured) pulse with a golden glow and scale up to 1.15× over 500 ms
- **Simultaneous capture sweep** — after the glow, every card flies in parallel from its own position directly to the capturing player's pile (700 ms easeIn); no gather-at-centre phase
- **End-of-round sweep** — remaining table cards glow and sweep to the last captor's pile before the scoring screen appears
- **AI hand count** — the face-down card row shrinks the moment the AI's fly animation begins (not only after state commits)
- **Entrance animation once** — newly dealt cards fade + scale in; cards already present do not re-animate after each turn

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
| Animations | flutter_animate 4.x + AnimationController for flying cards |
| Fonts | Google Fonts — Cinzel |
| Multiplayer (Stage 4) | Firebase Firestore + Anonymous Auth |
| AI (Stage 2+) | Minimax depth-3 with heuristic evaluation |

---

## Project Structure

```
lib/
├── main.dart                    # App entry, ProviderScope, orientation lock
├── core/
│   ├── constants.dart           # Game constants, primiera values, animation durations
│   ├── theme.dart               # ScopaTheme — colours, typography, button styles
│   └── router.dart              # GoRouter: /, /game, /scoring
├── models/
│   ├── card_model.dart          # ScopaCard (40-card Italian deck)
│   ├── player_model.dart        # Player (hand, captured, scopeCount)
│   └── game_state.dart          # GameState, GamePhase, Difficulty, LastAction, HandScoringResult
├── providers/
│   ├── game_provider.dart       # GameNotifier — all state transitions + peekAiPlay/applyAiTurn
│   └── providers.dart           # Service provider registrations
├── services/
│   ├── deck_service.dart        # Deck creation and shuffle
│   ├── game_service.dart        # Pure rule functions (captures, scopa, scoring)
│   └── ai_service.dart          # Easy / Medium / Hard AI (minimax depth-3 for Hard)
├── screens/
│   ├── menu_screen.dart         # Animated main menu with difficulty selector
│   ├── game_screen.dart         # Game table, HUD, flying-card animation orchestration
│   └── scoring_screen.dart      # Per-hand breakdown + cumulative scores + captured cards viewer
└── widgets/
    ├── card_widget.dart          # Face-up (image + ColoredCardFace fallback) / face-down
    ├── table_area_widget.dart    # DragTarget, capture picker, table display, card position lookup
    ├── hand_widget.dart          # Draggable player hand, card position lookup, ghost-card support
    ├── ai_hand_widget.dart       # Face-down AI cards with hiddenCount for live animation sync
    └── score_display_widget.dart # Real-time HUD (scope, cards, game score, difficulty badge, quit)
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
