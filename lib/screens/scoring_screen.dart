import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:scopa_flutter/core/theme.dart';
import 'package:scopa_flutter/models/card_model.dart';
import 'package:scopa_flutter/models/game_state.dart';
import 'package:scopa_flutter/models/player_model.dart';
import 'package:scopa_flutter/providers/game_provider.dart';
import 'package:scopa_flutter/widgets/card_widget.dart';

/// Displays the per-hand scoring breakdown and cumulative game scores.
class ScoringScreen extends ConsumerWidget {
  const ScoringScreen({super.key, required this.result});

  final HandScoringResult result;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0D1B2A), Color(0xFF0A2E1A)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── Title — always visible ────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: Column(
                  children: [
                    Text(
                      result.isGameOver ? 'GAME OVER' : 'FINE MANO',
                      style: kHeadingStyle.copyWith(fontSize: 26, letterSpacing: 4),
                    ).animate().fadeIn(duration: 400.ms),
                    const SizedBox(height: 8),
                    Divider(color: kGold.withAlpha(80)),
                    const SizedBox(height: 4),
                    _HeaderRow().animate(delay: 100.ms).fadeIn(duration: 300.ms),
                  ],
                ),
              ),

              // ── Score rows — scrollable on very small screens ─────────
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
                  child: Column(
                    children: _buildRows(result),
                  ),
                ),
              ),

              // ── Totals — always visible ───────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                child: Column(
                  children: [
                    Divider(color: kGold.withAlpha(80)),
                    const SizedBox(height: 4),
                    _TotalRow(
                      label: 'THIS HAND',
                      humanValue: result.humanHandTotal,
                      aiValue: result.aiHandTotal,
                    ).animate(delay: 620.ms).fadeIn(),
                    const SizedBox(height: 4),
                    _TotalRow(
                      label: 'GAME TOTAL',
                      humanValue: result.humanGameTotal,
                      aiValue: result.aiGameTotal,
                      highlight: true,
                    ).animate(delay: 700.ms).fadeIn(),
                    const SizedBox(height: 8),
                  ],
                ),
              ),

              // ── View captured cards — always visible ──────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                child: OutlinedButton.icon(
                  onPressed: () {
                    final state = ref.read(gameProvider);
                    _showCapturedCards(
                      context,
                      human: state.humanPlayer,
                      ai: state.aiPlayer,
                    );
                  },
                  icon: const Icon(Icons.style_outlined, size: 16),
                  label: const Text('VIEW CAPTURED CARDS'),
                ).animate(delay: 780.ms).fadeIn(),
              ),

              // ── Overtime / game-over banner — always visible ──────────
              if (result.isOvertime)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                  child: _OvertimeBanner(result: result)
                      .animate()
                      .scale(
                        begin: const Offset(0.9, 0.9),
                        duration: 350.ms,
                        curve: Curves.elasticOut,
                      )
                      .fadeIn(duration: 250.ms),
                ),
              if (result.isGameOver)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                  child: _GameOverBanner(result: result)
                      .animate()
                      .scale(
                        begin: const Offset(0.9, 0.9),
                        duration: 350.ms,
                        curve: Curves.elasticOut,
                      )
                      .fadeIn(duration: 250.ms),
                ),

              // ── Action button — always visible at bottom ──────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                child: SizedBox(
                  width: double.infinity,
                  child: result.isGameOver
                      ? ElevatedButton(
                          onPressed: () => context.go('/'),
                          child: const Text('BACK TO MENU'),
                        ).animate(delay: 900.ms).fadeIn()
                      : ElevatedButton(
                          onPressed: () {
                            ref.read(gameProvider.notifier).startNewHand();
                            context.go('/game');
                          },
                          child: const Text('NEXT HAND'),
                        ).animate(delay: 840.ms).fadeIn(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCapturedCards(
    BuildContext context, {
    required Player human,
    required Player ai,
  }) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: kBackgroundDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: kGold, width: 1),
      ),
      builder: (ctx) => _CapturedCardsSheet(human: human, ai: ai),
    );
  }

  List<Widget> _buildRows(HandScoringResult r) {
    final humanPrim = r.humanPrimieraScore >= 0 ? '${r.humanPrimieraScore}' : '—';
    final aiPrim = r.aiPrimieraScore >= 0 ? '${r.aiPrimieraScore}' : '—';

    return [
      _ScoreRow(
        label: 'CARTE',
        sublabel: 'Most cards',
        humanValue: r.humanCarte,
        aiValue: r.aiCarte,
        humanStat: '${r.humanCapturedCount} cards',
        aiStat: '${r.aiCapturedCount} cards',
        delay: 150,
      ),
      _ScoreRow(
        label: 'DENARI',
        sublabel: 'Most coins',
        humanValue: r.humanDenari,
        aiValue: r.aiDenari,
        humanStat: '${r.humanDenariCount} denari',
        aiStat: '${r.aiDenariCount} denari',
        delay: 250,
      ),
      _ScoreRow(
        label: 'SETTEBELLO',
        sublabel: '7 of Coins',
        humanValue: r.humanSettebello,
        aiValue: r.aiSettebello,
        delay: 350,
      ),
      _ScoreRow(
        label: 'PRIMIERA',
        sublabel: 'Best hand',
        humanValue: r.humanPrimiera,
        aiValue: r.aiPrimiera,
        humanStat: humanPrim,
        aiStat: aiPrim,
        delay: 450,
      ),
      _ScoreRow(
        label: 'SCOPE',
        sublabel: 'Table sweeps',
        humanValue: r.humanScope,
        aiValue: r.aiScope,
        delay: 550,
      ),
    ];
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _HeaderRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'YOU',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: kGold,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
              fontFamily: 'Cinzel',
            ),
          ),
        ),
        const SizedBox(width: 90),
        Expanded(
          child: Text(
            'CPU',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: kGold.withAlpha(180),
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
              fontFamily: 'Cinzel',
            ),
          ),
        ),
      ],
    );
  }
}

class _ScoreRow extends StatelessWidget {
  const _ScoreRow({
    required this.label,
    required this.sublabel,
    required this.humanValue,
    required this.aiValue,
    required this.delay,
    this.humanStat,
    this.aiStat,
  });

  final String label;
  final String sublabel;
  final int humanValue;
  final int aiValue;
  final int delay;

  /// Optional raw-count shown below the point score (e.g. "22 cards").
  final String? humanStat;
  final String? aiStat;

  @override
  Widget build(BuildContext context) {
    final humanWins = humanValue > aiValue;
    final aiWins = aiValue > humanValue;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          // Human score.
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: humanWins
                  ? BoxDecoration(
                      color: kGold.withAlpha(30),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: kGold.withAlpha(100)),
                    )
                  : null,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$humanValue',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: humanWins ? kGold : Colors.white54,
                    ),
                  ),
                  if (humanStat != null)
                    Text(
                      humanStat!,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 9, color: Colors.white38),
                    ),
                ],
              ),
            ),
          ),
          // Category label.
          SizedBox(
            width: 90,
            child: Column(
              children: [
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.white70,
                    letterSpacing: 1.5,
                    fontFamily: 'Cinzel',
                  ),
                ),
                Text(
                  sublabel,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 9, color: Colors.white38),
                ),
              ],
            ),
          ),
          // AI score.
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: aiWins
                  ? BoxDecoration(
                      color: Colors.red.withAlpha(25),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.red.withAlpha(80)),
                    )
                  : null,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$aiValue',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: aiWins ? Colors.redAccent : Colors.white54,
                    ),
                  ),
                  if (aiStat != null)
                    Text(
                      aiStat!,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 9, color: Colors.white38),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate(delay: delay.ms).fadeIn(duration: 300.ms).slideX(begin: -0.1, end: 0);
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({
    required this.label,
    required this.humanValue,
    required this.aiValue,
    this.highlight = false,
  });

  final String label;
  final int humanValue;
  final int aiValue;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            '$humanValue',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: highlight ? 28 : 18,
              fontWeight: FontWeight.bold,
              color: highlight ? kGold : Colors.white,
              fontFamily: highlight ? 'Cinzel' : null,
            ),
          ),
        ),
        SizedBox(
          width: 90,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 9,
              color: Colors.white54,
              letterSpacing: 1.5,
              fontFamily: 'Cinzel',
            ),
          ),
        ),
        Expanded(
          child: Text(
            '$aiValue',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: highlight ? 28 : 18,
              fontWeight: FontWeight.bold,
              color: highlight
                  ? kGold.withAlpha(180)
                  : Colors.white54,
              fontFamily: highlight ? 'Cinzel' : null,
            ),
          ),
        ),
      ],
    );
  }
}

class _OvertimeBanner extends StatelessWidget {
  const _OvertimeBanner({required this.result});

  final HandScoringResult result;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.amber.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber, width: 1.5),
      ),
      child: Column(
        children: [
          const Text(
            'PAREGGIO — SI CONTINUA!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.amber,
              fontFamily: 'Cinzel',
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Both players tied at ${result.humanGameTotal} — play another hand',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: Colors.white54),
          ),
        ],
      ),
    );
  }
}

class _GameOverBanner extends StatelessWidget {
  const _GameOverBanner({required this.result});

  final HandScoringResult result;

  @override
  Widget build(BuildContext context) {
    final humanWon = result.winner == 'human';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      decoration: BoxDecoration(
        color: humanWon ? kGold.withAlpha(30) : Colors.red.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: humanWon ? kGold : Colors.redAccent,
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Text(
            humanWon ? '🏆 YOU WIN!' : '💀 YOU LOSE',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: humanWon ? kGold : Colors.redAccent,
              fontFamily: 'Cinzel',
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${result.humanGameTotal} – ${result.aiGameTotal}',
            style: const TextStyle(fontSize: 16, color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

// ── Captured cards bottom sheet ───────────────────────────────────────────────

class _CapturedCardsSheet extends StatefulWidget {
  const _CapturedCardsSheet({required this.human, required this.ai});

  final Player human;
  final Player ai;

  @override
  State<_CapturedCardsSheet> createState() => _CapturedCardsSheetState();
}

class _CapturedCardsSheetState extends State<_CapturedCardsSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      constraints: BoxConstraints(maxHeight: screenHeight * 0.75),
      decoration: const BoxDecoration(
        color: kBackgroundDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar.
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: kGold.withAlpha(80),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Title.
          const Text(
            'CAPTURED CARDS',
            style: TextStyle(
              color: kGold,
              fontSize: 14,
              fontFamily: 'Cinzel',
              fontWeight: FontWeight.bold,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 12),

          // Tab bar.
          TabBar(
            controller: _tabs,
            indicatorColor: kGold,
            labelColor: kGold,
            unselectedLabelColor: Colors.white38,
            labelStyle: const TextStyle(
              fontFamily: 'Cinzel',
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
            tabs: [
              Tab(text: '${widget.human.name.toUpperCase()} (${widget.human.capturedCount})'),
              Tab(text: 'COMPUTER (${widget.ai.capturedCount})'),
            ],
          ),

          Divider(color: kGold.withAlpha(40), height: 1),

          // Card grids.
          Flexible(
            child: TabBarView(
              controller: _tabs,
              children: [
                _CardGrid(cards: widget.human.captured),
                _CardGrid(cards: widget.ai.captured),
              ],
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _CardGrid extends StatelessWidget {
  const _CardGrid({required this.cards});

  final List<ScopaCard> cards;

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'No cards captured',
            style: TextStyle(color: Colors.white38, fontSize: 14),
          ),
        ),
      );
    }

    // Sort: by suit then value for easy reading.
    final sorted = [...cards]
      ..sort((a, b) {
        final suitCmp = a.suit.index.compareTo(b.suit.index);
        return suitCmp != 0 ? suitCmp : a.value.compareTo(b.value);
      });

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 8,
        runSpacing: 10,
        alignment: WrapAlignment.center,
        children: sorted
            .map((card) => CardWidget(card: card, width: 56, height: 84))
            .toList(),
      ),
    );
  }
}
