import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:scopa_flutter/core/theme.dart';
import 'package:scopa_flutter/models/card_model.dart';
import 'package:scopa_flutter/models/game_state.dart';
import 'package:scopa_flutter/providers/game_provider.dart';
import 'package:scopa_flutter/widgets/ai_hand_widget.dart';
import 'package:scopa_flutter/widgets/hand_widget.dart';
import 'package:scopa_flutter/widgets/score_display_widget.dart';
import 'package:scopa_flutter/widgets/table_area_widget.dart';

/// Primary game screen — table, cards, HUD, and animation orchestration.
class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  // Key to call methods on HandWidget from TableAreaWidget.
  final GlobalKey<HandWidgetState> _handKey = GlobalKey<HandWidgetState>();

  // Scopa overlay visibility.
  bool _showScopaOverlay = false;
  String _scopaActorName = '';

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // Side-effect listeners — run outside build to avoid rebuild loops.
    ref.listen<GamePhase>(
      gameProvider.select((s) => s.phase),
      _onPhaseChanged,
    );

    ref.listen<LastAction?>(
      gameProvider.select((s) => s.lastAction),
      _onLastActionChanged,
    );

    final isPlayerTurn = ref.watch(gameProvider.select((s) => s.isPlayerTurn));

    return Scaffold(
      backgroundColor: kTableGreen,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // ── HUD ──────────────────────────────────────────────────
                const ScoreDisplayWidget(),

                // ── AI hand ───────────────────────────────────────────────
                const AiHandWidget(),

                // ── Table ─────────────────────────────────────────────────
                Expanded(
                  child: TableAreaWidget(
                    onCardPlayed: _onCardPlayed,
                    getSelectedCard: () => _handKey.currentState?.selectedCard,
                  ),
                ),

                // ── Player turn indicator ─────────────────────────────────
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 28,
                  color: isPlayerTurn
                      ? kGold.withAlpha(30)
                      : Colors.transparent,
                  alignment: Alignment.center,
                  child: isPlayerTurn
                      ? const Text(
                          'YOUR TURN — drag or tap a card',
                          style: TextStyle(
                            fontSize: 11,
                            color: kGold,
                            letterSpacing: 1.5,
                            fontFamily: 'Cinzel',
                          ),
                        )
                      : const Text(
                          'Computer is thinking…',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white38,
                            letterSpacing: 1,
                          ),
                        ),
                ),

                // ── Human hand ────────────────────────────────────────────
                HandWidget(
                  key: _handKey,
                  onCardPlayed: _onCardPlayed,
                ),
              ],
            ),

            // ── Scopa overlay ────────────────────────────────────────────
            if (_showScopaOverlay) _ScopaOverlay(actorName: _scopaActorName),
          ],
        ),
      ),
    );
  }

  // ── Callbacks ─────────────────────────────────────────────────────────────

  void _onCardPlayed(ScopaCard card, List<ScopaCard> captureTarget) {
    if (!ref.read(gameProvider).isPlayerTurn) return;
    ref.read(gameProvider.notifier).humanPlayCard(card, captureTarget);
    _handKey.currentState?.clearSelection();
  }

  void _onPhaseChanged(GamePhase? prev, GamePhase next) {
    if (next == GamePhase.aiTurn) {
      ref.read(gameProvider.notifier).resolveAiTurn();
    } else if (next == GamePhase.handOver || next == GamePhase.gameOver) {
      _navigateToScoring();
    }
  }

  void _onLastActionChanged(LastAction? prev, LastAction? next) {
    if (next == null) return;
    if (next.wasScopa) {
      final actor = next.actorId == 'human'
          ? ref.read(gameProvider).humanPlayer.name
          : ref.read(gameProvider).aiPlayer.name;
      _triggerScopaAnimation(actor);
    }
    // Clear lastAction after a short delay to allow animations to run.
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) ref.read(gameProvider.notifier).clearLastAction();
    });
  }

  void _triggerScopaAnimation(String actorName) {
    setState(() {
      _showScopaOverlay = true;
      _scopaActorName = actorName;
    });
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) setState(() => _showScopaOverlay = false);
    });
  }

  void _navigateToScoring() {
    // Slight delay so the last card animation can finish.
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      final result = ref.read(gameProvider.notifier).acknowledgeHandEnd();
      context.go('/scoring', extra: result);
    });
  }
}

// ── Scopa overlay ─────────────────────────────────────────────────────────────

class _ScopaOverlay extends StatelessWidget {
  const _ScopaOverlay({required this.actorName});

  final String actorName;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Gold flash.
            Container(color: kGold.withAlpha(0))
                .animate()
                .custom(
                  duration: 200.ms,
                  builder: (ctx, value, child) =>
                      Container(color: kGold.withAlpha((value * 50).round())),
                )
                .then()
                .custom(
                  duration: 700.ms,
                  builder: (ctx, value, child) =>
                      Container(color: kGold.withAlpha(((1 - value) * 50).round())),
                ),
            // SCOPA! text.
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'SCOPA!',
                  style: kScopaTextStyle,
                )
                    .animate()
                    .scale(
                      begin: const Offset(0.4, 0.4),
                      end: const Offset(1.15, 1.15),
                      duration: 300.ms,
                      curve: Curves.elasticOut,
                    )
                    .fadeIn(duration: 200.ms),
                const SizedBox(height: 8),
                Text(
                  actorName.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    letterSpacing: 3,
                    fontFamily: 'Cinzel',
                  ),
                ).animate(delay: 200.ms).fadeIn(),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
