import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/app_state.dart';
import '../../core/theme.dart';
import '../../models/puzzle_model.dart';

class DuelGameScreen extends StatefulWidget {
  final Difficulty difficulty;

  const DuelGameScreen({
    super.key,
    required this.difficulty,
  });

  @override
  State<DuelGameScreen> createState() => _DuelGameScreenState();
}

class _DuelGameScreenState extends State<DuelGameScreen>
    with TickerProviderStateMixin {
  late PuzzleModel _model1;
  late PuzzleModel _model2;
  ui.Image? _image;
  bool _imageLoaded = false;
  final int _seed = Random().nextInt(999999);

  late AnimationController _winnerAnim;
  late AnimationController _shakeAnim1;
  late AnimationController _shakeAnim2;
  int? _lastInvalidTap1;
  int? _lastInvalidTap2;
  int _winner = 0; // 0: none, 1: player 1, 2: player 2

  @override
  void initState() {
    super.initState();
    _model1 = PuzzleModel(
      difficulty: widget.difficulty,
      seed: _seed,
      usePowerups: false, // No powerups in local duel for fairness
    );
    _model2 = PuzzleModel(
      difficulty: widget.difficulty,
      seed: _seed,
      usePowerups: false,
    );

    _model1.addListener(() => _checkWinner(1));
    _model2.addListener(() => _checkWinner(2));

    _winnerAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _shakeAnim1 = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _shakeAnim2 = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));

    _loadImage();
  }

  void _checkWinner(int player) {
    if (_winner != 0) return;
    final model = player == 1 ? _model1 : _model2;
    if (model.solved) {
      setState(() => _winner = player);
      HapticFeedback.heavyImpact();
      _winnerAnim.forward();
      // Record win if it's considered a profile stat
      if (player == 2) {
         // Assuming Player 2 is "the user" or just recording a generic duel win
         context.read<AppState>().recordDuelWin();
      }
    }
  }

  void _confirmExit(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (ctx, anim1, anim2) => const SizedBox(),
      transitionBuilder: (ctx, anim1, anim2, child) {
        final scale = 0.8 + 0.2 * Curves.easeOutBack.transform(anim1.value);
        return Opacity(
          opacity: anim1.value,
          child: Transform.scale(
            scale: scale,
            child: _DuelExitDialog(
              onCancel: () => Navigator.pop(ctx),
              onExit: () {
                Navigator.pop(ctx);
                Navigator.of(context).pop();
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _loadImage() async {
    final imgUrl = 'https://picsum.photos/seed/$_seed/800/800';
    try {
      final provider = NetworkImage(imgUrl);
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

  @override
  void dispose() {
    _winnerAnim.dispose();
    _shakeAnim1.dispose();
    _shakeAnim2.dispose();
    super.dispose();
  }

  void _onTileTap(int player, int pos) {
    if (_winner != 0) return;
    final model = player == 1 ? _model1 : _model2;
    if (model.canMove(pos)) {
      model.tap(pos);
    } else {
      if (player == 1) {
        setState(() => _lastInvalidTap1 = pos);
        _shakeAnim1.forward(from: 0).then((_) {
          if (mounted) setState(() => _lastInvalidTap1 = null);
        });
      } else {
        setState(() => _lastInvalidTap2 = pos);
        _shakeAnim2.forward(from: 0).then((_) {
          if (mounted) setState(() => _lastInvalidTap2 = null);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Column(
            children: [
              // Player 1 (Top) - Rotated
              Expanded(
                child: RotatedBox(
                  quarterTurns: 2,
                  child: _DuelField(
                    playerNum: 1,
                    model: _model1,
                    image: _image,
                    imageLoaded: _imageLoaded,
                    isWinner: _winner == 1,
                    isGameOver: _winner != 0,
                    shakeAnim: _shakeAnim1,
                    lastInvalidTap: _lastInvalidTap1,
                    onTileTap: (pos) => _onTileTap(1, pos),
                  ),
                ),
              ),

              // Middle Divider
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    height: 6,
                    color: T.duel.withValues(alpha: 0.5),
                    child: Center(
                      child: Container(
                        width: 80,
                        height: 6,
                        color: T.duel,
                      ),
                    ),
                  ),
                  _ExitButton(onTap: () => _confirmExit(context)),
                ],
              ),

              // Player 2 (Bottom)
              Expanded(
                child: _DuelField(
                  playerNum: 2,
                  model: _model2,
                  image: _image,
                  imageLoaded: _imageLoaded,
                  isWinner: _winner == 2,
                  isGameOver: _winner != 0,
                  shakeAnim: _shakeAnim2,
                  lastInvalidTap: _lastInvalidTap2,
                  onTileTap: (pos) => _onTileTap(2, pos),
                ),
              ),
            ],
          ),

          // Winner Overlay
          if (_winner != 0)
            _DuelResultOverlay(
              winner: _winner,
              progress: _winnerAnim,
              onHome: () => Navigator.of(context).pop(),
              onRematch: () {
                 Navigator.of(context).pushReplacement(
                   MaterialPageRoute(builder: (_) => DuelGameScreen(difficulty: widget.difficulty))
                 );
              },
            ),
        ],
      ),
    );
  }
}

class _DuelField extends StatelessWidget {
  final int playerNum;
  final PuzzleModel model;
  final ui.Image? image;
  final bool imageLoaded;
  final bool isWinner;
  final bool isGameOver;
  final AnimationController shakeAnim;
  final int? lastInvalidTap;
  final void Function(int) onTileTap;

  const _DuelField({
    required this.playerNum,
    required this.model,
    required this.image,
    required this.imageLoaded,
    required this.isWinner,
    required this.isGameOver,
    required this.shakeAnim,
    required this.lastInvalidTap,
    required this.onTileTap,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final boardSize = min(size.width * 0.85, size.height * 0.35);

    return Container(
      width: double.infinity,
      color: isWinner ? T.duel.withValues(alpha: 0.05) : Colors.transparent,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            isWinner ? 'WINNER!' : 'PLAYER $playerNum',
            style: GoogleFonts.luckiestGuy(
              fontSize: 24,
              color: isWinner ? T.duel : (isGameOver ? Colors.white24 : Colors.white70),
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 12),
          Opacity(
            opacity: isGameOver && !isWinner ? 0.3 : 1.0,
            child: _PuzzleBoard(
              model: model,
              image: image,
              imageLoaded: imageLoaded,
              showPreview: false,
              onTileTap: onTileTap,
              shakeAnim: shakeAnim,
              lastInvalidTap: lastInvalidTap,
              accent: T.duel,
              screenWidth: boardSize,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${model.moves} MOVES',
            style: GoogleFonts.fredoka(
              fontSize: 14,
              color: Colors.white54,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
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
    final boardSize = screenWidth;
    final gap = g <= 3 ? 3.0 : (g == 4 ? 2.5 : 2.0);
    final cellSize = (boardSize - gap * (g + 1)) / g;

    return ListenableBuilder(
      listenable: model,
      builder: (context, _) => AnimatedSwitcher(
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
                  borderRadius: BorderRadius.circular(16),
                  color: const Color(0xFFE2Eef5),
                  border: Border.all(color: const Color(0xFF42566b), width: 4),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black38,
                      offset: Offset(0, 4),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
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
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.18),
          width: 2,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
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
          borderRadius: BorderRadius.circular(widget.gridSize <= 3 ? 10 : 6),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.06),
            width: 1,
          ),
        ),
      );
    }

    final radius = widget.gridSize <= 3 ? 10.0 : 6.0;

    Widget tile = GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTap: () {
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
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
            child: Container(
              margin: const EdgeInsets.only(bottom: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFE2Eef5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF42566b), width: 1),
              ),
              child: Container(
                margin: const EdgeInsets.only(bottom: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF38B6FF),
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
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
                      : Center(
                          child: Text(
                            '${widget.piece + 1}',
                            style: GoogleFonts.luckiestGuy(
                              fontSize: widget.cellSize * 0.4,
                              color: Colors.white,
                            ),
                          ),
                        ),
                ),
              ),
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

// ── Result Overlay ────────────────────────────────────────────────────────────

class _DuelResultOverlay extends StatelessWidget {
  final int winner;
  final Animation<double> progress;
  final VoidCallback onHome, onRematch;

  const _DuelResultOverlay({
    required this.winner,
    required this.progress,
    required this.onHome,
    required this.onRematch,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: progress,
      builder: (context, child) {
        final val = progress.value;
        return Stack(
          children: [
            Container(color: Colors.black.withValues(alpha: 0.7 * val)),
            Center(
              child: Transform.scale(
                scale: 0.8 + 0.2 * val,
                child: Opacity(
                  opacity: val,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                        decoration: BoxDecoration(
                          color: T.duel,
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(color: Colors.white, width: 4),
                          boxShadow: const [
                            BoxShadow(color: Colors.black45, offset: Offset(0, 8)),
                          ],
                        ),
                        child: Column(
                          children: [
                            Text(
                              'MATCH OVER',
                              style: GoogleFonts.luckiestGuy(
                                fontSize: 24,
                                color: Colors.black54,
                                letterSpacing: 1.5,
                              ),
                            ),
                            Text(
                              'PLAYER $winner WINS!',
                              style: GoogleFonts.luckiestGuy(
                                fontSize: 42,
                                color: Colors.white,
                                letterSpacing: 2,
                                shadows: [
                                  const Shadow(color: Colors.black26, offset: Offset(0, 4)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 48),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                           _OverlayBtn(icon: Icons.home_rounded, label: 'HOME', onTap: onHome),
                           const SizedBox(width: 24),
                           _OverlayBtn(icon: Icons.refresh_rounded, label: 'REMATCH', onTap: onRematch, isPrimary: true),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _OverlayBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;

  const _OverlayBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: isPrimary ? T.duel : Colors.white10,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
            ),
            child: Icon(icon, color: Colors.white, size: 32),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: GoogleFonts.luckiestGuy(
              fontSize: 16,
              color: Colors.white,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}
class _ExitButton extends StatelessWidget {
  final VoidCallback onTap;
  const _ExitButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black,
          shape: BoxShape.circle,
          border: Border.all(color: T.duel, width: 2),
          boxShadow: const [
            BoxShadow(color: Colors.black45, blurRadius: 8, offset: Offset(0, 4)),
          ],
        ),
        child: const Icon(Icons.close_rounded, color: T.duel, size: 24),
      ),
    );
  }
}

class _DuelExitDialog extends StatelessWidget {
  final VoidCallback onCancel, onExit;
  const _DuelExitDialog({required this.onCancel, required this.onExit});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(32),
            boxShadow: const [
              BoxShadow(color: Colors.black54, blurRadius: 20, offset: Offset(0, 10)),
            ],
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1E5279),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: T.duel.withValues(alpha: 0.3), width: 2),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: T.duel.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.logout_rounded, color: T.duel, size: 40),
                ),
                const SizedBox(height: 20),
                Text(
                  'EXIT DUEL?',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.luckiestGuy(
                    fontSize: 32,
                    color: Colors.white,
                    letterSpacing: 2,
                    shadows: [
                      const Shadow(color: Colors.black45, offset: Offset(0, 4)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Are you sure you want to stop this match? Your progress will be lost.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.fredoka(
                    fontSize: 16,
                    color: Colors.white.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: onCancel,
                        child: Container(
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.white10,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Center(
                            child: Text(
                              'CANCEL',
                              style: GoogleFonts.luckiestGuy(
                                color: Colors.white70,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: GestureDetector(
                        onTap: onExit,
                        child: Container(
                          height: 56,
                          decoration: BoxDecoration(
                            color: T.duel,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: T.duel.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              'EXIT',
                              style: GoogleFonts.luckiestGuy(
                                color: Colors.black87,
                                fontSize: 18,
                              ),
                            ),
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
    );
  }
}
