import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scopa_flutter/models/card_model.dart';
import 'package:scopa_flutter/providers/game_provider.dart';
import 'package:scopa_flutter/widgets/card_widget.dart';

/// Displays the AI's hand as a row of face-down cards.
class AiHandWidget extends ConsumerStatefulWidget {
  const AiHandWidget({super.key, this.hiddenCount = 0});

  /// Number of cards to hide immediately (used while the fly animation plays).
  final int hiddenCount;

  @override
  ConsumerState<AiHandWidget> createState() => AiHandWidgetState();
}

class AiHandWidgetState extends ConsumerState<AiHandWidget> {
  final _rowKey = GlobalKey();

  /// The card size used for AI hand cards.
  Size get cardSize => const Size(52, 78);

  /// Global top-left offset of the centre of the AI hand row.
  Offset? get handCenterGlobal {
    final box = _rowKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return null;
    final origin = box.localToGlobal(Offset.zero);
    return origin + Offset(box.size.width / 2, box.size.height / 2);
  }

  @override
  Widget build(BuildContext context) {
    final aiHand = ref.watch(
      gameProvider.select((s) => s.aiPlayer.hand),
    );

    final visibleCount =
        (aiHand.length - widget.hiddenCount).clamp(0, aiHand.length);

    if (visibleCount == 0) {
      return const SizedBox(height: 70);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        key: _rowKey,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: aiHand.take(visibleCount).toList()
            .asMap()
            .entries
            .map(
              (e) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: CardWidget(
                  card: const ScopaCard(suit: Suit.coppe, value: 1),
                  faceDown: true,
                  width: cardSize.width,
                  height: cardSize.height,
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
