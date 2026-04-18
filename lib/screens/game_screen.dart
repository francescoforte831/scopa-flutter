import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:scopa_flutter/core/constants.dart';
import 'package:scopa_flutter/core/theme.dart';
import 'package:scopa_flutter/models/card_model.dart';
import 'package:scopa_flutter/models/game_state.dart';
import 'package:scopa_flutter/providers/game_provider.dart';
import 'package:scopa_flutter/services/game_service.dart';
import 'package:scopa_flutter/widgets/ai_hand_widget.dart';
import 'package:scopa_flutter/widgets/card_widget.dart';
import 'package:scopa_flutter/widgets/hand_widget.dart';
import 'package:scopa_flutter/widgets/score_display_widget.dart';
import 'package:scopa_flutter/widgets/table_area_widget.dart';

/// Primary game screen — table, cards, HUD, and animation orchestration.
class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  // ── Widget keys for position lookups ─────────────────────────────────────
  final _stackKey = GlobalKey();
  final _handKey = GlobalKey<HandWidgetState>();
  final _aiHandKey = GlobalKey<AiHandWidgetState>();
  final _tableKey = GlobalKey<TableAreaWidgetState>();

  // ── Animation state ───────────────────────────────────────────────────────
  final List<_FlyJob> _flyingCards = [];
  bool _animating = false;
  ScopaCard? _ghostCard;  // card in hand shown as a ghost while flying
  int _aiHandHidden = 0;  // face-down cards hidden while the AI fly plays

  // ── Other UI state ────────────────────────────────────────────────────────
  bool _showScopaOverlay = false;
  String _scopaActorName = '';

  final _gameService = const GameService();

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Converts a global screen [offset] to the local coordinate system of the
  /// root [_stackKey] Stack, so [Positioned] widgets land in the right place.
  Offset _toLocal(Offset global) {
    final box = _stackKey.currentContext?.findRenderObject() as RenderBox?;
    return box?.globalToLocal(global) ?? global;
  }

  Offset _tableCenterLocal() {
    final global = _tableKey.currentState?.tableCenterGlobal;
    if (global == null) return const Offset(200, 300);
    return _toLocal(global);
  }

  /// Landing spot for human plays: bottom edge of the table area, centred.
  Offset _humanApproachLocal(Size cardSize) {
    final bounds = _tableKey.currentState?.containerBounds;
    if (bounds == null) return _tableCenterLocal();
    final global = Offset(
      bounds.left + (bounds.width - cardSize.width) / 2,
      bounds.bottom - cardSize.height - 20,
    );
    return _toLocal(global);
  }

  /// Landing spot for AI plays: top edge of the table area, centred.
  Offset _aiApproachLocal(Size cardSize) {
    final bounds = _tableKey.currentState?.containerBounds;
    if (bounds == null) return _tableCenterLocal();
    final global = Offset(
      bounds.left + (bounds.width - cardSize.width) / 2,
      bounds.top + 20,
    );
    return _toLocal(global);
  }

  Offset _humanPileLocal(Size screenSize) =>
      Offset(screenSize.width * 0.1, screenSize.height + 60);

  Offset _aiPileLocal(Size screenSize) =>
      Offset(screenSize.width * 0.9, -60);

  // ── Flying card management ────────────────────────────────────────────────

  Future<void> _fly(_FlyJob job) {
    setState(() => _flyingCards.add(job));
    return job.done;
  }

  void _removeFly(_FlyJob job) {
    if (mounted) setState(() => _flyingCards.remove(job));
  }

  // ── Human play flow ───────────────────────────────────────────────────────

  Future<void> _onHandCardTapped(ScopaCard card, BuildContext context) async {
    if (!ref.read(gameProvider).isPlayerTurn) return;
    if (_animating) return;

    // Capture before any await.
    final screenSize = MediaQuery.of(context).size;
    final tableCards = ref.read(gameProvider).tableCards;
    final captures = _gameService.findAllCaptures(card, tableCards);

    List<ScopaCard> chosen;
    if (captures.isEmpty) {
      chosen = const [];
    } else if (captures.length == 1) {
      chosen = captures.first;
    } else {
      final picked = await _showCaptureOptions(card, captures, context);
      if (picked == null || !mounted) return;
      chosen = picked;
    }

    await _animateHumanPlay(card, chosen, screenSize);
  }

  Future<void> _animateHumanPlay(
    ScopaCard card,
    List<ScopaCard> captureTarget,
    Size screenSize,
  ) async {
    _animating = true;

    final cardOffset = _handKey.currentState?.cardGlobalOffset(card);
    final tableCardSize = _tableKey.currentState?.cardSize ?? const Size(68, 102);
    final approachPos = _humanApproachLocal(tableCardSize);
    final fromLocal = cardOffset != null
        ? _toLocal(cardOffset)
        : approachPos;

    // Snapshot table-card positions before any state change.
    final captureOffsets = <ScopaCard, Offset>{};
    for (final c in captureTarget) {
      final gPos = _tableKey.currentState?.cardGlobalOffset(c);
      if (gPos != null) captureOffsets[c] = _toLocal(gPos);
    }

    setState(() => _ghostCard = card);

    // ── Phase 1: played card floats to table edge ─────────────────────────────
    final job1 = _FlyJob(
      card: card, from: fromLocal, to: approachPos,
      size: tableCardSize, durationMs: 700,
    );
    await _fly(job1);
    // job1 parked at table edge.

    if (captureTarget.isEmpty) {
      // ── Discard: settle onto table immediately ────────────────────────────
      setState(() {
        _flyingCards.remove(job1);
        _ghostCard = null;
      });
      ref.read(gameProvider.notifier).humanPlayCard(card, captureTarget);
    } else {
      // ── Capture: pause so the play is readable ────────────────────────────
      await Future.delayed(const Duration(milliseconds: 1000));
      if (!mounted) return;

      // Commit state — real table cards vanish; overlay cards take their place.
      setState(() => _ghostCard = null);
      ref.read(gameProvider.notifier).humanPlayCard(card, captureTarget);

      // Glow phase — all involved cards pulse and glow before sweeping.
      final glowJobs = <_FlyJob>[
        _FlyJob(card: card, from: approachPos, to: approachPos,
            size: tableCardSize, durationMs: 500, glowing: true),
        ...captureTarget.map((c) => _FlyJob(
          card: c,
          from: captureOffsets[c] ?? approachPos,
          to: captureOffsets[c] ?? approachPos,
          size: tableCardSize, durationMs: 500, glowing: true,
        )),
      ];

      setState(() {
        _flyingCards.remove(job1);
        _flyingCards.addAll(glowJobs);
      });
      await Future.wait(glowJobs.map((j) => j.done));
      if (!mounted) return;

      // Sweep — all cards fly simultaneously to the player's pile.
      final pileTarget = _humanPileLocal(screenSize);
      final sweepJobs = <_FlyJob>[
        _FlyJob(card: card, from: approachPos, to: pileTarget,
            size: tableCardSize, durationMs: 700, curve: Curves.easeIn),
        ...captureTarget.map((c) => _FlyJob(
          card: c,
          from: captureOffsets[c] ?? approachPos,
          to: pileTarget,
          size: tableCardSize, durationMs: 700, curve: Curves.easeIn,
        )),
      ];

      setState(() {
        _flyingCards.removeWhere(glowJobs.contains);
        _flyingCards.addAll(sweepJobs);
      });

      await Future.wait(sweepJobs.map((j) => j.done));
      for (final j in sweepJobs) { _removeFly(j); }
    }

    _animating = false;
  }

  // ── AI play flow ──────────────────────────────────────────────────────────

  Future<void> _runAiTurn(BuildContext context) async {
    final screenSize = MediaQuery.of(context).size;
    await Future<void>.delayed(kAiThinkDuration);
    if (!mounted || !ref.read(gameProvider).isAiTurn) return;

    final play = ref.read(gameProvider.notifier).peekAiPlay();
    await _animateAiPlay(play, screenSize);
  }

  Future<void> _animateAiPlay(dynamic play, Size screenSize) async {
    _animating = true;
    setState(() => _aiHandHidden = 1);

    final aiCenter = _aiHandKey.currentState?.handCenterGlobal;
    final aiCardSize = _aiHandKey.currentState?.cardSize ?? const Size(52, 78);
    final tableCardSize = _tableKey.currentState?.cardSize ?? const Size(68, 102);
    final approachPos = _aiApproachLocal(tableCardSize);

    final from = aiCenter != null
        ? _toLocal(aiCenter) - Offset(aiCardSize.width / 2, aiCardSize.height / 2)
        : _aiPileLocal(screenSize);

    // Snapshot table-card positions before state change.
    final captureOffsets = <ScopaCard, Offset>{};
    for (final c in play.captureTarget as List<ScopaCard>) {
      final gPos = _tableKey.currentState?.cardGlobalOffset(c);
      if (gPos != null) captureOffsets[c] = _toLocal(gPos);
    }

    // ── Phase 1: AI card flies face-up to top edge of table ──────────────────
    final job1 = _FlyJob(
      card: play.cardToPlay as ScopaCard,
      from: from,
      to: approachPos,
      size: tableCardSize,   // same size as table cards
      durationMs: 700,
    );
    await _fly(job1);
    // job1 parked at table edge.

    // Pause: human can read what the AI played.
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;

    setState(() => _aiHandHidden = 0);
    ref.read(gameProvider.notifier).applyAiTurn(play);

    if ((play.captureTarget as List<ScopaCard>).isEmpty) {
      // ── Discard: settle card onto table ──────────────────────────────────
      setState(() => _flyingCards.remove(job1));
    } else {
      // ── Capture: glow then sweep ─────────────────────────────────────────
      final captured = play.captureTarget as List<ScopaCard>;
      final played = play.cardToPlay as ScopaCard;

      // Glow phase — all involved cards pulse and glow.
      final glowJobs = <_FlyJob>[
        _FlyJob(card: played, from: approachPos, to: approachPos,
            size: tableCardSize, durationMs: 500, glowing: true),
        ...captured.map((c) => _FlyJob(
          card: c,
          from: captureOffsets[c] ?? approachPos,
          to: captureOffsets[c] ?? approachPos,
          size: tableCardSize, durationMs: 500, glowing: true,
        )),
      ];

      setState(() {
        _flyingCards.remove(job1);
        _flyingCards.addAll(glowJobs);
      });
      await Future.wait(glowJobs.map((j) => j.done));
      if (!mounted) return;

      // Sweep — all cards fly simultaneously to the AI's pile.
      final pileTarget = _aiPileLocal(screenSize);
      final sweepJobs = <_FlyJob>[
        _FlyJob(card: played, from: approachPos, to: pileTarget,
            size: tableCardSize, durationMs: 700, curve: Curves.easeIn),
        ...captured.map((c) => _FlyJob(
          card: c,
          from: captureOffsets[c] ?? approachPos,
          to: pileTarget,
          size: tableCardSize, durationMs: 700, curve: Curves.easeIn,
        )),
      ];

      setState(() {
        _flyingCards.removeWhere(glowJobs.contains);
        _flyingCards.addAll(sweepJobs);
      });

      await Future.wait(sweepJobs.map((j) => j.done));
      for (final j in sweepJobs) { _removeFly(j); }
    }

    _animating = false;
  }

  // ── Other interaction ─────────────────────────────────────────────────────

  void _onCardPlayed(ScopaCard card, List<ScopaCard> captureTarget) {
    if (!ref.read(gameProvider).isPlayerTurn) return;
    ref.read(gameProvider.notifier).humanPlayCard(card, captureTarget);
  }

  Future<List<ScopaCard>?> _showCaptureOptions(
    ScopaCard card,
    List<List<ScopaCard>> captures,
    BuildContext context,
  ) {
    return showModalBottomSheet<List<ScopaCard>>(
      context: context,
      backgroundColor: kBackgroundDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: kGold, width: 1),
      ),
      builder: (ctx) => _CapturePickerSheet(card: card, captures: captures),
    );
  }

  // ── Phase & action listeners ──────────────────────────────────────────────

  void _onPhaseChanged(GamePhase? prev, GamePhase next) {
    if (next == GamePhase.aiTurn) {
      _runAiTurn(context);
    } else if (next == GamePhase.handOver || next == GamePhase.gameOver) {
      _navigateToScoring();
    }
  }

  void _onLastActionChanged(LastAction? prev, LastAction? next) {
    if (next == null) return;
    if (next.wasScopa) {
      final actor = next.actorId == 'human'
          ? ref.read(gameProvider).humanPlayer.name
          : ref.read(gameProvider).aiPlayer.name;
      _triggerScopaAnimation(actor);
    }
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) ref.read(gameProvider.notifier).clearLastAction();
    });
  }

  void _triggerScopaAnimation(String actorName) {
    setState(() {
      _showScopaOverlay = true;
      _scopaActorName = actorName;
    });
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) setState(() => _showScopaOverlay = false);
    });
  }

  Future<void> _navigateToScoring() async {
    if (_animating) return;
    _animating = true;

    final tableCards = List<ScopaCard>.from(ref.read(gameProvider).tableCards);
    final lastCaptorId = ref.read(gameProvider.notifier).lastCaptorId;
    final screenSize = MediaQuery.of(context).size;

    if (tableCards.isNotEmpty && lastCaptorId != null) {
      final tableCardSize =
          _tableKey.currentState?.cardSize ?? const Size(68, 102);
      final centerFallback = _tableCenterLocal();

      final cardOffsets = <ScopaCard, Offset>{};
      for (final c in tableCards) {
        final gPos = _tableKey.currentState?.cardGlobalOffset(c);
        if (gPos != null) cardOffsets[c] = _toLocal(gPos);
      }

      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;

      // Glow phase — remaining cards pulse before sweeping to last captor.
      final glowJobs = tableCards
          .map((c) => _FlyJob(
                card: c,
                from: cardOffsets[c] ?? centerFallback,
                to: cardOffsets[c] ?? centerFallback,
                size: tableCardSize,
                durationMs: 500,
                glowing: true,
              ))
          .toList();

      setState(() => _flyingCards.addAll(glowJobs));
      await Future.wait(glowJobs.map((j) => j.done));
      if (!mounted) return;

      // Sweep to last captor's pile.
      final pileTarget = lastCaptorId == 'human'
          ? _humanPileLocal(screenSize)
          : _aiPileLocal(screenSize);

      final sweepJobs = tableCards
          .map((c) => _FlyJob(
                card: c,
                from: cardOffsets[c] ?? centerFallback,
                to: pileTarget,
                size: tableCardSize,
                durationMs: 700,
                curve: Curves.easeIn,
              ))
          .toList();

      setState(() {
        _flyingCards.removeWhere(glowJobs.contains);
        _flyingCards.addAll(sweepJobs);
      });

      await Future.wait(sweepJobs.map((j) => j.done));
      for (final j in sweepJobs) {
        _removeFly(j);
      }
    } else {
      await Future.delayed(const Duration(milliseconds: 600));
    }

    _animating = false;
    if (!mounted) return;
    final result = ref.read(gameProvider.notifier).acknowledgeHandEnd();
    context.go('/scoring', extra: result);
  }

  Future<void> _confirmExit(BuildContext context) async {
    final router = GoRouter.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kBackgroundDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: kGold, width: 1),
        ),
        title: const Text(
          'QUIT GAME?',
          style: TextStyle(
            color: kGold,
            fontFamily: 'Cinzel',
            fontSize: 16,
            letterSpacing: 2,
          ),
        ),
        content: const Text(
          'Your progress will be lost.',
          style: TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCEL', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('QUIT', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      router.go('/');
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    ref.listen<GamePhase>(
      gameProvider.select((s) => s.phase),
      _onPhaseChanged,
    );
    ref.listen<LastAction?>(
      gameProvider.select((s) => s.lastAction),
      _onLastActionChanged,
    );

    final isPlayerTurn = ref.watch(gameProvider.select((s) => s.isPlayerTurn));

    return Scaffold(
      backgroundColor: kTableGreen,
      body: SafeArea(
        child: Stack(
          key: _stackKey,
          children: [
            Column(
              children: [
                // ── HUD ──────────────────────────────────────────────────────
                ScoreDisplayWidget(onExit: () => _confirmExit(context)),

                // ── AI hand ──────────────────────────────────────────────────
                AiHandWidget(key: _aiHandKey, hiddenCount: _aiHandHidden),

                // ── Table ─────────────────────────────────────────────────────
                Expanded(
                  child: TableAreaWidget(
                    key: _tableKey,
                    onCardPlayed: _onCardPlayed,
                  ),
                ),

                // ── Turn indicator ────────────────────────────────────────────
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 28,
                  color: isPlayerTurn ? kGold.withAlpha(30) : Colors.transparent,
                  alignment: Alignment.center,
                  child: isPlayerTurn
                      ? const Text(
                          'YOUR TURN — tap or drag a card',
                          style: TextStyle(
                            fontSize: 11,
                            color: kGold,
                            letterSpacing: 1.5,
                            fontFamily: 'Cinzel',
                          ),
                        )
                      : const Text(
                          'Computer is thinking…',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white38,
                            letterSpacing: 1,
                          ),
                        ),
                ),

                // ── Human hand ────────────────────────────────────────────────
                HandWidget(
                  key: _handKey,
                  ghostCard: _ghostCard,
                  onCardPlayed: _onCardPlayed,
                  onCardTapped: (card) => _onHandCardTapped(card, context),
                ),
              ],
            ),

            // ── Flying card overlay ───────────────────────────────────────────
            ..._flyingCards.map(
              (job) => _FlyingCardWidget(
                key: ValueKey(job.id),
                job: job,
                onComplete: () => job.complete(),
              ),
            ),

            // ── Scopa overlay ─────────────────────────────────────────────────
            if (_showScopaOverlay) _ScopaOverlay(actorName: _scopaActorName),
          ],
        ),
      ),
    );
  }
}

// ── Flying card job ───────────────────────────────────────────────────────────

class _FlyJob {
  static int _nextId = 0;
  final int id = _nextId++;
  final ScopaCard card;
  final Offset from;
  final Offset to;
  final Size size;
  final int durationMs;
  final Curve curve;
  final bool glowing;
  final Completer<void> _completer = Completer<void>();

  _FlyJob({
    required this.card,
    required this.from,
    required this.to,
    required this.size,
    this.durationMs = 650,
    this.curve = Curves.easeInOut,
    this.glowing = false,
  });

  Future<void> get done => _completer.future;
  void complete() {
    if (!_completer.isCompleted) _completer.complete();
  }
}

// ── Flying card widget ────────────────────────────────────────────────────────

class _FlyingCardWidget extends StatefulWidget {
  const _FlyingCardWidget({
    super.key,
    required this.job,
    required this.onComplete,
  });

  final _FlyJob job;
  final VoidCallback onComplete;

  @override
  State<_FlyingCardWidget> createState() => _FlyingCardWidgetState();
}

class _FlyingCardWidgetState extends State<_FlyingCardWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _posAnim;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.job.durationMs),
    );
    _posAnim = Tween<Offset>(begin: widget.job.from, end: widget.job.to)
        .animate(CurvedAnimation(parent: _ctrl, curve: widget.job.curve));
    _scaleAnim = widget.job.glowing
        ? Tween<double>(begin: 1.0, end: 1.15)
            .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut))
        : TweenSequence<double>([
            TweenSequenceItem(
                tween: Tween(begin: 1.0, end: 1.12), weight: 40),
            TweenSequenceItem(
                tween: Tween(begin: 1.12, end: 1.0), weight: 60),
          ]).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));

    _ctrl.forward().then((_) {
      widget.onComplete();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cardChild = CardWidget(
      card: widget.job.card,
      width: widget.job.size.width,
      height: widget.job.size.height,
    );

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (ctx, child) => Positioned(
        left: _posAnim.value.dx,
        top: _posAnim.value.dy,
        width: widget.job.size.width,
        height: widget.job.size.height,
        child: Transform.scale(
          scale: _scaleAnim.value,
          child: widget.job.glowing
              ? Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: kGold.withAlpha((_ctrl.value * 200).round()),
                        blurRadius: 12 + _ctrl.value * 12,
                        spreadRadius: _ctrl.value * 6,
                      ),
                    ],
                  ),
                  child: child,
                )
              : child,
        ),
      ),
      child: cardChild,
    );
  }
}

// ── Scopa overlay ─────────────────────────────────────────────────────────────

class _ScopaOverlay extends StatelessWidget {
  const _ScopaOverlay({required this.actorName});

  final String actorName;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(color: kGold.withAlpha(0))
                .animate()
                .custom(
                  duration: 200.ms,
                  builder: (ctx, value, child) =>
                      Container(color: kGold.withAlpha((value * 50).round())),
                )
                .then()
                .custom(
                  duration: 700.ms,
                  builder: (ctx, value, child) =>
                      Container(color: kGold.withAlpha(((1 - value) * 50).round())),
                ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('SCOPA!', style: kScopaTextStyle)
                    .animate()
                    .scale(
                      begin: const Offset(0.4, 0.4),
                      end: const Offset(1.15, 1.15),
                      duration: 300.ms,
                      curve: Curves.elasticOut,
                    )
                    .fadeIn(duration: 200.ms),
                const SizedBox(height: 8),
                Text(
                  actorName.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    letterSpacing: 3,
                    fontFamily: 'Cinzel',
                  ),
                ).animate(delay: 200.ms).fadeIn(),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Capture picker sheet ──────────────────────────────────────────────────────

class _CapturePickerSheet extends StatelessWidget {
  const _CapturePickerSheet({required this.card, required this.captures});

  final ScopaCard card;
  final List<List<ScopaCard>> captures;

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.8;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
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
            ),
            const SizedBox(height: 12),
            Divider(color: kGold.withAlpha(60)),
            const SizedBox(height: 4),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: captures
                      .map(
                        (captureSet) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: InkWell(
                            onTap: () => Navigator.pop(context, captureSet),
                            borderRadius: BorderRadius.circular(12),
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
                                                card: c,
                                                width: 50,
                                                height: 75,
                                              ))
                                          .toList(),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: kGold.withAlpha(30),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.check,
                                        color: kGold, size: 14),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
