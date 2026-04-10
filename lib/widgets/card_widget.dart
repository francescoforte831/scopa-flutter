import 'package:flutter/material.dart';
import 'package:scopa_flutter/core/theme.dart';
import 'package:scopa_flutter/models/card_model.dart';

/// Renders a single Scopa card — either face-up or face-down.
///
/// Tries to load the card image asset first; falls back to [_ColoredCardFace]
/// if no image exists, so the game is immediately playable without art assets.
class CardWidget extends StatelessWidget {
  const CardWidget({
    super.key,
    required this.card,
    this.faceDown = false,
    this.isSelected = false,
    this.isDragging = false,
    this.width = 68,
    this.height = 102,
  });

  final ScopaCard card;
  final bool faceDown;

  /// Highlighted with a gold border (used in capture selection).
  final bool isSelected;

  /// Reduced opacity when being dragged (ghost effect).
  final bool isDragging;

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: isDragging ? 0.35 : 1.0,
      duration: const Duration(milliseconds: 150),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? kGold.withAlpha(200)
                  : Colors.black.withAlpha(100),
              blurRadius: isSelected ? 12 : 4,
              spreadRadius: isSelected ? 2 : 0,
            ),
          ],
          border: isSelected
              ? Border.all(color: kGold, width: 2.5)
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(7),
          child: faceDown ? _CardBack(width: width, height: height) : _CardFront(card: card),
        ),
      ),
    );
  }
}

// ── Card front ────────────────────────────────────────────────────────────────

class _CardFront extends StatelessWidget {
  const _CardFront({required this.card});

  final ScopaCard card;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      card.assetPath,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stack) => _ColoredCardFace(card: card),
    );
  }
}

/// Fallback card face rendered entirely with Flutter primitives.
/// Used when card image PNGs are not yet present in assets.
class _ColoredCardFace extends StatelessWidget {
  const _ColoredCardFace({required this.card});

  final ScopaCard card;

  Color get _borderColor =>
      (card.suit == Suit.coppe || card.suit == Suit.denari)
          ? kSuitRed
          : kSuitDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: kCardCream,
      child: Stack(
        children: [
          // Decorative border.
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: _borderColor, width: 3),
              ),
            ),
          ),
          // Top-left corner value + suit.
          Positioned(
            top: 4,
            left: 6,
            child: _CornerLabel(card: card, color: _borderColor),
          ),
          // Center suit symbol.
          Center(
            child: Text(
              card.suitSymbol,
              style: TextStyle(
                fontSize: 28,
                color: _borderColor.withAlpha(220),
              ),
            ),
          ),
          // Value label centre-top (for face cards).
          if (card.value >= 8)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  Text(
                    _faceCardName,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: _borderColor,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          // Bottom-right corner (rotated 180°).
          Positioned(
            bottom: 4,
            right: 6,
            child: Transform.rotate(
              angle: 3.14159,
              child: _CornerLabel(card: card, color: _borderColor),
            ),
          ),
        ],
      ),
    );
  }

  String get _faceCardName {
    switch (card.value) {
      case 8: return 'FANTE';
      case 9: return 'CAVALLO';
      case 10: return 'RE';
      default: return '';
    }
  }
}

class _CornerLabel extends StatelessWidget {
  const _CornerLabel({required this.card, required this.color});

  final ScopaCard card;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          card.displayLabel,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: color,
            height: 1.1,
          ),
        ),
        Text(
          card.suitLabel,
          style: TextStyle(
            fontSize: 9,
            color: color,
            height: 1.1,
          ),
        ),
      ],
    );
  }
}

// ── Card back ─────────────────────────────────────────────────────────────────

class _CardBack extends StatelessWidget {
  const _CardBack({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: const BoxDecoration(
        color: Color(0xFF1A3A5C),
      ),
      child: CustomPaint(
        painter: _CardBackPainter(),
      ),
    );
  }
}

class _CardBackPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = kGold.withAlpha(60)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    // Draw a simple diamond grid pattern.
    const spacing = 12.0;
    for (double x = 0; x <= size.width + spacing; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x - size.height, size.height), paint);
      canvas.drawLine(Offset(x, 0), Offset(x + size.height, size.height), paint);
    }

    // Gold border.
    final borderPaint = Paint()
      ..color = kGold.withAlpha(150)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final rect = Rect.fromLTWH(3, 3, size.width - 6, size.height - 6);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(5)),
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// The card widget displayed during dragging — elevated with shadow.
class DraggingCardWidget extends StatelessWidget {
  const DraggingCardWidget({
    super.key,
    required this.card,
    this.width = 68,
    this.height = 102,
  });

  final ScopaCard card;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: 1.1,
      child: Material(
        elevation: 16,
        borderRadius: BorderRadius.circular(8),
        shadowColor: Colors.black54,
        child: CardWidget(card: card, width: width, height: height),
      ),
    );
  }
}
