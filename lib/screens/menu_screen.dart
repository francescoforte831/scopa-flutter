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

              // ── Play button ────────────────────────────────────────────
              ElevatedButton(
                onPressed: () {
                  ref
                      .read(gameProvider.notifier)
                      .startNewGame(difficulty: _selected);
                  context.go('/game');
                },
                child: const Text('PLAY VS COMPUTER'),
              )
                  .animate(delay: 800.ms)
                  .fadeIn(duration: 500.ms)
                  .slideY(begin: 0.4, end: 0, curve: Curves.easeOut),

              const SizedBox(height: 16),
              Text(
                'v2.0 · Stage 2',
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
