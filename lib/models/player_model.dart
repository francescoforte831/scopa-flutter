import 'package:equatable/equatable.dart';
import 'package:scopa_flutter/models/card_model.dart';

/// Represents a player (human or AI) in a Scopa game.
class Player extends Equatable {
  const Player({
    required this.id,
    required this.name,
    this.hand = const [],
    this.captured = const [],
    this.scopeCount = 0,
  });

  /// Unique identifier – 'human' or 'ai'.
  final String id;

  final String name;

  /// Cards currently in the player's hand.
  final List<ScopaCard> hand;

  /// Cards the player has captured this hand.
  final List<ScopaCard> captured;

  /// Number of scope scored this hand.
  final int scopeCount;

  // ── Computed helpers ─────────────────────────────────────────────────────

  int get capturedCount => captured.length;

  int get denariCount => captured.where((c) => c.isDenari).length;

  bool get hasCapturedSettebello => captured.any((c) => c.isSettebello);

  bool get isHuman => id == 'human';

  // ── Immutable update ─────────────────────────────────────────────────────

  Player copyWith({
    String? id,
    String? name,
    List<ScopaCard>? hand,
    List<ScopaCard>? captured,
    int? scopeCount,
  }) {
    return Player(
      id: id ?? this.id,
      name: name ?? this.name,
      hand: hand ?? this.hand,
      captured: captured ?? this.captured,
      scopeCount: scopeCount ?? this.scopeCount,
    );
  }

  @override
  List<Object?> get props => [id, name, hand, captured, scopeCount];
}
