import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scopa_flutter/core/theme.dart';
import 'package:scopa_flutter/models/card_model.dart';
import 'package:scopa_flutter/providers/game_provider.dart';
import 'package:scopa_flutter/services/game_service.dart';
import 'package:scopa_flutter/widgets/card_widget.dart';

/// The green felt table centre — shows table cards and accepts drops/taps.
///
/// Handles capture selection:
///   • Single valid capture → applied automatically.
///   • Multiple valid captures → bottom sheet lets player choose.
///   • No capture → confirms discard.
class TableAreaWidget extends ConsumerStatefulWidget {
  const TableAreaWidget({
    super.key,
    required this.onCardPlayed,
    required this.getSelectedCard,
  });

  final void Function(ScopaCard card, List<ScopaCard> captureTarget) onCardPlayed;

  /// Returns the card currently selected in [HandWidget], if any.
  final ScopaCard? Function() getSelectedCard;

  @override
  ConsumerState<TableAreaWidget> createState() => _TableAreaWidgetState();
}

class _TableAreaWidgetState extends ConsumerState<TableAreaWidget> {
  final _gameService = const GameService();

  // Tracks cards that are animating off the table (capture animation).
  final Set<ScopaCard> _capturedAnimating = {};

  @override
  Widget build(BuildContext context) {
    final tableCards = ref.watch(gameProvider.select((s) => s.tableCards));
    final isPlayerTurn = ref.watch(gameProvider.select((s) => s.isPlayerTurn));
    final lastAction = ref.watch(gameProvider.select((s) => s.lastAction));

    // Trigger capture animation when lastAction has captured cards.
    if (lastAction != null && lastAction.captured.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _capturedAnimating.clear();
          });
        }
      });
    }

    return DragTarget<ScopaCard>(
      onAcceptWithDetails: (details) {
        _handleCardPlayed(details.data, tableCards, context);
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;
        return GestureDetector(
          onTap: () {
            final selected = widget.getSelectedCard();
            if (selected != null && isPlayerTurn) {
              _handleCardPlayed(selected, tableCards, context);
            }
          },
          child: Container(
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isHovering ? kTableGreenLight : kTableGreen,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isHovering ? kGold : kGold.withAlpha(100),
                width: isHovering ? 2.5 : 1.5,
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
                // Empty table hint.
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
                // Table cards.
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      alignment: WrapAlignment.center,
                      children: tableCards.asMap().entries.map((entry) {
                        final index = entry.key;
                        final card = entry.value;
                        return GestureDetector(
                          onTap: () {
                            final selected = widget.getSelectedCard();
                            if (selected != null && isPlayerTurn) {
                              _handleCardPlayedWithTarget(
                                selected, card, tableCards, context,
                              );
                            }
                          },
                          child: CardWidget(key: ValueKey(card), card: card)
                              .animate(delay: (index * 80).ms)
                              .fadeIn(duration: 250.ms)
                              .scale(
                                begin: const Offset(0.7, 0.7),
                                end: const Offset(1.0, 1.0),
                                duration: 250.ms,
                                curve: Curves.easeOut,
                              ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                // Hover glow overlay.
                if (isHovering)
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
    final captures = _gameService.findAllCaptures(card, tableCards);

    if (captures.isEmpty) {
      _confirmDiscard(card, tableCards, context);
    } else if (captures.length == 1) {
      widget.onCardPlayed(card, captures.first);
    } else {
      _showCaptureOptions(card, captures, context);
    }
  }

  void _handleCardPlayedWithTarget(
    ScopaCard card,
    ScopaCard tappedTableCard,
    List<ScopaCard> tableCards,
    BuildContext context,
  ) {
    final captures = _gameService.findAllCaptures(card, tableCards);
    // Find captures that include the tapped table card.
    final matching = captures.where((c) => c.contains(tappedTableCard)).toList();

    if (matching.isEmpty) {
      // Tapped card is not part of any valid capture — show all options.
      _handleCardPlayed(card, tableCards, context);
    } else if (matching.length == 1) {
      widget.onCardPlayed(card, matching.first);
    } else {
      _showCaptureOptions(card, matching, context);
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
    if (chosen != null && mounted) {
      widget.onCardPlayed(card, chosen);
    }
  }

  Future<void> _confirmDiscard(
    ScopaCard card,
    List<ScopaCard> tableCards,
    BuildContext context,
  ) async {
    if (tableCards.isEmpty) {
      // Nothing to capture anyway — discard directly.
      widget.onCardPlayed(card, const []);
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kBackgroundDark,
        title: Text(
          'Discard ${card.displayLabel}${card.suitLabel}?',
          style: const TextStyle(color: kGold, fontFamily: 'Cinzel'),
        ),
        content: const Text(
          'No capture available. Place this card on the table?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    if ((confirmed ?? false) && mounted) {
      widget.onCardPlayed(card, const []);
    }
  }
}

// ── Capture picker bottom sheet ───────────────────────────────────────────────

class _CapturePickerSheet extends StatelessWidget {
  const _CapturePickerSheet({
    required this.card,
    required this.captures,
  });

  final ScopaCard card;
  final List<List<ScopaCard>> captures;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose capture with ${card.displayLabel}${card.suitLabel}',
            style: const TextStyle(
              color: kGold,
              fontSize: 16,
              fontFamily: 'Cinzel',
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...captures.asMap().entries.map((entry) {
            final captureSet = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                onTap: () => Navigator.pop(context, captureSet),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: kGold.withAlpha(100)),
                    borderRadius: BorderRadius.circular(8),
                    color: kGold.withAlpha(15),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.arrow_forward_ios,
                          color: kGold, size: 14),
                      const SizedBox(width: 12),
                      Wrap(
                        spacing: 8,
                        children: captureSet.map((c) {
                          return Text(
                            '${c.displayLabel}${c.suitLabel}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
