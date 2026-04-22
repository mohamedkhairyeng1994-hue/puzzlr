import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../core/theme.dart';
import '../../widgets/logo_widget.dart';
import '../settings/settings_screen.dart';
import 'rando_game_screen.dart';
import 'rando_models.dart';

class RandoLevelsScreen extends StatefulWidget {
  const RandoLevelsScreen({super.key});

  @override
  State<RandoLevelsScreen> createState() => _RandoLevelsScreenState();
}

class _RandoLevelsScreenState extends State<RandoLevelsScreen> {
  static const int _totalLevels = 30;

  void _goToGame(BuildContext context, int level) {
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (ctx, a, sec) => RandoGameScreen(level: level),
        transitionsBuilder: (ctx, a, sec, child) => FadeTransition(
          opacity: CurvedAnimation(parent: a, curve: Curves.easeOut),
          child: child,
        ),
      ),
    );
  }

  void _showOutOfTriesDialog(BuildContext context, int level) {
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
                style: GoogleFonts.fredoka(
                    color: Colors.white, fontSize: 18),
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
                            Navigator.of(ctx).pop();
                            await innerCtx
                                .read<AppState>()
                                .watchAdForTry();
                            if (context.mounted) {
                              context.read<AppState>().useTry();
                              _goToGame(context, level);
                            }
                          },
                          child: Container(
                            height: 88,
                            decoration: BoxDecoration(
                              color: const Color(0xFF38B6FF),
                              borderRadius: BorderRadius.circular(20),
                              border:
                                  Border.all(color: Colors.white, width: 3),
                              boxShadow: const [
                                BoxShadow(
                                    color: Colors.black45,
                                    offset: Offset(0, 4))
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.smart_display_rounded,
                                    color: Colors.white, size: 34),
                                const SizedBox(height: 4),
                                Text('WATCH',
                                    style: GoogleFonts.luckiestGuy(
                                        fontSize: 18, color: Colors.white)),
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
                                  Navigator.of(ctx).pop();
                                  await innerCtx
                                      .read<AppState>()
                                      .spendFlames(5);
                                  if (context.mounted) {
                                    context.read<AppState>().useTry();
                                    _goToGame(context, level);
                                  }
                                }
                              : null,
                          child: Container(
                            height: 88,
                            decoration: BoxDecoration(
                              color: canAfford
                                  ? const Color(0xFFFF5722)
                                  : Colors.grey.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: Colors.white.withValues(
                                      alpha: canAfford ? 1.0 : 0.5),
                                  width: 3),
                              boxShadow: canAfford
                                  ? const [
                                      BoxShadow(
                                          color: Colors.black45,
                                          offset: Offset(0, 4))
                                    ]
                                  : null,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                    Icons.local_fire_department_rounded,
                                    color: Colors.white.withValues(
                                        alpha: canAfford ? 1.0 : 0.5),
                                    size: 34),
                                const SizedBox(height: 4),
                                Text('- 5',
                                    style: GoogleFonts.luckiestGuy(
                                        fontSize: 18,
                                        color: Colors.white.withValues(
                                            alpha: canAfford ? 1.0 : 0.5))),
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
    final unlocked = appState.randoSolved + 1;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      body: AnimatedBg(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
                          boxShadow: const [
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
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white24, width: 2),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.favorite_rounded,
                              color: T.timeAttack, size: 18),
                          const SizedBox(width: 8),
                          Text('${appState.triesLeft}/5',
                              style: T.caption),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white24, width: 2),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.local_fire_department_rounded,
                              color: T.gold, size: 18),
                          const SizedBox(width: 8),
                          Text('${appState.flames}', style: T.caption),
                        ],
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const SettingsScreen())),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          color: T.daily,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black45, offset: Offset(0, 3))
                          ],
                        ),
                        child: const Icon(Icons.settings_rounded,
                            color: Colors.white, size: 24),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const GameTitleText('RANDO', size: 64),
              Text(
                'MIXED CHALLENGES',
                style: GoogleFonts.luckiestGuy(
                  fontSize: 24,
                  color: const Color(0xFFCB6CE6),
                  letterSpacing: 2.0,
                  shadows: const [
                    Shadow(color: Colors.black, offset: Offset(0, 3))
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: GridView.builder(
                    physics: const BouncingScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 5,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 1.0,
                    ),
                    itemCount: _totalLevels,
                    itemBuilder: (ctx, i) {
                      final level = i + 1;
                      final isLocked = level > unlocked;
                      final kind = MiniGameKind.forLevel(level);
                      return _RandoLevelButton(
                        level: level,
                        kind: kind,
                        isLocked: isLocked,
                        onTap: () {
                          final state = context.read<AppState>();
                          if (state.triesLeft <= 0) {
                            _showOutOfTriesDialog(context, level);
                          } else {
                            state.useTry();
                            _goToGame(context, level);
                          }
                        },
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _RandoLevelButton extends StatefulWidget {
  final int level;
  final MiniGameKind kind;
  final bool isLocked;
  final VoidCallback onTap;

  const _RandoLevelButton({
    required this.level,
    required this.kind,
    required this.isLocked,
    required this.onTap,
  });

  @override
  State<_RandoLevelButton> createState() => _RandoLevelButtonState();
}

class _RandoLevelButtonState extends State<_RandoLevelButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final Color face =
        widget.isLocked ? const Color(0xFF4A3B62) : widget.kind.accent;
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
        child: Container(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black87,
            boxShadow: [
              BoxShadow(
                  color: Colors.black38,
                  offset: Offset(0, 4),
                  blurRadius: 2),
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
                color: face,
                border: Border.all(color: Colors.white, width: 2.5),
              ),
              child: Center(
                child: widget.isLocked
                    ? const Icon(Icons.lock_rounded,
                        color: Colors.white, size: 22)
                    : Stack(
                        alignment: Alignment.center,
                        children: [
                          Text(
                            '${widget.level}',
                            style: GoogleFonts.luckiestGuy(
                              fontSize: 26,
                              color: Colors.white,
                              shadows: const [
                                Shadow(
                                    color: Colors.black54,
                                    offset: Offset(0, 2)),
                              ],
                            ),
                          ),
                          Positioned(
                            bottom: 4,
                            right: 4,
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                widget.kind.icon,
                                color: Colors.white,
                                size: 12,
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
    );
  }
}
