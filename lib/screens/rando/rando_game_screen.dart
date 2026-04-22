import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../core/theme.dart';
import '../../widgets/logo_widget.dart';
import 'minigames/math_quick.dart';
import 'minigames/memory_match.dart';
import 'minigames/tap_odd.dart';
import 'minigames/word_complete.dart';
import 'rando_models.dart';

class RandoGameScreen extends StatefulWidget {
  final int level;

  const RandoGameScreen({super.key, required this.level});

  @override
  State<RandoGameScreen> createState() => _RandoGameScreenState();
}

class _RandoGameScreenState extends State<RandoGameScreen>
    with TickerProviderStateMixin {
  int _attempt = 0;
  bool _solved = false;
  bool _failed = false;
  String _failReason = '';

  late AnimationController _solvedAnim;
  late AnimationController _failedAnim;

  MiniGameKind get _kind => MiniGameKind.forLevel(widget.level);
  int get _seed => widget.level * 1000 + 42;

  @override
  void initState() {
    super.initState();
    _solvedAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _failedAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void dispose() {
    _solvedAnim.dispose();
    _failedAnim.dispose();
    super.dispose();
  }

  void _onSolved() {
    if (_solved || _failed) return;
    HapticFeedback.heavyImpact();
    setState(() => _solved = true);
    context.read<AppState>().recordRandoSolve(level: widget.level);
    _solvedAnim.forward();
  }

  void _onFailed(String reason) {
    if (_solved || _failed) return;
    HapticFeedback.vibrate();
    setState(() {
      _failed = true;
      _failReason = reason;
    });
    _failedAnim.forward();
  }

  void _retry() {
    final state = context.read<AppState>();
    if (state.triesLeft <= 0) {
      Navigator.of(context).pop();
      return;
    }
    state.useTry();
    _solvedAnim.reset();
    _failedAnim.reset();
    setState(() {
      _attempt++;
      _solved = false;
      _failed = false;
      _failReason = '';
    });
  }

  void _next() {
    Navigator.of(context).pop(true);
  }

  Widget _buildMiniGame() {
    final callbacks = MiniGameCallbacks(
      onSolved: _onSolved,
      onFailed: _onFailed,
    );
    final key = ValueKey(_attempt);
    switch (_kind) {
      case MiniGameKind.memoryMatch:
        return MemoryMatchGame(
          key: key,
          seed: _seed,
          level: widget.level,
          callbacks: callbacks,
        );
      case MiniGameKind.wordComplete:
        return WordCompleteGame(
          key: key,
          seed: _seed,
          level: widget.level,
          callbacks: callbacks,
        );
      case MiniGameKind.mathQuick:
        return MathQuickGame(
          key: key,
          seed: _seed,
          level: widget.level,
          callbacks: callbacks,
        );
      case MiniGameKind.tapOdd:
        return TapOddGame(
          key: key,
          seed: _seed,
          level: widget.level,
          callbacks: callbacks,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      body: AnimatedBg(
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  // Top bar
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: const BoxDecoration(
                              color: T.timeAttack,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black45,
                                    offset: Offset(0, 3))
                              ],
                            ),
                            child: const Icon(Icons.arrow_back_rounded,
                                color: Colors.white, size: 24),
                          ),
                        ),
                        const SizedBox(width: 12),
                        _TopChip(
                          icon: Icons.favorite_rounded,
                          color: T.timeAttack,
                          text: '${appState.triesLeft}/5',
                        ),
                        const SizedBox(width: 8),
                        _TopChip(
                          icon: Icons.local_fire_department_rounded,
                          color: T.gold,
                          text: '${appState.flames}',
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF9C27B0),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: const [
                              BoxShadow(
                                  color: Colors.black45, offset: Offset(0, 3))
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.shuffle_rounded,
                                  color: Colors.white, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                'LVL ${widget.level}',
                                style: GoogleFonts.luckiestGuy(
                                  color: Colors.white,
                                  fontSize: 16,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  GameTitleText(_kind.title, size: 36),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 8),
                    child: Text(
                      _kind.instructions,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.fredoka(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(child: _buildMiniGame()),
                ],
              ),
              if (_solved) _SolvedOverlay(onNext: _next),
              if (_failed)
                _FailedOverlay(reason: _failReason, onRetry: _retry),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopChip extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  const _TopChip({required this.icon, required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(
            text,
            style: GoogleFonts.fredoka(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SolvedOverlay extends StatelessWidget {
  final VoidCallback onNext;
  const _SolvedOverlay({required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.65),
      alignment: Alignment.center,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: GlassCard(
          glow: const Color(0xFF3ba629),
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const GameTitleText('SOLVED!', size: 44),
              const SizedBox(height: 12),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.local_fire_department_rounded,
                      color: T.gold, size: 28),
                  const SizedBox(width: 6),
                  Text(
                    '+2',
                    style: GoogleFonts.luckiestGuy(
                      fontSize: 30,
                      color: T.gold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: onNext,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 40, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8CD83A),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: const [
                      BoxShadow(color: Colors.black45, offset: Offset(0, 4))
                    ],
                  ),
                  child: Text(
                    'CONTINUE',
                    style: GoogleFonts.luckiestGuy(
                      fontSize: 22,
                      color: Colors.white,
                      letterSpacing: 1.2,
                      shadows: const [
                        Shadow(color: Colors.black54, offset: Offset(0, 2))
                      ],
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
}

class _FailedOverlay extends StatelessWidget {
  final String reason;
  final VoidCallback onRetry;
  const _FailedOverlay({required this.reason, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final tries = context.watch<AppState>().triesLeft;
    return Container(
      color: Colors.black.withValues(alpha: 0.65),
      alignment: Alignment.center,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: GlassCard(
          glow: const Color(0xFF8B2A2A),
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const GameTitleText('FAILED!', size: 44),
              const SizedBox(height: 8),
              Text(
                reason,
                textAlign: TextAlign.center,
                style: GoogleFonts.fredoka(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6C7A89),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: const [
                          BoxShadow(
                              color: Colors.black45, offset: Offset(0, 4))
                        ],
                      ),
                      child: Text(
                        'BACK',
                        style: GoogleFonts.luckiestGuy(
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  GestureDetector(
                    onTap: tries > 0 ? onRetry : null,
                    child: Opacity(
                      opacity: tries > 0 ? 1.0 : 0.4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF5757),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: const [
                            BoxShadow(
                                color: Colors.black45, offset: Offset(0, 4))
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.replay_rounded,
                                color: Colors.white, size: 22),
                            const SizedBox(width: 6),
                            Text(
                              'RETRY',
                              style: GoogleFonts.luckiestGuy(
                                fontSize: 18,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.black38,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.favorite_rounded,
                                      color: T.timeAttack, size: 14),
                                  const SizedBox(width: 4),
                                  Text(
                                    '-1',
                                    style: GoogleFonts.fredoka(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
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
    );
  }
}
