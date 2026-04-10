import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scopa_flutter/core/theme.dart';
import 'package:scopa_flutter/providers/game_provider.dart';

/// Top HUD bar showing real-time scope count, captured card count, and hand number.
class ScoreDisplayWidget extends ConsumerWidget {
  const ScoreDisplayWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameProvider);
    final human = state.humanPlayer;
    final ai = state.aiPlayer;

    return Container(
      color: Colors.black38,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Human stats.
          Expanded(
            child: _PlayerStats(
              name: human.name,
              capturedCount: human.capturedCount,
              scopeCount: human.scopeCount,
              gameScore: state.humanScore,
              alignLeft: true,
            ),
          ),
          // Hand counter in the centre.
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'HAND',
                style: TextStyle(
                  fontSize: 9,
                  color: kGold.withAlpha(180),
                  letterSpacing: 2,
                  fontFamily: 'Cinzel',
                ),
              ),
              Text(
                '${state.handNumber}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: kGold,
                  fontFamily: 'Cinzel',
                ),
              ),
            ],
          ),
          // AI stats.
          Expanded(
            child: _PlayerStats(
              name: ai.name,
              capturedCount: ai.capturedCount,
              scopeCount: ai.scopeCount,
              gameScore: state.aiScore,
              alignLeft: false,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayerStats extends StatelessWidget {
  const _PlayerStats({
    required this.name,
    required this.capturedCount,
    required this.scopeCount,
    required this.gameScore,
    required this.alignLeft,
  });

  final String name;
  final int capturedCount;
  final int scopeCount;
  final int gameScore;
  final bool alignLeft;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          alignLeft ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          name.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.white70,
            letterSpacing: 1.5,
            fontFamily: 'Cinzel',
          ),
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!alignLeft) ...[
              _Stat(icon: '🧹', value: scopeCount),
              const SizedBox(width: 8),
              _Stat(icon: '🃏', value: capturedCount),
              const SizedBox(width: 8),
              _GameScore(score: gameScore),
            ] else ...[
              _GameScore(score: gameScore),
              const SizedBox(width: 8),
              _Stat(icon: '🃏', value: capturedCount),
              const SizedBox(width: 8),
              _Stat(icon: '🧹', value: scopeCount),
            ],
          ],
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.value});

  final String icon;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(icon, style: const TextStyle(fontSize: 12)),
        const SizedBox(width: 2),
        Text(
          '$value',
          style: const TextStyle(
            fontSize: 13,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _GameScore extends StatelessWidget {
  const _GameScore({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: kGold.withAlpha(30),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: kGold.withAlpha(120), width: 1),
      ),
      child: Text(
        '$score',
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: kGold,
          fontFamily: 'Cinzel',
        ),
      ),
    );
  }
}
