import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:scopa_flutter/core/constants.dart';
import 'package:scopa_flutter/models/card_model.dart';
import 'package:scopa_flutter/providers/game_provider.dart';
import 'package:scopa_flutter/widgets/card_widget.dart';

/// Displays the human player's hand with draggable and tappable cards.
///
/// Cards can be played by:
///   1. Dragging onto the [TableAreaWidget] drop zone.
///   2. Tapping a card to select it, then tapping a table card.
class HandWidget extends ConsumerStatefulWidget {
  const HandWidget({
    super.key,
    required this.onCardPlayed,
  });

  /// Called when the player plays a card (with an optional capture target).
  /// An empty [captureTarget] means discard.
  final void Function(ScopaCard card, List<ScopaCard> captureTarget) onCardPlayed;

  @override
  ConsumerState<HandWidget> createState() => HandWidgetState();
}

class HandWidgetState extends ConsumerState<HandWidget> {
  ScopaCard? _selectedCard;

  @override
  Widget build(BuildContext context) {
    final hand = ref.watch(gameProvider.select((s) => s.humanPlayer.hand));
    final isPlayerTurn = ref.watch(gameProvider.select((s) => s.isPlayerTurn));

    if (hand.isEmpty) {
      return const SizedBox(height: 90);
    }

    return Container(
      color: Colors.black26,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: hand.asMap().entries.map((entry) {
          final index = entry.key;
          final card = entry.value;
          final isSelected = _selectedCard == card;

          return _buildDraggableCard(
            card: card,
            index: index,
            isSelected: isSelected,
            isEnabled: isPlayerTurn,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDraggableCard({
    required ScopaCard card,
    required int index,
    required bool isSelected,
    required bool isEnabled,
  }) {
    final cardWidget = CardWidget(
      key: ValueKey(card),
      card: card,
      isSelected: isSelected,
    );

    final animated = cardWidget
        .animate(delay: kDealStaggerDelay * index)
        .slideY(begin: 1.2, end: 0, duration: 300.ms, curve: Curves.easeOut)
        .fadeIn(duration: 200.ms);

    if (!isEnabled) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: animated,
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: GestureDetector(
        onTap: () => _onCardTapped(card),
        child: Draggable<ScopaCard>(
          data: card,
          feedback: DraggingCardWidget(card: card),
          childWhenDragging: CardWidget(
            card: card,
            isDragging: true,
          ),
          onDragStarted: () {
            setState(() => _selectedCard = card);
          },
          onDraggableCanceled: (_, offset) {
            setState(() => _selectedCard = null);
          },
          child: animated,
        ),
      ),
    );
  }

  void _onCardTapped(ScopaCard card) {
    if (_selectedCard == card) {
      // Deselect.
      setState(() => _selectedCard = null);
    } else {
      setState(() => _selectedCard = card);
    }
  }

  /// Called by [TableAreaWidget] when a card is tapped while one is selected.
  void playSelectedCard(List<ScopaCard> captureTarget) {
    if (_selectedCard == null) return;
    final card = _selectedCard!;
    setState(() => _selectedCard = null);
    widget.onCardPlayed(card, captureTarget);
  }

  ScopaCard? get selectedCard => _selectedCard;

  void clearSelection() {
    setState(() => _selectedCard = null);
  }
}
