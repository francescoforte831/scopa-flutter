import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:scopa_flutter/core/theme.dart';
import 'package:scopa_flutter/models/game_state.dart';
import 'package:scopa_flutter/providers/game_provider.dart';

/// Main menu screen — difficulty selector + play button.
class MenuScreen extends ConsumerStatefulWidget {
  const MenuScreen({super.key});

  @override
  ConsumerState<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends ConsumerState<MenuScreen> {
  Difficulty _selected = Difficulty.medium;
  int _winningScore = 11;

  void _showHowToPlay(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF0D1B2A),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: kGold, width: 1),
      ),
      builder: (_) => const _HowToPlaySheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0D1B2A), Color(0xFF0A2E1A), Color(0xFF0D1B2A)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _GoldDivider(),
              const Spacer(flex: 2),

              // ── Title ─────────────────────────────────────────────────
              Column(
                children: [
                  Text('SCOPA', style: kTitleStyle)
                      .animate()
                      .fadeIn(duration: 800.ms)
                      .slideY(
                        begin: -0.3,
                        end: 0,
                        duration: 600.ms,
                        curve: Curves.easeOut,
                      ),
                  const SizedBox(height: 8),
                  Text('IL GIOCO DI CARTE ITALIANO', style: kSubtitleStyle)
                      .animate(delay: 300.ms)
                      .fadeIn(duration: 600.ms),
                ],
              ),

              const Spacer(flex: 1),

              // ── Suit icons ─────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  'assets/images/ui/title_screen_Asso_di_denari.png',
                  'assets/images/ui/title_screen_Asso_di_coppe.png',
                  'assets/images/ui/title_screen_Asso_di_spade.png',
                  'assets/images/ui/title_screen_Asso_di_bastoni.png',
                ].asMap().entries.map((e) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Image.asset(
                      e.value,
                      width: 64,
                      height: 64,
                      fit: BoxFit.contain,
                    )
                        .animate(delay: (e.key * 100 + 500).ms)
                        .fadeIn(duration: 400.ms)
                        .scale(
                          begin: const Offset(0.5, 0.5),
                          curve: Curves.elasticOut,
                        ),
                  );
                }).toList(),
              ),

              const Spacer(flex: 1),

              // ── Difficulty selector ────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    Text(
                      'DIFFICULTY',
                      style: TextStyle(
                        fontSize: 11,
                        color: kGold.withAlpha(180),
                        letterSpacing: 3,
                        fontFamily: 'Cinzel',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: Difficulty.values.map((d) {
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: _DifficultyButton(
                              difficulty: d,
                              isSelected: _selected == d,
                              onTap: () => setState(() => _selected = d),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 8),
                    // Description of selected difficulty.
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Text(
                        _selected.description,
                        key: ValueKey(_selected),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withAlpha(120),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              )
                  .animate(delay: 600.ms)
                  .fadeIn(duration: 500.ms)
                  .slideY(begin: 0.3, end: 0, curve: Curves.easeOut),

              const Spacer(flex: 1),

              // ── Points to win selector ─────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    Text(
                      'POINTS TO WIN',
                      style: TextStyle(
                        fontSize: 11,
                        color: kGold.withAlpha(180),
                        letterSpacing: 3,
                        fontFamily: 'Cinzel',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [1, 11, 16, 21].map((pts) {
                        final isSelected = _winningScore == pts;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: GestureDetector(
                              onTap: () => setState(() => _winningScore = pts),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? kGold.withAlpha(40)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSelected
                                        ? kGold
                                        : kGold.withAlpha(80),
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: Text(
                                  '$pts',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected
                                        ? kGold
                                        : kGold.withAlpha(160),
                                    fontFamily: 'Cinzel',
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              )
                  .animate(delay: 700.ms)
                  .fadeIn(duration: 500.ms)
                  .slideY(begin: 0.3, end: 0, curve: Curves.easeOut),

              const Spacer(flex: 1),

              // ── Play button ────────────────────────────────────────────
              ElevatedButton(
                onPressed: () {
                  ref.read(gameProvider.notifier).startNewGame(
                        difficulty: _selected,
                        winningScore: _winningScore,
                      );
                  context.go('/game');
                },
                child: const Text('PLAY VS COMPUTER'),
              )
                  .animate(delay: 800.ms)
                  .fadeIn(duration: 500.ms)
                  .slideY(begin: 0.4, end: 0, curve: Curves.easeOut),

              const SizedBox(height: 12),
              TextButton(
                onPressed: () => _showHowToPlay(context),
                child: Text(
                  'HOW TO PLAY',
                  style: TextStyle(
                    fontSize: 12,
                    color: kGold.withAlpha(180),
                    letterSpacing: 2,
                    fontFamily: 'Cinzel',
                  ),
                ),
              ).animate(delay: 900.ms).fadeIn(),

              const SizedBox(height: 8),
              Text(
                'v1.0 · Beta',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withAlpha(60),
                  letterSpacing: 1,
                ),
              ).animate(delay: 1000.ms).fadeIn(),

              const Spacer(flex: 1),
              _GoldDivider(),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Difficulty button ─────────────────────────────────────────────────────────

class _DifficultyButton extends StatelessWidget {
  const _DifficultyButton({
    required this.difficulty,
    required this.isSelected,
    required this.onTap,
  });

  final Difficulty difficulty;
  final bool isSelected;
  final VoidCallback onTap;

  Color get _color {
    switch (difficulty) {
      case Difficulty.easy:   return const Color(0xFF4CAF50); // green
      case Difficulty.medium: return kGold;
      case Difficulty.hard:   return const Color(0xFFEF5350); // red
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? _color.withAlpha(40) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? _color : _color.withAlpha(80),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              difficulty.label.toUpperCase(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isSelected ? _color : _color.withAlpha(160),
                letterSpacing: 1.5,
                fontFamily: 'Cinzel',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Decorative divider ────────────────────────────────────────────────────────

class _GoldDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 4),
      child: Row(
        children: [
          Expanded(child: Divider(color: kGold.withAlpha(80), thickness: 1)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              '✦',
              style: TextStyle(color: kGold.withAlpha(150), fontSize: 12),
            ),
          ),
          Expanded(child: Divider(color: kGold.withAlpha(80), thickness: 1)),
        ],
      ),
    );
  }
}

// ── How to play sheet ─────────────────────────────────────────────────────────

class _HowToPlaySheet extends StatelessWidget {
  const _HowToPlaySheet();

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      constraints: BoxConstraints(maxHeight: screenHeight * 0.88),
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: kGold.withAlpha(80),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'COME SI GIOCA',
            style: TextStyle(
              color: kGold,
              fontSize: 16,
              fontFamily: 'Cinzel',
              fontWeight: FontWeight.bold,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'How to Play Scopa',
            style: TextStyle(fontSize: 12, color: Colors.white.withAlpha(120)),
          ),
          const SizedBox(height: 16),
          Divider(color: kGold.withAlpha(60)),
          const SizedBox(height: 8),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  _RuleSection(
                    title: 'THE DECK',
                    body: '40 cards in 4 suits — Coins (Denari), Cups (Coppe), Swords (Spade), Clubs (Bastoni). Cards run 1 (Asso) to 10 (Re).',
                  ),
                  _RuleSection(
                    title: 'GOAL',
                    body: 'Score more points than your opponent by capturing cards from the table. The first player to reach the target score wins.',
                  ),
                  _RuleSection(
                    title: 'YOUR TURN',
                    body: 'Play one card from your hand each turn. You can capture a table card of equal value, or a group of table cards that sum to your card\'s value.',
                  ),
                  _RuleSection(
                    title: 'SINGLE-CARD PRIORITY',
                    body: 'If a direct match exists (one table card equals yours), you must take it — you cannot use a multi-card sum instead.',
                  ),
                  _RuleSection(
                    title: 'SCOPA',
                    body: 'If your capture clears every card from the table, you earn a bonus Scopa point. The final capture of a hand does not score a Scopa.',
                  ),
                  _RuleSection(
                    title: 'END OF HAND',
                    body: 'When all cards are played, the player who made the last capture takes any remaining table cards. Hands alternate who goes first.',
                  ),
                  _RuleDivider(),
                  _RuleSection(
                    title: 'SCORING',
                    body: '',
                  ),
                  _ScoreItem(
                    name: 'Carte',
                    desc: '1 point to whoever captured the most cards.',
                  ),
                  _ScoreItem(
                    name: 'Denari',
                    desc: '1 point for capturing the most Coins cards.',
                  ),
                  _ScoreItem(
                    name: 'Settebello',
                    desc: '1 point for capturing the 7 of Coins.',
                  ),
                  _ScoreItem(
                    name: 'Primiera',
                    desc: '1 point for the best hand — one card per suit, scored as: 7=21, 6=18, A=16, 5=15, 4=14, 3=13, 2=12, face=10. Missing a suit disqualifies you.',
                  ),
                  _ScoreItem(
                    name: 'Scope',
                    desc: '1 point per Scopa earned during the hand.',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RuleSection extends StatelessWidget {
  const _RuleSection({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: kGold,
              fontSize: 11,
              fontFamily: 'Cinzel',
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          if (body.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              body,
              style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
            ),
          ],
        ],
      ),
    );
  }
}

class _ScoreItem extends StatelessWidget {
  const _ScoreItem({required this.name, required this.desc});

  final String name;
  final String desc;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• $name  ',
            style: const TextStyle(
              color: kGold,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              height: 1.5,
            ),
          ),
          Expanded(
            child: Text(
              desc,
              style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _RuleDivider extends StatelessWidget {
  const _RuleDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Divider(color: kGold.withAlpha(40)),
    );
  }
}
