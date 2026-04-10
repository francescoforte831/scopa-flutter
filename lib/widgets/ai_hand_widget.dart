import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scopa_flutter/models/card_model.dart';
import 'package:scopa_flutter/providers/game_provider.dart';
import 'package:scopa_flutter/widgets/card_widget.dart';

/// Displays the AI's hand as a row of face-down cards.
class AiHandWidget extends ConsumerWidget {
  const AiHandWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aiHand = ref.watch(
      gameProvider.select((s) => s.aiPlayer.hand),
    );

    if (aiHand.isEmpty) {
      return const SizedBox(height: 70);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: aiHand
            .asMap()
            .entries
            .map(
              (e) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: CardWidget(
                  // Use a dummy card for face-down rendering.
                  card: const ScopaCard(suit: Suit.coppe, value: 1),
                  faceDown: true,
                  width: 52,
                  height: 78,
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
