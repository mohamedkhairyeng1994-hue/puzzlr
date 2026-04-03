import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/app_state.dart';
import '../../core/theme.dart';
import '../../models/puzzle_model.dart';

// ── GameMode ──────────────────────────────────────────────────────────────────

enum GameMode { classic, timeAttack, daily }

// ── GameScreen ────────────────────────────────────────────────────────────────

class GameScreen extends StatefulWidget {
  final Difficulty difficulty;
  final String imageUrl;
  final ui.Image? customImage;
  final GameMode mode;
  final int? seed;

  const GameScreen({
    super.key,
    required this.difficulty,
    required this.imageUrl,
    this.customImage,
    this.mode = GameMode.classic,
    this.seed,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  late PuzzleModel _model;
  ui.Image? _image;
  bool _imageLoaded = false;
  bool _showPreview = false;

  // Timer
  Timer? _ticker;
  int _elapsedSeconds = 0;
  int _remainingSeconds = 0;
  bool _timedOut = false;

  late AnimationController _solvedAnim;
  late AnimationController _gameOverAnim;
  late AnimationController _shakeAnim;
  int? _lastInvalidTap;

  bool _usedPowerups = false;

  Color get _modeAccent {
    switch (widget.mode) {
      case GameMode.timeAttack:
        return T.timeAttack;
      case GameMode.daily:
        return T.daily;
      case GameMode.classic:
        return widget.difficulty.accent;
    }
  }

  String _failReason = '';

  @override
  void initState() {
    super.initState();
    _model = PuzzleModel(
      difficulty: widget.difficulty,
      seed: widget.seed,
      usePowerups: true,
    );
    _model.addListener(_onModelUpdated);
    _remainingSeconds = widget.difficulty.timeLimit;

    _solvedAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _gameOverAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _shakeAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    if (widget.customImage != null) {
      _image = widget.customImage;
      _imageLoaded = true;
    } else if (widget.imageUrl.isNotEmpty) {
      _loadImage();
    } else {
      _imageLoaded = true;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showInstructions();
    });
  }

  void _onModelUpdated() {
    if (_gameOverAnim.isAnimating ||
        _solvedAnim.isAnimating ||
        _gameOverAnim.value > 0 ||
        _solvedAnim.value > 0 ||
        _timedOut)
      return;
    // Daily mode has no move limit
    if (widget.mode == GameMode.daily) return;
    if (_model.moves >= widget.difficulty.moveLimit) {
      _ticker?.cancel();
      setState(() {
        _timedOut = true;
        _failReason = 'Out of Moves!';
      });
      _gameOverAnim.forward();
    }
  }

  void _showInstructions() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            GlassCard(
              padding: const EdgeInsets.fromLTRB(28, 40, 28, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'OBJECTIVES',
                    style: GoogleFonts.luckiestGuy(
                      fontSize: 34,
                      color: Colors.white,
                      letterSpacing: 2.0,
                      shadows: const [
                        Shadow(color: Colors.black, offset: Offset(0, 3)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Rules Content
                  _RuleItem(
                    icon: Icons.timer_rounded,
                    color: T.timeAttack,
                    title: 'Time Limit',
                    value: widget.mode == GameMode.daily
                        ? '∞'
                        : '${widget.difficulty.timeLimit}s',
                  ),
                  const SizedBox(height: 16),
                  _RuleItem(
                    icon: Icons.pan_tool_rounded,
                    color: T.daily,
                    title: 'Max Moves',
                    value: widget.mode == GameMode.daily
                        ? '∞'
                        : '${widget.difficulty.moveLimit}',
                  ),
                  const SizedBox(height: 32),

                  Text(
                    widget.mode == GameMode.daily
                        ? 'Slide tiles into their correct spots.\nNo limits — just solve it as fast as you can!'
                        : 'Slide tiles into their correct spots.\nBeat the targets below to earn more stars!',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.fredoka(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: T.gold.withValues(alpha: 0.6),
                        width: 2,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          offset: Offset(0, 4),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          'REWARDS',
                          style: GoogleFonts.luckiestGuy(
                            fontSize: 22,
                            color: T.gold,
                            letterSpacing: 1.5,
                            shadows: const [
                              Shadow(
                                color: Colors.black54,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.local_fire_department_rounded,
                                  color: T.gold,
                                  size: 24,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '+3',
                                  style: GoogleFonts.luckiestGuy(
                                    color: Colors.white,
                                    fontSize: 20,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              '≤ ${widget.difficulty.starA} Moves',
                              style: GoogleFonts.fredoka(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.local_fire_department_rounded,
                                  color: T.gold,
                                  size: 24,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '+2',
                                  style: GoogleFonts.luckiestGuy(
                                    color: Colors.white,
                                    fontSize: 20,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              '≤ ${widget.difficulty.starB} Moves',
                              style: GoogleFonts.fredoka(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.local_fire_department_rounded,
                                  color: T.gold,
                                  size: 24,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '+1',
                                  style: GoogleFonts.luckiestGuy(
                                    color: Colors.white,
                                    fontSize: 20,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              'Finish Board',
                              style: GoogleFonts.fredoka(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Play Button
                  GestureDetector(
                    onTap: () {
                      Navigator.of(ctx).pop();
                      _startTimer();
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(
                        color: T.daily, // Green
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black45,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          'PLAY NOW',
                          style: GoogleFonts.luckiestGuy(
                            fontSize: 28,
                            color: Colors.white,
                            letterSpacing: 1.5,
                            shadows: const [
                              Shadow(
                                color: Colors.black54,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ), // End GlassCard
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).pop();
                },
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: T.timeAttack,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2.5),
                    boxShadow: const [
                      BoxShadow(color: Colors.black45, offset: Offset(0, 3)),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _startTimer() {
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _model.solved) return;
      setState(() {
        _elapsedSeconds++;
        _remainingSeconds = (widget.difficulty.timeLimit - _elapsedSeconds)
            .clamp(0, widget.difficulty.timeLimit);
      });
      // Daily mode has no time limit - timer just counts up
      if (widget.mode == GameMode.daily) return;
      if (_remainingSeconds <= 0) {
        _ticker?.cancel();
        setState(() {
          _timedOut = true;
          _failReason = "Time's Up!";
        });
        _gameOverAnim.forward();
      }
    });
  }

  Future<void> _loadImage() async {
    try {
      final provider = NetworkImage(widget.imageUrl);
      final stream = provider.resolve(ImageConfiguration.empty);
      stream.addListener(
        ImageStreamListener(
          (info, _) {
            if (!mounted) return;
            setState(() {
              _image = info.image;
              _imageLoaded = true;
            });
          },
          onError: (e, s) {
            if (!mounted) return;
            setState(() => _imageLoaded = true);
          },
        ),
      );
    } catch (_) {
      if (mounted) setState(() => _imageLoaded = true);
    }
  }

  void _onAiSolve() {
    if (_model.solved || _timedOut) return;
    _model.forceSolve();
    _ticker?.cancel();
    HapticFeedback.heavyImpact();
    _recordSolve();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _solvedAnim.forward();
    });
  }

  void _onTileTap(int pos) {
    if (_model.solved || _timedOut) return;
    if (_model.canMove(pos)) {
      _model.tap(pos);
      if (_model.solved) {
        _ticker?.cancel();
        HapticFeedback.heavyImpact();
        _recordSolve();
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) _solvedAnim.forward();
        });
      }
    } else {
      setState(() => _lastInvalidTap = pos);
      _shakeAnim.forward(from: 0).then((_) {
        if (mounted) setState(() => _lastInvalidTap = null);
      });
    }
  }

  void _recordSolve() {
    final appState = context.read<AppState>();
    if (widget.mode == GameMode.daily) {
      // Daily mode uses the stage system
      appState.recordDailyStage(
        d: widget.difficulty,
        moves: _model.moves,
        seconds: _elapsedSeconds,
      );
    } else {
      appState.recordSolve(
        d: widget.difficulty,
        moves: _model.moves,
        seconds: _elapsedSeconds,
        usedPowerups: _usedPowerups,
        isTimeAttack: widget.mode == GameMode.timeAttack,
        isCustomPhoto: widget.customImage != null,
      );
    }
  }

  void _onPeekStart() {
    setState(() => _showPreview = true);
  }

  void _onPeekEnd() {
    setState(() => _showPreview = false);
  }

  void _handleReplay() {
    // Daily mode doesn't require tries
    if (widget.mode == GameMode.daily) {
      _doRestart();
      return;
    }
    final state = context.read<AppState>();
    if (state.triesLeft <= 0) {
      _showOutOfTriesDialog();
    } else {
      state.useTry();
      _doRestart();
    }
  }

  void _doRestart() {
    _ticker?.cancel();
    _gameOverAnim.reset();
    _solvedAnim.reset();
    _elapsedSeconds = 0;
    _remainingSeconds = widget.difficulty.timeLimit;
    _timedOut = false;
    _failReason = '';
    _usedPowerups = false;
    _model.restart();
    _startTimer();
  }

  void _showOutOfTriesDialog() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: GlassCard(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'OUT OF TRIES',
                style: GoogleFonts.luckiestGuy(
                  fontSize: 32,
                  color: Colors.white,
                  letterSpacing: 1.5,
                  shadows: const [
                    Shadow(color: Colors.black, offset: Offset(0, 3)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'You have 0 tries left today.\nWatch an ad to get 1 more try!',
                textAlign: TextAlign.center,
                style: GoogleFonts.fredoka(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 16),
              StreamBuilder(
                stream: Stream.periodic(const Duration(seconds: 1)),
                builder: (context, _) {
                  final now = DateTime.now();
                  final tomorrow = DateTime(now.year, now.month, now.day + 1);
                  final diff = tomorrow.difference(now);

                  final h = diff.inHours.toString().padLeft(2, '0');
                  final m = (diff.inMinutes % 60).toString().padLeft(2, '0');
                  final s = (diff.inSeconds % 60).toString().padLeft(2, '0');

                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white24, width: 1.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.timer_outlined,
                          color: T.gold,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Free Refill In $h:$m:$s',
                          style: GoogleFonts.fredoka(
                            color: T.gold,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),
              GestureDetector(
                onTap: () async {
                  Navigator.of(ctx).pop();
                  await ctx.read<AppState>().watchAdForTry();
                  if (context.mounted) {
                    context.read<AppState>().useTry();
                    _doRestart();
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: T.timeAttack,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: const [
                      BoxShadow(color: Colors.black45, offset: Offset(0, 4)),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      'WATCH AD',
                      style: GoogleFonts.luckiestGuy(
                        fontSize: 24,
                        color: Colors.white,
                        letterSpacing: 2.0,
                        shadows: const [
                          Shadow(color: Colors.black54, offset: Offset(0, 2)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _solvedAnim.dispose();
    _gameOverAnim.dispose();
    _shakeAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final d = widget.difficulty;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      body: AnimatedBg(
        child: Stack(
          children: [
            SafeArea(
              child: ListenableBuilder(
                listenable: _model,
                builder: (ctx, _) => Column(
                  children: [
                    _TopBar(
                      difficulty: d,
                      mode: widget.mode,
                      moves: _model.moves,
                      onBack: () => Navigator.of(context).pop(),
                      onRestart: _handleReplay,
                      onAiSolve: _onAiSolve,
                      accent: _modeAccent,
                    ),

                    const SizedBox(height: 8),
                    _TimerBar(
                      remaining: _remainingSeconds,
                      total: d.timeLimit,
                      accent: _modeAccent,
                    ),

                    const SizedBox(height: 8),
                    _StatsRow(
                      moves: _model.moves,
                      maxMoves: d.moveLimit,
                      seconds: _elapsedSeconds,
                      accent: _modeAccent,
                    ),
                    const SizedBox(height: 12),

                    Expanded(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          child: _PuzzleBoard(
                            model: _model,
                            image: _image,
                            imageLoaded: _imageLoaded,
                            showPreview: _showPreview,
                            onTileTap: _onTileTap,
                            shakeAnim: _shakeAnim,
                            lastInvalidTap: _lastInvalidTap,
                            accent: _modeAccent,
                            screenWidth: size.width - 36,
                          ),
                        ),
                      ),
                    ),

                    if (_model.usePowerups) ...[
                      const SizedBox(height: 12),
                      _PowerUpBar(
                        model: _model,
                        accent: _modeAccent,
                        onPeekStart: _onPeekStart,
                        onPeekEnd: _onPeekEnd,
                        onHint: () {
                          _usedPowerups = true;
                          _model.activateHint();
                        },
                        onAutoMove: () {
                          _usedPowerups = true;
                          _model.activateAutoMove();
                        },
                      ),
                    ],
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // Solved overlay
            AnimatedBuilder(
              animation: _solvedAnim,
              builder: (ctx, _) {
                if (_solvedAnim.value == 0) return const SizedBox.shrink();
                return _SolvedOverlay(
                  progress: _solvedAnim.value,
                  moves: _model.moves,
                  stars: _model.stars,
                  seconds: _elapsedSeconds,
                  difficulty: widget.difficulty,
                  mode: widget.mode,
                  accent: _modeAccent,
                  image: _image,
                  onReplay: () {
                    _ticker?.cancel();
                    _solvedAnim.reset();
                    _gameOverAnim.reset();
                    _elapsedSeconds = 0;
                    _remainingSeconds = widget.difficulty.timeLimit;
                    _timedOut = false;
                    _usedPowerups = false;
                    _model.restart();
                    if (widget.mode == GameMode.timeAttack) _startTimer();
                  },
                  onHome: () => Navigator.of(context).pop(),
                );
              },
            ),

            // Game Over overlay (time attack only)
            AnimatedBuilder(
              animation: _gameOverAnim,
              builder: (ctx, _) {
                if (_gameOverAnim.value == 0) return const SizedBox.shrink();
                return _GameOverOverlay(
                  progress: _gameOverAnim.value,
                  moves: _model.moves,
                  accent: _modeAccent,
                  failReason: _failReason,
                  onReplay: _handleReplay,
                  onHome: () => Navigator.of(context).pop(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ── Top Bar ───────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final Difficulty difficulty;
  final GameMode mode;
  final int moves;
  final VoidCallback onBack, onRestart, onAiSolve;
  final Color accent;

  const _TopBar({
    required this.difficulty,
    required this.mode,
    required this.moves,
    required this.onBack,
    required this.onRestart,
    required this.onAiSolve,
    required this.accent,
  });

  String get _modeLabel {
    switch (mode) {
      case GameMode.timeAttack:
        return 'Time Attack';
      case GameMode.daily:
        return 'Daily';
      case GameMode.classic:
        return 'Classic';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
      child: Row(
        children: [
          _CircleBtn(icon: Icons.arrow_back_ios_new_rounded, onTap: onBack),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${difficulty.label} · $_modeLabel',
                  style: GoogleFonts.luckiestGuy(
                    fontSize: 24,
                    color: Colors.white,
                    letterSpacing: 1.0,
                    shadows: const [
                      Shadow(color: Colors.black, offset: Offset(0, 2)),
                    ],
                  ),
                ),
                Text(
                  '${difficulty.gridSize} × ${difficulty.gridSize} grid',
                  style: GoogleFonts.fredoka(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          _CircleBtn(icon: Icons.smart_toy_rounded, onTap: onAiSolve),
          const SizedBox(width: 8),
          _CircleBtn(icon: Icons.refresh_rounded, onTap: onRestart),
        ],
      ),
    );
  }
}

class _CircleBtn extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final GestureTapDownCallback? onTapDown;
  final GestureTapUpCallback? onTapUp;
  final VoidCallback? onTapCancel;

  const _CircleBtn({
    required this.icon,
    this.onTap,
    this.onTapDown,
    this.onTapUp,
    this.onTapCancel,
    super.key,
  });

  @override
  State<_CircleBtn> createState() => _CircleBtnState();
}

class _CircleBtnState extends State<_CircleBtn> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (d) {
        setState(() => _down = true);
        if (widget.onTapDown != null) widget.onTapDown!(d);
      },
      onTapUp: (d) {
        setState(() => _down = false);
        if (widget.onTapUp != null) widget.onTapUp!(d);
        if (widget.onTap != null) widget.onTap!();
      },
      onTapCancel: () {
        setState(() => _down = false);
        if (widget.onTapCancel != null) widget.onTapCancel!();
      },
      child: AnimatedScale(
        scale: _down ? 0.9 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black87,
            boxShadow: [
              BoxShadow(
                color: Colors.black38,
                offset: Offset(0, 4),
                blurRadius: 2,
              ),
            ],
          ),
          child: Container(
            margin: const EdgeInsets.only(bottom: 4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFE2Eef5), // Silver lip
              border: Border.all(color: const Color(0xFF42566b), width: 1.5),
            ),
            child: Container(
              margin: const EdgeInsets.only(
                bottom: 2,
              ), // Gives spherical 3D shape
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF38B6FF),
                border: Border.all(color: Colors.white, width: 2.5),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Icon(widget.icon, color: Colors.white, size: 24),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Timer Bar ─────────────────────────────────────────────────────────────────

class _TimerBar extends StatelessWidget {
  final int remaining;
  final int total;
  final Color accent;
  const _TimerBar({
    required this.remaining,
    required this.total,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = total > 0 ? remaining / total : 0.0;
    final barColor = ratio > 0.4
        ? T.daily
        : (ratio > 0.2 ? T.duel : T.timeAttack);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
        ),
        child: Row(
          children: [
            Icon(Icons.timer_outlined, size: 16, color: barColor),
            const SizedBox(width: 8),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: ratio.clamp(0.0, 1.0),
                  backgroundColor: Colors.white.withValues(alpha: 0.08),
                  valueColor: AlwaysStoppedAnimation<Color>(barColor),
                  minHeight: 6,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              '$remaining s',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: barColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Stats Row ─────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final int moves;
  final int maxMoves;
  final int seconds;
  final Color accent;
  const _StatsRow({
    required this.moves,
    required this.maxMoves,
    required this.seconds,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    final timeStr =
        '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: [
          Expanded(
            child: _StatPill(
              icon: Icons.swap_horiz_rounded,
              label: '$moves / $maxMoves',
              color: accent,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _StatPill(
              icon: Icons.access_time_rounded,
              label: timeStr,
              color: Colors.white.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _StatPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF265b82), // Deep blue base
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const [
          BoxShadow(color: Colors.black45, offset: Offset(0, 3)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.luckiestGuy(fontSize: 18, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

// ── Power-Up Bar ──────────────────────────────────────────────────────────────

class _PowerUpBar extends StatelessWidget {
  final PuzzleModel model;
  final Color accent;
  final VoidCallback onPeekStart, onPeekEnd, onHint, onAutoMove;

  const _PowerUpBar({
    required this.model,
    required this.accent,
    required this.onPeekStart,
    required this.onPeekEnd,
    required this.onHint,
    required this.onAutoMove,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF265b82), // Deep blue base
          borderRadius: BorderRadius.circular(40),
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: const [
            BoxShadow(color: Colors.black45, offset: Offset(0, 4)),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _PowerBtn(
              icon: Icons.remove_red_eye_outlined,
              count: -1, // -1 hides badge rendering for infinite
              color: T.classic,
              label: 'Peek',
              onTapDown: onPeekStart,
              onTapUp: onPeekEnd,
            ),
            _PowerBtn(
              icon: Icons.lightbulb_outline_rounded,
              count: model.hintLeft,
              color: T.gold,
              label: 'Hint',
              onTap: onHint,
            ),
            _PowerBtn(
              icon: Icons.play_arrow_rounded,
              count: model.autoLeft,
              color: T.daily,
              label: 'Auto',
              onTap: onAutoMove,
            ),
          ],
        ),
      ),
    );
  }
}

class _PowerBtn extends StatefulWidget {
  final IconData icon;
  final int count;
  final Color color;
  final String label;
  final VoidCallback? onTap;
  final VoidCallback? onTapDown;
  final VoidCallback? onTapUp;

  const _PowerBtn({
    required this.icon,
    required this.count,
    required this.color,
    required this.label,
    this.onTap,
    this.onTapDown,
    this.onTapUp,
  });

  @override
  State<_PowerBtn> createState() => _PowerBtnState();
}

class _PowerBtnState extends State<_PowerBtn> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.count != 0;
    return GestureDetector(
      onTapDown: enabled
          ? (_) {
              setState(() => _pressed = true);
              if (widget.onTapDown != null) widget.onTapDown!();
            }
          : null,
      onTapUp: enabled
          ? (_) {
              setState(() => _pressed = false);
              if (widget.onTapUp != null) widget.onTapUp!();
              if (widget.onTap != null) widget.onTap!();
            }
          : null,
      onTapCancel: () {
        setState(() => _pressed = false);
        if (widget.onTapUp != null) widget.onTapUp!();
      },
      child: AnimatedOpacity(
        opacity: enabled ? 1.0 : 0.4,
        duration: const Duration(milliseconds: 200),
        child: AnimatedScale(
          scale: _pressed ? 0.9 : 1.0,
          duration: const Duration(milliseconds: 80),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black87,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black38,
                          offset: Offset(0, 3),
                          blurRadius: 1,
                        ),
                      ],
                    ),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFE2Eef5),
                        border: Border.all(
                          color: const Color(0xFF42566b),
                          width: 1.5,
                        ),
                      ),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: widget.color, // Powerup specific color
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Icon(widget.icon, color: Colors.white, size: 26),
                      ),
                    ),
                  ),
                  if (widget.count >= 0)
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black54,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            '${widget.count}',
                            style: GoogleFonts.luckiestGuy(
                              fontSize: 12,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                widget.label,
                style: GoogleFonts.luckiestGuy(
                  fontSize: 14,
                  color: Colors.white,
                  letterSpacing: 1.0,
                  shadows: const [
                    Shadow(color: Colors.black, offset: Offset(0, 1)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Puzzle Board ──────────────────────────────────────────────────────────────

class _PuzzleBoard extends StatelessWidget {
  final PuzzleModel model;
  final ui.Image? image;
  final bool imageLoaded;
  final bool showPreview;
  final void Function(int) onTileTap;
  final AnimationController shakeAnim;
  final int? lastInvalidTap;
  final Color accent;
  final double screenWidth;

  const _PuzzleBoard({
    required this.model,
    required this.image,
    required this.imageLoaded,
    required this.showPreview,
    required this.onTileTap,
    required this.shakeAnim,
    required this.lastInvalidTap,
    required this.accent,
    required this.screenWidth,
  });

  @override
  Widget build(BuildContext context) {
    final g = model.gridSize;
    final boardSize = screenWidth.clamp(
      0.0,
      MediaQuery.of(context).size.height * 0.55,
    );
    final gap = g <= 3 ? 4.0 : (g == 4 ? 3.0 : 2.5);
    final cellSize = (boardSize - gap * (g + 1)) / g;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: showPreview
          ? _PreviewImage(
              image: image,
              size: boardSize,
              key: const ValueKey('preview'),
            )
          : Container(
              key: const ValueKey('board'),
              width: boardSize,
              height: boardSize,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: const Color(0xFFE2Eef5),
                border: Border.all(color: const Color(0xFF42566b), width: 4),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black38,
                    offset: Offset(0, 8),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30.5),
                child: !imageLoaded
                    ? Center(
                        child: CircularProgressIndicator(
                          color: accent,
                          strokeWidth: 2,
                        ),
                      )
                    : GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        padding: EdgeInsets.all(gap),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: g,
                          crossAxisSpacing: gap,
                          mainAxisSpacing: gap,
                        ),
                        itemCount: model.total,
                        itemBuilder: (_, pos) {
                          final piece = model.tiles[pos];
                          final isEmpty = piece == model.total - 1;
                          final isInPlace = model.inPlace(pos);
                          final isHint = model.hintPos == pos;
                          final isInvalid = lastInvalidTap == pos;
                          return _Tile(
                            key: ValueKey(piece),
                            piece: piece,
                            isEmpty: isEmpty,
                            gridSize: g,
                            image: image,
                            cellSize: cellSize,
                            canMove: model.canMove(pos),
                            isInPlace: isInPlace,
                            isHint: isHint,
                            isInvalid: isInvalid,
                            shakeAnim: isInvalid ? shakeAnim : null,
                            accent: accent,
                            onTap: () => onTileTap(pos),
                          );
                        },
                      ),
              ),
            ),
    );
  }
}

class _PreviewImage extends StatelessWidget {
  final ui.Image? image;
  final double size;
  const _PreviewImage({required this.image, required this.size, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.18),
          width: 2,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(40),
        child: image == null
            ? Container(color: Colors.white10)
            : CustomPaint(
                painter: _FullImagePainter(image!),
                size: Size(size, size),
              ),
      ),
    );
  }
}

class _FullImagePainter extends CustomPainter {
  final ui.Image image;
  _FullImagePainter(this.image);

  @override
  void paint(Canvas canvas, Size size) {
    final src = Rect.fromLTWH(
      0,
      0,
      image.width.toDouble(),
      image.height.toDouble(),
    );
    final dst = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawImageRect(
      image,
      src,
      dst,
      Paint()..filterQuality = FilterQuality.medium,
    );
  }

  @override
  bool shouldRepaint(_FullImagePainter old) => false;
}

// ── Tile ──────────────────────────────────────────────────────────────────────

class _Tile extends StatefulWidget {
  final int piece;
  final bool isEmpty;
  final int gridSize;
  final ui.Image? image;
  final double cellSize;
  final bool canMove;
  final bool isInPlace;
  final bool isHint;
  final bool isInvalid;
  final AnimationController? shakeAnim;
  final Color accent;
  final VoidCallback onTap;

  const _Tile({
    super.key,
    required this.piece,
    required this.isEmpty,
    required this.gridSize,
    required this.image,
    required this.cellSize,
    required this.canMove,
    required this.isInPlace,
    required this.isHint,
    required this.isInvalid,
    required this.shakeAnim,
    required this.accent,
    required this.onTap,
  });

  @override
  State<_Tile> createState() => _TileState();
}

class _TileState extends State<_Tile> with SingleTickerProviderStateMixin {
  bool _pressed = false;
  late AnimationController _hintAnim;

  @override
  void initState() {
    super.initState();
    _hintAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    if (widget.isHint) _hintAnim.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_Tile old) {
    super.didUpdateWidget(old);
    if (widget.isHint && !old.isHint) {
      _hintAnim.repeat(reverse: true);
    } else if (!widget.isHint && old.isHint) {
      _hintAnim.stop();
      _hintAnim.reset();
    }
  }

  @override
  void dispose() {
    _hintAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(widget.gridSize <= 3 ? 12 : 8),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.06),
            width: 1,
          ),
        ),
      );
    }

    final radius = widget.gridSize <= 3 ? 12.0 : 8.0;

    Widget tile = GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed && widget.canMove ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOut,
        child: AnimatedBuilder(
          animation: _hintAnim,
          builder: (ctx, child) {
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(radius),
                border: widget.isHint
                    ? Border.all(
                        color: T.gold.withValues(
                          alpha: 0.5 + 0.5 * _hintAnim.value,
                        ),
                        width: 2,
                      )
                    : widget.isInPlace
                    ? Border.all(
                        color: widget.accent.withValues(alpha: 0.5),
                        width: 1.5,
                      )
                    : null,
                boxShadow: widget.isHint
                    ? [
                        BoxShadow(
                          color: T.gold.withValues(
                            alpha: 0.4 * _hintAnim.value,
                          ),
                          blurRadius: 12,
                          spreadRadius: -2,
                        ),
                      ]
                    : widget.isInPlace
                    ? [
                        BoxShadow(
                          color: widget.accent.withValues(alpha: 0.2),
                          blurRadius: 8,
                          spreadRadius: -3,
                        ),
                      ]
                    : null,
              ),
              child: child,
            );
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(radius - 1),
            child: widget.image != null
                ? CustomPaint(
                    painter: _TilePainter(
                      image: widget.image!,
                      piece: widget.piece,
                      gridSize: widget.gridSize,
                      dimmed: !widget.isInPlace,
                    ),
                    size: Size(widget.cellSize, widget.cellSize),
                  )
                : _TilePlaceholder(
                    piece: widget.piece,
                    gridSize: widget.gridSize,
                    accent: widget.accent,
                    isInPlace: widget.isInPlace,
                  ),
          ),
        ),
      ),
    );

    if (widget.shakeAnim != null) {
      tile = AnimatedBuilder(
        animation: widget.shakeAnim!,
        builder: (_, child) {
          final s = sin(widget.shakeAnim!.value * pi * 5);
          return Transform.translate(offset: Offset(s * 4, 0), child: child);
        },
        child: tile,
      );
    }

    return tile;
  }
}

class _TilePainter extends CustomPainter {
  final ui.Image image;
  final int piece;
  final int gridSize;
  final bool dimmed;
  const _TilePainter({
    required this.image,
    required this.piece,
    required this.gridSize,
    required this.dimmed,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final row = piece ~/ gridSize;
    final col = piece % gridSize;
    final iW = image.width.toDouble();
    final iH = image.height.toDouble();
    final srcW = iW / gridSize;
    final srcH = iH / gridSize;
    final src = Rect.fromLTWH(col * srcW, row * srcH, srcW, srcH);
    final dst = Rect.fromLTWH(0, 0, size.width, size.height);

    final paint = Paint()..filterQuality = FilterQuality.medium;
    if (dimmed) {
      paint.colorFilter = const ColorFilter.matrix([
        0.17,
        0.57,
        0.06,
        0,
        -50,
        0.17,
        0.57,
        0.06,
        0,
        -50,
        0.17,
        0.57,
        0.06,
        0,
        -50,
        0,
        0,
        0,
        1,
        0,
      ]);
    }
    canvas.drawImageRect(image, src, dst, paint);
  }

  @override
  bool shouldRepaint(_TilePainter old) =>
      old.piece != piece || old.gridSize != gridSize || old.dimmed != dimmed;
}

class _TilePlaceholder extends StatelessWidget {
  final int piece;
  final int gridSize;
  final Color accent;
  final bool isInPlace;
  const _TilePlaceholder({
    required this.piece,
    required this.gridSize,
    required this.accent,
    required this.isInPlace,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isInPlace
              ? [accent.withValues(alpha: 0.4), accent.withValues(alpha: 0.15)]
              : [
                  Colors.white.withValues(alpha: 0.08),
                  Colors.white.withValues(alpha: 0.03),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          '${piece + 1}',
          style: TextStyle(
            color: isInPlace ? accent : Colors.white.withValues(alpha: 0.4),
            fontWeight: FontWeight.w700,
            fontSize: gridSize <= 3 ? 22 : 14,
          ),
        ),
      ),
    );
  }
}

// ── Solved Overlay ────────────────────────────────────────────────────────────

class _SolvedOverlay extends StatefulWidget {
  final double progress;
  final int moves, stars, seconds;
  final Difficulty difficulty;
  final GameMode mode;
  final Color accent;
  final ui.Image? image;
  final VoidCallback onReplay, onHome;

  const _SolvedOverlay({
    required this.progress,
    required this.moves,
    required this.stars,
    required this.seconds,
    required this.difficulty,
    required this.mode,
    required this.accent,
    required this.image,
    required this.onReplay,
    required this.onHome,
  });

  @override
  State<_SolvedOverlay> createState() => _SolvedOverlayState();
}

class _SolvedOverlayState extends State<_SolvedOverlay>
    with TickerProviderStateMixin {
  final List<AnimationController> _starAnims = [];
  late AnimationController _confettiAnim;
  final _rng = Random();

  @override
  void initState() {
    super.initState();
    _confettiAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    for (var i = 0; i < 3; i++) {
      final ctrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 400),
      );
      _starAnims.add(ctrl);
      Future.delayed(Duration(milliseconds: 300 + i * 150), () {
        if (mounted) ctrl.forward();
      });
    }
  }

  @override
  void dispose() {
    _confettiAnim.dispose();
    for (final a in _starAnims) {
      a.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.seconds ~/ 60;
    final s = widget.seconds % 60;
    final timeStr =
        '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';

    return BackdropFilter(
      filter: ui.ImageFilter.blur(
        sigmaX: 20 * widget.progress,
        sigmaY: 20 * widget.progress,
      ),
      child: Opacity(
        opacity: widget.progress,
        child: Stack(
          children: [
            // Dark overlay
            Container(color: Colors.black.withValues(alpha: 0.55)),

            // Confetti
            AnimatedBuilder(
              animation: _confettiAnim,
              builder: (ctx, _) {
                return CustomPaint(
                  painter: _ConfettiPainter(
                    progress: _confettiAnim.value,
                    rng: _rng,
                    accent: widget.accent,
                  ),
                  size: Size.infinite,
                );
              },
            ),

            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Transform.scale(
                  scale: 0.85 + 0.15 * widget.progress,
                  child: GlassCard(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Image thumbnail
                        if (widget.image != null)
                          Container(
                            width: 130,
                            height: 130,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: widget.accent.withValues(alpha: 0.5),
                                width: 3,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black45,
                                  offset: Offset(0, 4),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: CustomPaint(
                                painter: _FullImagePainter(widget.image!),
                                size: const Size(130, 130),
                              ),
                            ),
                          ),
                        const SizedBox(height: 20),

                        // Stars (Flames replacement visually - wait, earlier we kept stars here)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(3, (i) {
                            final lit = i < widget.stars;
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              child: AnimatedBuilder(
                                animation: i < _starAnims.length
                                    ? _starAnims[i]
                                    : _confettiAnim,
                                builder: (ctx, _) {
                                  final v = i < _starAnims.length
                                      ? _starAnims[i].value
                                      : 0.0;
                                  return Transform.scale(
                                    scale: 0.5 + 0.5 * v,
                                    child: Icon(
                                      lit
                                          ? Icons.local_fire_department_rounded
                                          : Icons
                                                .local_fire_department_outlined,
                                      color: lit
                                          ? T.gold
                                          : Colors.white.withValues(alpha: 0.2),
                                      size: 44,
                                    ),
                                  );
                                },
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 16),

                        Text(
                          'PUZZLE SOLVED!',
                          style: GoogleFonts.luckiestGuy(
                            fontSize: 32,
                            color: Colors.white,
                            letterSpacing: 2.0,
                            shadows: const [
                              Shadow(
                                color: Colors.black54,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Stats row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _MiniStat(
                              icon: Icons.swap_horiz_rounded,
                              value: '${widget.moves}',
                              label: 'moves',
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                            const SizedBox(width: 24),
                            _MiniStat(
                              icon: Icons.access_time_rounded,
                              value: timeStr,
                              label: 'time',
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),

                        Row(
                          children: [
                            GestureDetector(
                              onTap: widget.onHome,
                              child: Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF6C7A89),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 3,
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black45,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.home_rounded,
                                    color: Colors.white,
                                    size: 34,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            GestureDetector(
                              onTap: widget.onReplay,
                              child: Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  color: T.timeAttack,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 3,
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black45,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.refresh_rounded,
                                    color: Colors.white,
                                    size: 36,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.of(context).pushReplacement(
                                    PageRouteBuilder(
                                      transitionDuration: const Duration(
                                        milliseconds: 300,
                                      ),
                                      pageBuilder: (ctx, a, sec) => GameScreen(
                                        difficulty: widget.difficulty,
                                        imageUrl:
                                            'https://picsum.photos/seed/${DateTime.now().millisecondsSinceEpoch}/800/800',
                                        mode: widget.mode,
                                        seed: DateTime.now()
                                            .millisecondsSinceEpoch,
                                      ),
                                    ),
                                  );
                                },
                                child: Container(
                                  height: 64,
                                  decoration: BoxDecoration(
                                    color: T.daily, // Green for NEXT
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 3,
                                    ),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black45,
                                        offset: Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.skip_next_rounded,
                                        color: Colors.white,
                                        size: 32,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'NEXT',
                                        style: GoogleFonts.luckiestGuy(
                                          fontSize: 26,
                                          color: Colors.white,
                                          letterSpacing: 1.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String value, label;
  final Color color;
  const _MiniStat({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 24, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.fredoka(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.fredoka(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
}

// ── Confetti painter ──────────────────────────────────────────────────────────

class _ConfettiPainter extends CustomPainter {
  final double progress;
  final Random rng;
  final Color accent;
  static const _count = 20;

  _ConfettiPainter({
    required this.progress,
    required this.rng,
    required this.accent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final seed = 42;
    final r = Random(seed);
    final colors = [
      accent,
      T.gold,
      T.daily,
      T.timeAttack,
      T.custom,
      Colors.white,
    ];
    for (var i = 0; i < _count; i++) {
      final startX = r.nextDouble() * size.width;
      final speed = 0.3 + r.nextDouble() * 0.7;
      final phase = r.nextDouble();
      final t = (progress + phase) % 1.0;
      final x = startX + sin(t * pi * 2 + i.toDouble()) * 30;
      final y = t * speed * size.height * 1.2 - 20;
      final color = colors[i % colors.length];
      final paint = Paint()..color = color.withValues(alpha: (1 - t) * 0.9);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(t * pi * 4);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: 8, height: 4),
          const Radius.circular(2),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.progress != progress;
}

// ── Game Over Overlay ─────────────────────────────────────────────────────────

class _GameOverOverlay extends StatelessWidget {
  final double progress;
  final int moves;
  final Color accent;
  final String failReason;
  final VoidCallback onReplay, onHome;

  const _GameOverOverlay({
    required this.progress,
    required this.moves,
    required this.accent,
    required this.failReason,
    required this.onReplay,
    required this.onHome,
  });

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ui.ImageFilter.blur(sigmaX: 18 * progress, sigmaY: 18 * progress),
      child: Opacity(
        opacity: progress,
        child: Container(
          color: Colors.black.withValues(alpha: 0.65),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Transform.scale(
                scale: 0.85 + 0.15 * progress,
                child: GlassCard(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: T.timeAttack.withValues(alpha: 0.15),
                          border: Border.all(
                            color: T.timeAttack.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Icon(
                          failReason.contains('Moves')
                              ? Icons.pan_tool_rounded
                              : Icons.timer_off_rounded,
                          color: T.timeAttack,
                          size: 34,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        failReason.isNotEmpty
                            ? failReason.toUpperCase()
                            : "GAME OVER!",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.luckiestGuy(
                          fontSize: 32,
                          color: Colors.white,
                          letterSpacing: 2.0,
                          shadows: const [
                            Shadow(color: Colors.black, offset: Offset(0, 3)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$moves moves made',
                        style: GoogleFonts.fredoka(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Builder(
                        builder: (ctx) {
                          final app = ctx.watch<AppState>();
                          final hasHearts = app.triesLeft > 0;
                          final canAfford = app.flames >= 5;
                          return Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () async {
                                    await ctx.read<AppState>().watchAdForTry();
                                    if (ctx.mounted) {
                                      onReplay();
                                    }
                                  },
                                  child: Container(
                                    height: 90,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF38B6FF),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 3,
                                      ),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Colors.black45,
                                          offset: Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.smart_display_rounded,
                                          color: Colors.white,
                                          size: 36,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'WATCH',
                                          style: GoogleFonts.luckiestGuy(
                                            fontSize: 18,
                                            color: Colors.white,
                                            letterSpacing: 1.0,
                                            shadows: const [
                                              Shadow(
                                                color: Colors.black54,
                                                offset: Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: GestureDetector(
                                  onTap: canAfford
                                      ? () async {
                                          await ctx
                                              .read<AppState>()
                                              .spendFlames(5);
                                          if (ctx.mounted) {
                                            onReplay();
                                          }
                                        }
                                      : null,
                                  child: Container(
                                    height: 90,
                                    decoration: BoxDecoration(
                                      color: canAfford
                                          ? const Color(0xFFFF5722)
                                          : Colors.grey.withValues(alpha: 0.4),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: Colors.white.withValues(
                                          alpha: canAfford ? 1.0 : 0.5,
                                        ),
                                        width: 3,
                                      ),
                                      boxShadow: canAfford
                                          ? const [
                                              BoxShadow(
                                                color: Colors.black45,
                                                offset: Offset(0, 4),
                                              ),
                                            ]
                                          : null,
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.local_fire_department_rounded,
                                          color: Colors.white.withValues(
                                            alpha: canAfford ? 1.0 : 0.5,
                                          ),
                                          size: 36,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '- 5',
                                          style: GoogleFonts.luckiestGuy(
                                            fontSize: 18,
                                            color: Colors.white.withValues(
                                              alpha: canAfford ? 1.0 : 0.5,
                                            ),
                                            shadows: canAfford
                                                ? const [
                                                    Shadow(
                                                      color: Colors.black54,
                                                      offset: Offset(0, 2),
                                                    ),
                                                  ]
                                                : null,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: GestureDetector(
                                  onTap: hasHearts ? onReplay : null,
                                  child: Container(
                                    height: 90,
                                    decoration: BoxDecoration(
                                      color: hasHearts
                                          ? T.timeAttack
                                          : Colors.grey.withValues(alpha: 0.4),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: Colors.white.withValues(
                                          alpha: hasHearts ? 1.0 : 0.5,
                                        ),
                                        width: 3,
                                      ),
                                      boxShadow: hasHearts
                                          ? const [
                                              BoxShadow(
                                                color: Colors.black45,
                                                offset: Offset(0, 4),
                                              ),
                                            ]
                                          : null,
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.refresh_rounded,
                                          color: Colors.white.withValues(
                                            alpha: hasHearts ? 1.0 : 0.5,
                                          ),
                                          size: 36,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'RETRY',
                                          style: GoogleFonts.luckiestGuy(
                                            fontSize: 18,
                                            color: Colors.white.withValues(
                                              alpha: hasHearts ? 1.0 : 0.5,
                                            ),
                                            shadows: hasHearts
                                                ? const [
                                                    Shadow(
                                                      color: Colors.black54,
                                                      offset: Offset(0, 2),
                                                    ),
                                                  ]
                                                : null,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 14),
                      GestureDetector(
                        onTap: onHome,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF38B6FF),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black45,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              'MAIN MENU',
                              style: GoogleFonts.luckiestGuy(
                                fontSize: 24,
                                color: Colors.white,
                                letterSpacing: 1.5,
                                shadows: const [
                                  Shadow(
                                    color: Colors.black54,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RuleItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String value;
  const _RuleItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2), // Dark inset
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.fredoka(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.luckiestGuy(
              fontSize: 24,
              color: color,
              shadows: const [
                Shadow(color: Colors.black54, offset: Offset(0, 2)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
