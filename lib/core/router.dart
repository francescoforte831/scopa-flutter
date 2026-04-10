import 'package:go_router/go_router.dart';
import 'package:scopa_flutter/models/game_state.dart';
import 'package:scopa_flutter/screens/game_screen.dart';
import 'package:scopa_flutter/screens/menu_screen.dart';
import 'package:scopa_flutter/screens/scoring_screen.dart';

/// Application router configuration using GoRouter.
///
/// Routes:
///   /          → MenuScreen
///   /game      → GameScreen
///   /scoring   → ScoringScreen (requires HandScoringResult via extra)
final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'menu',
      builder: (context, state) => const MenuScreen(),
    ),
    GoRoute(
      path: '/game',
      name: 'game',
      builder: (context, state) => const GameScreen(),
    ),
    GoRoute(
      path: '/scoring',
      name: 'scoring',
      builder: (context, state) {
        final result = state.extra as HandScoringResult;
        return ScoringScreen(result: result);
      },
    ),
  ],
);
