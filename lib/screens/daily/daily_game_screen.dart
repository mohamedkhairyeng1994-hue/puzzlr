import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:confetti/confetti.dart';

import '../../core/app_state.dart';
import '../../core/theme.dart';
import '../../models/puzzle_model.dart';

// ══════════════════════════════════════════════════════════════════════════════
//  DailyGameScreen
// ══════════════════════════════════════════════════════════════════════════════

class DailyGameScreen extends StatefulWidget {
  final Difficulty difficulty;
  final String imageUrl;
  final int seed;

  const DailyGameScreen({
    super.key,
    required this.difficulty,
    required this.imageUrl,
    required this.seed,
  });

  @override
  State<DailyGameScreen> createState() => _DailyGameScreenState();
}

class _DailyGameScreenState extends State<DailyGameScreen>
    with TickerProviderStateMixin {
  late PuzzleModel _model;
  ui.Image? _image;
  bool _imageLoaded = false;
  bool _showPreview = false;

  // Timer
  Timer? _ticker;
  int _elapsedSeconds = 0;

  late AnimationController _solvedAnim;
  late AnimationController _shakeAnim;
  late ConfettiController _confetti;
  int? _lastInvalidTap;

  @override
  void initState() {
    super.initState();
    _model = PuzzleModel(
      difficulty: widget.difficulty,
      seed: widget.seed,
      usePowerups: true,
    );
    _model.addListener(_onModelUpdated);

    _solvedAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _shakeAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _confetti = ConfettiController(duration: const Duration(seconds: 3));

    _loadImage();

    // Start game immediately as requested (No objective dialog)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startTimer();
    });
  }

  void _onModelUpdated() {
    if (_solvedAnim.isAnimating || _solvedAnim.value > 0) return;
    if (_model.solved) {
      _ticker?.cancel();
      HapticFeedback.heavyImpact();
      _confetti.play();
      _recordSolve();
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) _solvedAnim.forward();
      });
    }
  }

  void _startTimer() {
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _model.solved) return;
      setState(() => _elapsedSeconds++);
    });
  }

  Future<void> _loadImage() async {
    try {
      final provider = NetworkImage(widget.imageUrl);
      final stream = provider.resolve(ImageConfiguration.empty);
      stream.addListener(ImageStreamListener((info, _) {
        if (!mounted) return;
        setState(() {
          _image = info.image;
          _imageLoaded = true;
        });
      }, onError: (e, s) {
        if (!mounted) return;
        setState(() => _imageLoaded = true);
      }));
    } catch (_) {
      if (mounted) setState(() => _imageLoaded = true);
    }
  }

  void _onTileTap(int pos) {
    if (_model.solved) return;
    if (_model.canMove(pos)) {
      _model.tap(pos);
    } else {
      setState(() => _lastInvalidTap = pos);
      _shakeAnim.forward(from: 0).then((_) {
        if (mounted) setState(() => _lastInvalidTap = null);
      });
    }
  }

  void _recordSolve() {
    context.read<AppState>().recordDailyStage(
          d: widget.difficulty,
          moves: _model.moves,
          seconds: _elapsedSeconds,
        );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _solvedAnim.dispose();
    _shakeAnim.dispose();
    _confetti.dispose();
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
              child: Column(
                children: [
                  // ── Daily Header ───────────────────────────────────────────
                  _DailyHeader(
                    difficulty: d,
                    onBack: () => Navigator.of(context).pop(),
                    onAiSolve: () => _model.forceSolve(),
                  ),

                  const SizedBox(height: 12),

                  // ── Live Stats ─────────────────────────────────────────────
                  _LiveStats(
                    moves: _model.moves,
                    seconds: _elapsedSeconds,
                  ),

                  const SizedBox(height: 16),

                  // ── Puzzle Board ───────────────────────────────────────────
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: ListenableBuilder(
                          listenable: _model,
                          builder: (ctx, _) => _PuzzleBoard(
                            model: _model,
                            image: _image,
                            imageLoaded: _imageLoaded,
                            showPreview: _showPreview,
                            onTileTap: _onTileTap,
                            shakeAnim: _shakeAnim,
                            lastInvalidTap: _lastInvalidTap,
                            accent: T.daily,
                            screenWidth: size.width - 40,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Controls ───────────────────────────────────────────────
                  ListenableBuilder(
                    listenable: _model,
                    builder: (context, _) => _DailyControls(
                      model: _model,
                      onPeekStart: () => setState(() => _showPreview = true),
                      onPeekEnd: () => setState(() => _showPreview = false),
                      onHint: () => _model.activateHint(),
                      onAutoMove: () => _model.activateAutoMove(),
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),

            // Confetti
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confetti,
                blastDirectionality: BlastDirectionality.explosive,
                colors: const [T.daily, T.gold, Colors.white],
                shouldLoop: false,
              ),
            ),

            // Solved Overlay (Daily Specific)
            AnimatedBuilder(
              animation: _solvedAnim,
              builder: (ctx, _) {
                if (_solvedAnim.value == 0) return const SizedBox.shrink();
                return _DailySolvedOverlay(
                  progress: _solvedAnim.value,
                  moves: _model.moves,
                  seconds: _elapsedSeconds,
                  difficulty: widget.difficulty,
                  onNext: () => Navigator.of(context).pop(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  Internal Widgets
// ══════════════════════════════════════════════════════════════════════════════

class _DailyHeader extends StatelessWidget {
  final Difficulty difficulty;
  final VoidCallback onBack;
  final VoidCallback onAiSolve;

  const _DailyHeader({
    required this.difficulty,
    required this.onBack,
    required this.onAiSolve,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          _CircleButton(
            icon: Icons.close_rounded,
            onTap: onBack,
            color: const Color(0xFF1E5279),
          ),
          const Expanded(
            child: Column(
              children: [
                _HeaderTitle(),
              ],
            ),
          ),
          _CircleButton(
            icon: Icons.smart_toy_rounded,
            onTap: onAiSolve,
            color: T.daily,
          ),
          const SizedBox(width: 8),
          _StageBadge(difficulty: difficulty),
        ],
      ),
    );
  }
}

class _HeaderTitle extends StatelessWidget {
  const _HeaderTitle();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'DAILY',
          style: GoogleFonts.luckiestGuy(
            fontSize: 22,
            color: T.daily,
            letterSpacing: 2,
            shadows: [
              const Shadow(color: Colors.black45, offset: Offset(0, 2))
            ],
          ),
        ),
        Text(
          'PUZZLE',
          style: GoogleFonts.luckiestGuy(
            fontSize: 16,
            color: Colors.white70,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}

class _StageBadge extends StatelessWidget {
  final Difficulty difficulty;
  const _StageBadge({required this.difficulty});

  @override
  Widget build(BuildContext context) {
    final colors = [T.classic, T.gold, T.timeAttack];
    final labels = ['EASY', 'MED', 'HARD'];
    final color = colors[difficulty.index];
    final label = labels[difficulty.index];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.6), width: 2),
      ),
      child: Text(
        label,
        style: GoogleFonts.luckiestGuy(
          color: color,
          fontSize: 16,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _LiveStats extends StatelessWidget {
  final int moves;
  final int seconds;

  const _LiveStats({required this.moves, required this.seconds});

  @override
  Widget build(BuildContext context) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _StatItem(
            icon: Icons.pan_tool_rounded, value: '$moves', label: 'MOVES'),
        const SizedBox(width: 40),
        _StatItem(icon: Icons.timer_rounded, value: '$m:$s', label: 'TIME'),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: T.gold, size: 18),
            const SizedBox(width: 6),
            Text(
              value,
              style: GoogleFonts.luckiestGuy(
                fontSize: 24,
                color: Colors.white,
              ),
            ),
          ],
        ),
        Text(
          label,
          style: GoogleFonts.fredoka(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Colors.white54,
            letterSpacing: 1.5,
          ),
        ),
      ],
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
                borderRadius: BorderRadius.circular(20), // Adjusted for inner grid
                child: !imageLoaded
                    ? Center(
                        child: CircularProgressIndicator(
                          color: T.daily,
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
  _TilePainter({
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
        0.17, 0.57, 0.06, 0, -50,
        0.17, 0.57, 0.06, 0, -50,
        0.17, 0.57, 0.06, 0, -50,
        0, 0, 0, 1, 0,
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

class _DailyControls extends StatelessWidget {
  final PuzzleModel model;
  final VoidCallback onPeekStart;
  final VoidCallback onPeekEnd;
  final VoidCallback onHint;
  final VoidCallback onAutoMove;

  const _DailyControls({
    required this.model,
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
              count: -1, // Infinite peek in daily
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
                    width: 50,
                    height: 50,
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
                          color: widget.color,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Icon(widget.icon, color: Colors.white, size: 22),
                      ),
                    ),
                  ),
                  if (widget.count >= 0)
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: Center(
                          child: Text(
                            '${widget.count}',
                            style: GoogleFonts.luckiestGuy(
                              fontSize: 10,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                widget.label,
                style: GoogleFonts.luckiestGuy(
                  fontSize: 12,
                  color: Colors.white,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CircleButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  const _CircleButton({
    required this.icon,
    required this.onTap,
    required this.color,
  });

  @override
  State<_CircleButton> createState() => _CircleButtonState();
}

class _CircleButtonState extends State<_CircleButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) {
        setState(() => _down = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _down = false),
      child: AnimatedScale(
        scale: _down ? 0.9 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: 44,
          height: 44,
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
            margin: const EdgeInsets.only(bottom: 3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFE2Eef5),
              border: Border.all(color: const Color(0xFF42566b), width: 1.5),
            ),
            child: Container(
              margin: const EdgeInsets.only(bottom: 2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Icon(widget.icon, color: Colors.white, size: 20),
            ),
          ),
        ),
      ),
    );
  }
}

class _DailySolvedOverlay extends StatelessWidget {
  final double progress;
  final int moves;
  final int seconds;
  final Difficulty difficulty;
  final VoidCallback onNext;

  const _DailySolvedOverlay({
    required this.progress,
    required this.moves,
    required this.seconds,
    required this.difficulty,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    final opacity = progress.clamp(0.0, 1.0);

    return Container(
      color: Colors.black.withValues(alpha: 0.85 * opacity),
      child: Center(
        child: Transform.scale(
          scale: 0.8 + 0.2 * progress,
          child: Opacity(
            opacity: opacity,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'STAGE COMPLETE!',
                  style: GoogleFonts.luckiestGuy(
                    fontSize: 40,
                    color: T.daily,
                    letterSpacing: 2,
                    shadows: [
                      const Shadow(color: Colors.black, offset: Offset(0, 4))
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                _ResultRow(label: 'MOVES', value: '$moves', color: T.gold),
                const SizedBox(height: 16),
                _ResultRow(label: 'TIME', value: '$m:$s', color: T.classic),
                const SizedBox(height: 48),
                GestureDetector(
                  onTap: onNext,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 48, vertical: 18),
                    decoration: BoxDecoration(
                      color: T.daily,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: const [
                        BoxShadow(color: Colors.black45, offset: Offset(0, 6))
                      ],
                    ),
                    child: Text(
                      'CONTINUE',
                      style: GoogleFonts.luckiestGuy(
                        fontSize: 28,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _ResultRow({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12, width: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.fredoka(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white60,
              letterSpacing: 1.5,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.luckiestGuy(
              fontSize: 28,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
