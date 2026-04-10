import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scopa_flutter/services/ai_service.dart';
import 'package:scopa_flutter/services/deck_service.dart';
import 'package:scopa_flutter/services/game_service.dart';

/// Service providers — singleton instances injected throughout the app.

final deckServiceProvider = Provider<DeckService>((ref) => DeckService());

final gameServiceProvider = Provider<GameService>((ref) => const GameService());

final aiServiceProvider = Provider<AiService>((ref) => const AiService());
