import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:scopa_flutter/core/theme.dart';
import 'package:scopa_flutter/providers/game_provider.dart';

/// Main menu screen — the entry point of the app.
class MenuScreen extends ConsumerWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              // Top decorative divider.
              _GoldDivider(),
              const Spacer(flex: 2),

              // Title block.
              Column(
                children: [
                  Text('SCOPA', style: kTitleStyle)
                      .animate()
                      .fadeIn(duration: 800.ms)
                      .slideY(begin: -0.3, end: 0, duration: 600.ms, curve: Curves.easeOut),
                  const SizedBox(height: 8),
                  Text(
                    'IL GIOCO DI CARTE ITALIANO',
                    style: kSubtitleStyle,
                  )
                      .animate(delay: 300.ms)
                      .fadeIn(duration: 600.ms),
                ],
              ),

              const Spacer(flex: 2),

              // Decorative card icons.
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: ['⬡', '⚔', '♣', '🏆'].asMap().entries.map((e) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      e.value,
                      style: TextStyle(
                        fontSize: 28,
                        color: kGold.withAlpha(180),
                      ),
                    )
                        .animate(delay: (e.key * 100 + 500).ms)
                        .fadeIn(duration: 400.ms)
                        .scale(begin: const Offset(0.5, 0.5), curve: Curves.elasticOut),
                  );
                }).toList(),
              ),

              const Spacer(flex: 1),

              // Play button.
              ElevatedButton(
                onPressed: () {
                  ref.read(gameProvider.notifier).startNewGame();
                  context.go('/game');
                },
                child: const Text('PLAY VS COMPUTER'),
              )
                  .animate(delay: 700.ms)
                  .fadeIn(duration: 500.ms)
                  .slideY(begin: 0.4, end: 0, curve: Curves.easeOut),

              const SizedBox(height: 16),

              // Version / credits.
              Text(
                'v1.0 · Stage 1',
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
            child: Text('✦', style: TextStyle(color: kGold.withAlpha(150), fontSize: 12)),
          ),
          Expanded(child: Divider(color: kGold.withAlpha(80), thickness: 1)),
        ],
      ),
    );
  }
}
