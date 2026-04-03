import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/app_state.dart';
import '../../core/theme.dart';
import '../../models/puzzle_model.dart';
import '../../widgets/logo_widget.dart';
import '../game/game_screen.dart';
import '../settings/settings_screen.dart';

class LevelsScreen extends StatefulWidget {
  const LevelsScreen({super.key});

  @override
  State<LevelsScreen> createState() => _LevelsScreenState();
}

class _LevelsScreenState extends State<LevelsScreen> {
  int _currentPage = 0; // 0: Easy, 1: Medium, 2: Hard

  void _goToGame(BuildContext context, int level, Difficulty d) {
    // Generate a fixed visual puzzle based on absolute level
    final seed = (_currentPage * 30 + level) * 1000 + 42; 
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (ctx, a, sec) => GameScreen(
          difficulty: d,
          imageUrl: 'https://picsum.photos/seed/$seed/800/800',
          mode: GameMode.classic,
          seed: seed,
        ),
        transitionsBuilder: (ctx, a, sec, child) => FadeTransition(
          opacity: CurvedAnimation(parent: a, curve: Curves.easeOut),
          child: child,
        ),
      ),
    );
  }

  void _showOutOfTriesDialog(BuildContext context, int level, Difficulty d) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.transparent,
        contentPadding: EdgeInsets.zero,
        content: GlassCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const GameTitleText('OUT OF TRIES', size: 32),
              const SizedBox(height: 16),
              Text(
                'You have 0 tries left today.\nWatch an ad or spend flames to play!',
                textAlign: TextAlign.center,
                style: GoogleFonts.fredoka(color: Colors.white, fontSize: 18),
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
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white24, width: 1.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.timer_outlined, color: T.gold, size: 20),
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
              const SizedBox(height: 24),
              Builder(
                builder: (innerCtx) {
                  final appState = innerCtx.watch<AppState>();
                  final canAfford = appState.flames >= 5;
                  
                  return Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            Navigator.of(ctx).pop(); // Dismiss dialog
                            await innerCtx.read<AppState>().watchAdForTry();
                            if (context.mounted) {
                              context.read<AppState>().useTry();
                              _goToGame(context, level, d);
                            }
                          },
                          child: Container(
                            height: 90,
                            decoration: BoxDecoration(
                              color: const Color(0xFF38B6FF),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: const [BoxShadow(color: Colors.black45, offset: Offset(0, 4))],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.smart_display_rounded, color: Colors.white, size: 36),
                                const SizedBox(height: 4),
                                Text(
                                  'WATCH',
                                  style: GoogleFonts.luckiestGuy(
                                    fontSize: 18,
                                    color: Colors.white,
                                    letterSpacing: 1.0,
                                    shadows: const [Shadow(color: Colors.black54, offset: Offset(0, 2))],
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
                          onTap: canAfford ? () async {
                            Navigator.of(ctx).pop();
                            await innerCtx.read<AppState>().spendFlames(5);
                            if (context.mounted) {
                              context.read<AppState>().useTry(); // Spend the granted try instantly
                              _goToGame(context, level, d);
                            }
                          } : null,
                          child: Container(
                            height: 90,
                            decoration: BoxDecoration(
                              color: canAfford ? const Color(0xFFFF5722) : Colors.grey.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white.withValues(alpha: canAfford ? 1.0 : 0.5), width: 3),
                              boxShadow: canAfford ? const [BoxShadow(color: Colors.black45, offset: Offset(0, 4))] : null,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.local_fire_department_rounded, color: Colors.white.withValues(alpha: canAfford ? 1.0 : 0.5), size: 36),
                                const SizedBox(height: 4),
                                Text(
                                  '- 5',
                                  style: GoogleFonts.luckiestGuy(
                                    fontSize: 18,
                                    color: Colors.white.withValues(alpha: canAfford ? 1.0 : 0.5),
                                    shadows: canAfford ? const [Shadow(color: Colors.black54, offset: Offset(0, 2))] : null,
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
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    // Unlocked dictates how many levels we can play globally
    final globalUnlocked = appState.totalSolved + 1; 

    String diffText = 'EASY';
    Color diffColor = T.daily; // Green for easy
    Difficulty currentDiff = Difficulty.easy;

    if (_currentPage == 1) {
      diffText = 'MEDIUM';
      diffColor = T.classic; // Blue for medium
      currentDiff = Difficulty.medium;
    } else if (_currentPage == 2) {
      diffText = 'HARD';
      diffColor = T.timeAttack; // Red for hard
      currentDiff = Difficulty.hard;
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      body: AnimatedBg(
        child: SafeArea(
          child: Column(
            children: [
              // Top Bar with floating settings
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: T.timeAttack,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black, width: 2),
                          boxShadow: const [BoxShadow(color: Colors.black45, offset: Offset(0, 3))],
                        ),
                        child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 24),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white24, width: 2),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.favorite_rounded, color: T.timeAttack, size: 18),
                          const SizedBox(width: 8),
                          Text('${appState.triesLeft}/5', style: T.caption),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white24, width: 2),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.local_fire_department_rounded, color: T.gold, size: 18),
                          const SizedBox(width: 8),
                          Text('${appState.flames}', style: T.caption),
                        ],
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          color: T.daily, // Bright Green
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Colors.black45, offset: Offset(0, 3))],
                        ),
                        child: const Icon(Icons.settings_rounded, color: Colors.white, size: 24),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),
              
              // Big chunky title
              const GameTitleText('Levels', size: 64),
              // Difficulty Subtitle
              Text(
                diffText,
                style: GoogleFonts.luckiestGuy(
                  fontSize: 32,
                  color: diffColor,
                  letterSpacing: 2.0,
                  shadows: const [Shadow(color: Colors.black, offset: Offset(0, 3))],
                ),
              ),
              
              const SizedBox(height: 16),

              // Level Grid
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: GridView.builder(
                    key: ValueKey(_currentPage), // Forces reset of scroll/animation if page changes
                    physics: const BouncingScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 5,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 1.0,
                    ),
                    itemCount: 30, // 30 levels per page
                    itemBuilder: (ctx, i) {
                      final level = i + 1;
                      // Calculate absolute progression level (1 to 90)
                      final absoluteLevel = (_currentPage * 30) + level;
                      final isLocked = absoluteLevel > globalUnlocked;

                      return LevelButton(
                        level: level,
                        isLocked: isLocked,
                        onTap: () {
                          final state = context.read<AppState>();
                          if (state.triesLeft <= 0) {
                            _showOutOfTriesDialog(context, level, currentDiff);
                          } else {
                            state.useTry();
                            _goToGame(context, level, currentDiff);
                          }
                        },
                      );
                    },
                  ),
                ),
              ),

              // Navigation Bottom Arrows
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _ArrowButton(
                      icon: Icons.arrow_back_rounded, 
                      onTap: () {
                        if (_currentPage > 0) {
                          setState(() => _currentPage--);
                        } else {
                           HapticFeedback.vibrate();
                        }
                      }
                    ),
                    const SizedBox(width: 32),
                    _ArrowButton(
                      icon: Icons.arrow_forward_rounded, 
                      onTap: () {
                        if (_currentPage < 2) {
                          setState(() => _currentPage++);
                        } else {
                           HapticFeedback.vibrate();
                        }
                      }
                    ),
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

// ── Level Bubble Button ──────────────────────────────────────────────────────────

class LevelButton extends StatefulWidget {
  final int level;
  final bool isLocked;
  final VoidCallback onTap;
  
  const LevelButton({
    required this.level,
    required this.isLocked,
    required this.onTap,
    super.key,
  });

  @override
  State<LevelButton> createState() => _LevelButtonState();
}

class _LevelButtonState extends State<LevelButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) {
        setState(() => _down = false);
        if (!widget.isLocked) {
          HapticFeedback.lightImpact();
          widget.onTap();
        } else {
           HapticFeedback.vibrate();
        }
      },
      onTapCancel: () => setState(() => _down = false),
      child: AnimatedScale(
        scale: _down ? 0.9 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.fastOutSlowIn,
        child: Container(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black87,
            boxShadow: [
              BoxShadow(color: Colors.black38, offset: Offset(0, 4), blurRadius: 2),
            ],
          ),
          child: Container(
            margin: const EdgeInsets.only(bottom: 4), 
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFE2Eef5),
              border: Border.all(color: const Color(0xFF42566b), width: 1.5),
            ),
            child: Container(
              margin: const EdgeInsets.only(bottom: 2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.isLocked ? const Color(0xFF265b82) : const Color(0xFF38B6FF),
                border: Border.all(color: Colors.white, width: 2.5),
              ),
              child: Center(
                child: widget.isLocked
                    ? const Icon(Icons.lock_rounded, color: Colors.white, size: 24)
                    : Text(
                        '${widget.level}',
                        style: GoogleFonts.luckiestGuy(
                          fontSize: 28,
                          color: Colors.white,
                          shadows: const [
                            Shadow(color: Colors.black54, offset: Offset(0, 2), blurRadius: 0),
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

// ── Green Navigation Arrow ───────────────────────────────────────────────────

class _ArrowButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  
  const _ArrowButton({required this.icon, required this.onTap});

  @override
  State<_ArrowButton> createState() => _ArrowButtonState();
}

class _ArrowButtonState extends State<_ArrowButton> {
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
        scale: _down ? 0.85 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: 60,
          height: 60,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black,
          ),
          child: Container(
            margin: const EdgeInsets.only(bottom: 4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF3ba629),
              border: Border.all(color: Colors.black, width: 2),
            ),
            child: Container(
              margin: const EdgeInsets.only(bottom: 2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF8CD83A),
                border: Border.all(color: Colors.black, width: 2.5),
              ),
              child: Center(
                child: Icon(
                  widget.icon,
                  color: const Color(0xFFFFDE59),
                  size: 34,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
