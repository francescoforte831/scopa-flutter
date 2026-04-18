import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scopa_flutter/core/constants.dart';
import 'package:scopa_flutter/models/card_model.dart';
import 'package:scopa_flutter/providers/game_provider.dart';
import 'package:scopa_flutter/widgets/card_widget.dart';

/// Displays the human player's hand with draggable and tappable cards.
class HandWidget extends ConsumerStatefulWidget {
  const HandWidget({
    super.key,
    required this.onCardPlayed,
    required this.onCardTapped,
    this.ghostCard,
  });

  final void Function(ScopaCard card, List<ScopaCard> captureTarget) onCardPlayed;
  final void Function(ScopaCard card) onCardTapped;

  /// Card currently mid-flight — rendered as a faint ghost instead of solid.
  final ScopaCard? ghostCard;

  @override
  ConsumerState<HandWidget> createState() => HandWidgetState();
}

class HandWidgetState extends ConsumerState<HandWidget> {
  final Map<ScopaCard, GlobalKey> _cardKeys = {};

  /// Cards that have already slid in — they don't repeat the entrance animation.
  final Set<ScopaCard> _seenCards = {};
  int? _lastHandNumber;

  /// Returns the top-left global position of [card]'s widget, or null if
  /// the card's key is not currently in the tree.
  Offset? cardGlobalOffset(ScopaCard card) {
    final box =
        _cardKeys[card]?.currentContext?.findRenderObject() as RenderBox?;
    return box?.localToGlobal(Offset.zero);
  }

  /// The rendered size of each card in this widget.
  Size get cardSize => const Size(68, 102);

  @override
  Widget build(BuildContext context) {
    final hand = ref.watch(gameProvider.select((s) => s.humanPlayer.hand));
    final isPlayerTurn = ref.watch(gameProvider.select((s) => s.isPlayerTurn));
    final handNumber = ref.watch(gameProvider.select((s) => s.handNumber));

    // Clear animation tracking between hands so new cards slide in fresh.
    if (handNumber != _lastHandNumber) {
      _seenCards.clear();
      _lastHandNumber = handNumber;
    }

    if (hand.isEmpty) return const SizedBox(height: 90);

    return Container(
      color: Colors.black26,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: hand.asMap().entries.map((entry) {
          final index = entry.key;
          final card = entry.value;
          final key = _cardKeys.putIfAbsent(card, GlobalKey.new);
          final isGhost = card == widget.ghostCard;
          final isNew = _seenCards.add(card); // true only on first appearance

          final baseCard = CardWidget(key: key, card: card);
          final animated = isNew
              ? baseCard
                  .animate(delay: kDealStaggerDelay * index)
                  .slideY(
                      begin: 1.2, end: 0, duration: 300.ms, curve: Curves.easeOut)
                  .fadeIn(duration: 200.ms)
              : baseCard;

          final cardWidget = Opacity(
            opacity: isGhost ? 0.25 : 1.0,
            child: animated,
          );

          if (!isPlayerTurn || isGhost) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: cardWidget,
            );
          }

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: GestureDetector(
              onTap: () => widget.onCardTapped(card),
              child: Draggable<ScopaCard>(
                data: card,
                feedback: DraggingCardWidget(card: card),
                childWhenDragging: CardWidget(card: card, isDragging: true),
                child: cardWidget,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
