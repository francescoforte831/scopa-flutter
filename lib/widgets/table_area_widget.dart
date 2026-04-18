import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scopa_flutter/core/theme.dart';
import 'package:scopa_flutter/models/card_model.dart';
import 'package:scopa_flutter/providers/game_provider.dart';
import 'package:scopa_flutter/services/game_service.dart';
import 'package:scopa_flutter/widgets/card_widget.dart';

/// The green felt table centre — shows table cards and accepts card drops.
class TableAreaWidget extends ConsumerStatefulWidget {
  const TableAreaWidget({
    super.key,
    required this.onCardPlayed,
  });

  final void Function(ScopaCard card, List<ScopaCard> captureTarget) onCardPlayed;

  @override
  ConsumerState<TableAreaWidget> createState() => TableAreaWidgetState();
}

class TableAreaWidgetState extends ConsumerState<TableAreaWidget> {
  final Map<ScopaCard, GlobalKey> _cardKeys = {};
  final _containerKey = GlobalKey();
  final Set<ScopaCard> _seenCards = {};
  int? _lastHandNumber;

  // ── Stable slot positioning ──────────────────────────────────────────────
  final Map<ScopaCard, int> _cardSlots = {};
  final List<int> _freedSlots = [];
  int _nextSlot = 0;
  final Map<int, double> _slotJitterX = {};
  final Map<int, double> _slotJitterY = {};
  final Map<int, double> _slotRotation = {};
  final _rng = Random();

  int _assignSlot(ScopaCard card) {
    if (_cardSlots.containsKey(card)) return _cardSlots[card]!;
    final slot = _freedSlots.isNotEmpty ? _freedSlots.removeAt(0) : _nextSlot++;
    _cardSlots[card] = slot;
    _slotJitterX.putIfAbsent(slot, () => (_rng.nextDouble() - 0.5) * 12);
    _slotJitterY.putIfAbsent(slot, () => (_rng.nextDouble() - 0.5) * 8);
    _slotRotation.putIfAbsent(slot, () => (_rng.nextDouble() - 0.5) * 0.06);
    return slot;
  }

  void _cleanupSlots(List<ScopaCard> currentCards) {
    final toRemove = <ScopaCard>[];
    for (final card in _cardSlots.keys) {
      if (!currentCards.contains(card)) toRemove.add(card);
    }
    for (final card in toRemove) {
      final slot = _cardSlots.remove(card)!;
      _freedSlots.add(slot);
      _cardKeys.remove(card);
    }
    _freedSlots.sort();
  }

  /// Top-left global offset of [card]'s widget on the table, or null.
  Offset? cardGlobalOffset(ScopaCard card) {
    final box =
        _cardKeys[card]?.currentContext?.findRenderObject() as RenderBox?;
    return box?.localToGlobal(Offset.zero);
  }

  /// Global [Rect] of the table container widget, or null if not yet laid out.
  Rect? get containerBounds {
    final box =
        _containerKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  /// Global centre of the table area container.
  Offset? get tableCenterGlobal {
    final box =
        _containerKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return null;
    final origin = box.localToGlobal(Offset.zero);
    return origin + Offset(box.size.width / 2, box.size.height / 2);
  }

  /// The standard card size rendered on the table.
  Size get cardSize => const Size(68, 102);

  @override
  Widget build(BuildContext context) {
    final tableCards = ref.watch(gameProvider.select((s) => s.tableCards));
    final handNumber = ref.watch(gameProvider.select((s) => s.handNumber));

    if (handNumber != _lastHandNumber) {
      _seenCards.clear();
      _cardKeys.clear();
      _cardSlots.clear();
      _freedSlots.clear();
      _nextSlot = 0;
      _slotJitterX.clear();
      _slotJitterY.clear();
      _slotRotation.clear();
      _lastHandNumber = handNumber;
    }

    _cleanupSlots(tableCards);
    for (final card in tableCards) {
      _assignSlot(card);
    }

    return DragTarget<ScopaCard>(
      onWillAcceptWithDetails: (_) => true,
      onAcceptWithDetails: (details) {
        _handleCardPlayed(details.data, tableCards, context);
      },
      builder: (context, candidateData, rejectedData) {
        final hovering = candidateData.isNotEmpty;
        return AnimatedContainer(
          key: _containerKey,
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: hovering ? kTableGreenLight : kTableGreen,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: hovering ? kGold : kGold.withAlpha(100),
              width: hovering ? 2.5 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(80),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              if (tableCards.isEmpty)
                const Center(
                  child: Text(
                    'SCOPA!',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white24,
                      letterSpacing: 4,
                      fontFamily: 'Cinzel',
                    ),
                  ),
                ),

              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      const cardW = 68.0;
                      const cardH = 102.0;
                      const spacingX = 14.0;
                      const spacingY = 14.0;

                      final maxCols = ((constraints.maxWidth + spacingX) /
                              (cardW + spacingX))
                          .floor()
                          .clamp(1, 10);

                      int maxSlotUsed = 0;
                      for (final card in tableCards) {
                        final s = _cardSlots[card] ?? 0;
                        if (s > maxSlotUsed) maxSlotUsed = s;
                      }
                      final totalRows =
                          tableCards.isEmpty ? 0 : (maxSlotUsed ~/ maxCols) + 1;

                      final gridW =
                          maxCols * cardW + (maxCols - 1) * spacingX;
                      final gridH = totalRows * cardH +
                          (totalRows > 1 ? (totalRows - 1) * spacingY : 0);
                      final ox = (constraints.maxWidth - gridW) / 2;
                      final oy = max(
                          0.0, (constraints.maxHeight - gridH) / 2);

                      var newCardIndex = 0;
                      return Stack(
                        clipBehavior: Clip.none,
                        children: tableCards.map((card) {
                          final slot = _cardSlots[card]!;
                          final col = slot % maxCols;
                          final row = slot ~/ maxCols;
                          final key =
                              _cardKeys.putIfAbsent(card, GlobalKey.new);
                          final isNew = _seenCards.add(card);

                          final x = ox +
                              col * (cardW + spacingX) +
                              _slotJitterX[slot]!;
                          final y = oy +
                              row * (cardH + spacingY) +
                              _slotJitterY[slot]!;

                          final rotatedCard = Transform.rotate(
                            angle: _slotRotation[slot]!,
                            child: CardWidget(card: card),
                          );

                          final delayIdx = isNew ? newCardIndex++ : 0;

                          return Positioned(
                            left: x,
                            top: y,
                            width: cardW,
                            height: cardH,
                            child: SizedBox.expand(
                              key: key,
                              child: isNew
                                  ? rotatedCard
                                      .animate(
                                          delay: (delayIdx * 80).ms)
                                      .fadeIn(duration: 250.ms)
                                      .scale(
                                        begin: const Offset(0.7, 0.7),
                                        end: const Offset(1.0, 1.0),
                                        duration: 250.ms,
                                        curve: Curves.easeOut,
                                      )
                                  : rotatedCard,
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ),
              ),

              if (hovering)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: kGold.withAlpha(20),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _handleCardPlayed(
    ScopaCard card,
    List<ScopaCard> tableCards,
    BuildContext context,
  ) {
    final captures = const GameService().findAllCaptures(card, tableCards);
    if (captures.isEmpty) {
      widget.onCardPlayed(card, const []);
    } else if (captures.length == 1) {
      widget.onCardPlayed(card, captures.first);
    } else {
      _showCaptureOptions(card, captures, context);
    }
  }

  Future<void> _showCaptureOptions(
    ScopaCard card,
    List<List<ScopaCard>> captures,
    BuildContext context,
  ) async {
    final chosen = await showModalBottomSheet<List<ScopaCard>>(
      context: context,
      backgroundColor: kBackgroundDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: kGold, width: 1),
      ),
      builder: (ctx) => _CapturePickerSheet(card: card, captures: captures),
    );
    if (chosen != null) {
      widget.onCardPlayed(card, chosen);
    }
  }
}

// ── Capture picker bottom sheet ───────────────────────────────────────────────

class _CapturePickerSheet extends StatelessWidget {
  const _CapturePickerSheet({required this.card, required this.captures});

  final ScopaCard card;
  final List<List<ScopaCard>> captures;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CardWidget(card: card, width: 44, height: 66),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'CHOOSE CAPTURE',
                        style: TextStyle(
                          color: kGold,
                          fontSize: 13,
                          fontFamily: 'Cinzel',
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                      Text(
                        '${captures.length} options available',
                        style: TextStyle(
                          color: Colors.white.withAlpha(120),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Divider(color: kGold.withAlpha(60)),
            const SizedBox(height: 12),
            ...captures.map((captureSet) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: () => Navigator.pop(context, captureSet),
                    borderRadius: BorderRadius.circular(12),
                    splashColor: kGold.withAlpha(30),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        border: Border.all(color: kGold.withAlpha(80)),
                        borderRadius: BorderRadius.circular(12),
                        color: kGold.withAlpha(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: captureSet
                                  .map((c) => CardWidget(
                                        key: ValueKey(c),
                                        card: c,
                                        width: 52,
                                        height: 78,
                                      ))
                                  .toList(),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: kGold.withAlpha(30),
                              shape: BoxShape.circle,
                            ),
                            child:
                                const Icon(Icons.check, color: kGold, size: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                )),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}
