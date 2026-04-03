import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/app_state.dart';
import '../../core/theme.dart';
import '../../models/puzzle_model.dart';
import '../../widgets/logo_widget.dart';
import 'daily_game_screen.dart';


// ══════════════════════════════════════════════════════════════════════════════
//  DailyScreen
// ══════════════════════════════════════════════════════════════════════════════

class DailyScreen extends StatefulWidget {
  const DailyScreen({super.key});

  @override
  State<DailyScreen> createState() => _DailyScreenState();
}

class _DailyScreenState extends State<DailyScreen>
    with TickerProviderStateMixin {
  late AnimationController _entryAnim;
  late AnimationController _pulseAnim;
  late AnimationController _celebAnim;
  late Timer _countdownTimer;
  String _countdownStr = '';

  @override
  void initState() {
    super.initState();
    _entryAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    _pulseAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _celebAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _updateCountdown();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) _updateCountdown();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = context.read<AppState>();
      if (appState.dailyStage >= 3) _celebAnim.forward();
    });
  }

  void _updateCountdown() {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final diff = tomorrow.difference(now);
    final h = diff.inHours.toString().padLeft(2, '0');
    final m = (diff.inMinutes % 60).toString().padLeft(2, '0');
    final s = (diff.inSeconds % 60).toString().padLeft(2, '0');
    setState(() => _countdownStr = '$h:$m:$s');
  }

  @override
  void dispose() {
    _entryAnim.dispose();
    _pulseAnim.dispose();
    _celebAnim.dispose();
    _countdownTimer.cancel();
    super.dispose();
  }

  int get _dailySeed {
    final now = DateTime.now();
    return now.year * 10000 + now.month * 100 + now.day;
  }

  void _launchStage(Difficulty d) {
    final seed = _dailySeed + d.index * 100;
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (ctx, a, sec) => DailyGameScreen(
          difficulty: d,
          imageUrl: 'https://picsum.photos/seed/daily$seed/800/800',
          seed: seed,
        ),
        transitionsBuilder: (ctx, a, sec, child) {
          final slide = Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).chain(CurveTween(curve: Curves.easeOutCubic));
          return SlideTransition(position: a.drive(slide), child: child);
        },
      ),
    ).then((_) {
      if (!mounted) return;
      setState(() {});
      final appState = context.read<AppState>();
      if (appState.dailyStage >= 3 && _celebAnim.value == 0) {
        _celebAnim.forward();
      }
    });
  }

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final stage = appState.dailyStage;
    final now = DateTime.now();
    final monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final weekday = dayNames[now.weekday - 1];
    final dateStr = '$weekday, ${monthNames[now.month - 1]} ${now.day}';

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      body: AnimatedBg(
        child: FadeTransition(
          opacity: CurvedAnimation(parent: _entryAnim, curve: Curves.easeOut),
          child: SafeArea(
            child: Column(
              children: [
                // ── Top Bar ──────────────────────────────────────────────
                _TopBar(
                  streak: appState.streak,
                  onBack: () => Navigator.of(context).pop(),
                ),

                // ── Hero Header ──────────────────────────────────────────
                _HeroHeader(
                  dateStr: dateStr,
                  countdownStr: _countdownStr,
                  stage: stage,
                  entryAnim: _entryAnim,
                  pulseAnim: _pulseAnim,
                ),

                const SizedBox(height: 16),

                // ── Stage Pipeline ───────────────────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        // Progress connector + stage cards
                        _StagePipeline(
                          stage: stage,
                          appState: appState,
                          formatTime: _formatTime,
                          pulseAnim: _pulseAnim,
                          onPlay: _launchStage,
                        ),

                        // ── Completion Panel ─────────────────────────────
                        if (stage >= 3) ...[
                          const SizedBox(height: 20),
                          _CompletionPanel(
                            celebAnim: _celebAnim,
                            appState: appState,
                            formatTime: _formatTime,
                            seed: _dailySeed,
                          ),
                        ],

                        const SizedBox(height: 32),
                      ],
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

// ══════════════════════════════════════════════════════════════════════════════
//  Top Bar
// ══════════════════════════════════════════════════════════════════════════════

class _TopBar extends StatelessWidget {
  final int streak;
  final VoidCallback onBack;

  const _TopBar({required this.streak, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          // Back Button
          GestureDetector(
            onTap: onBack,
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFF1E5279),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2.5),
                boxShadow: const [
                  BoxShadow(color: Colors.black45, offset: Offset(0, 3)),
                ],
              ),
              child: const Icon(Icons.arrow_back_rounded,
                  color: Colors.white, size: 22),
            ),
          ),

          const Spacer(),

          // Streak Badge
          if (streak > 0)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                    color: T.gold.withValues(alpha: 0.7), width: 2),
              ),
              child: Row(
                children: [
                  const Icon(Icons.local_fire_department_rounded,
                      color: T.gold, size: 20),
                  const SizedBox(width: 6),
                  Text(
                    '$streak Day Streak',
                    style: GoogleFonts.fredoka(
                      color: T.gold,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  Hero Header
// ══════════════════════════════════════════════════════════════════════════════

class _HeroHeader extends StatelessWidget {
  final String dateStr;
  final String countdownStr;
  final int stage;
  final AnimationController entryAnim;
  final AnimationController pulseAnim;

  const _HeroHeader({
    required this.dateStr,
    required this.countdownStr,
    required this.stage,
    required this.entryAnim,
    required this.pulseAnim,
  });

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(0, -0.3), end: Offset.zero)
          .chain(CurveTween(curve: Curves.easeOutCubic))
          .animate(entryAnim),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0F4C81), Color(0xFF1A6BAD)],
            ),
            border: Border.all(
              color: T.daily.withValues(alpha: 0.5),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: T.daily.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
              const BoxShadow(
                  color: Colors.black45, offset: Offset(0, 6)),
            ],
          ),
          child: Stack(
            children: [
              // Decorative dots
              Positioned(
                top: -10,
                right: -10,
                child: _DecorCircle(size: 80, color: T.daily, opacity: 0.06),
              ),
              Positioned(
                bottom: -20,
                left: 20,
                child: _DecorCircle(size: 100, color: T.classic, opacity: 0.05),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    // Left: title + date
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: T.daily.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: T.daily.withValues(alpha: 0.5),
                                    width: 1.5,
                                  ),
                                ),
                                child: const Icon(Icons.calendar_today_rounded,
                                    color: T.daily, size: 20),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'DAILY PUZZLE',
                                style: GoogleFonts.luckiestGuy(
                                  fontSize: 20,
                                  color: T.daily,
                                  letterSpacing: 1.5,
                                  shadows: const [
                                    Shadow(
                                        color: Colors.black45,
                                        offset: Offset(0, 2))
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            dateStr,
                            style: GoogleFonts.fredoka(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Stage progress pill
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              stage >= 3
                                  ? '✅ All stages complete!'
                                  : 'Stage $stage / 3',
                              style: GoogleFonts.fredoka(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: stage >= 3
                                    ? T.daily
                                    : Colors.white.withValues(alpha: 0.7),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Right: countdown
                    if (stage < 3)
                      _CountdownBox(
                          countdownStr: countdownStr, pulseAnim: pulseAnim),
                    if (stage >= 3)
                      const _CompletedIcon(),
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

class _CountdownBox extends StatelessWidget {
  final String countdownStr;
  final AnimationController pulseAnim;

  const _CountdownBox(
      {required this.countdownStr, required this.pulseAnim});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulseAnim,
      builder: (_, __) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: T.timeAttack
                .withValues(alpha: 0.4 + pulseAnim.value * 0.3),
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Text(
              'RESETS IN',
              style: GoogleFonts.fredoka(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white.withValues(alpha: 0.5),
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              countdownStr,
              style: GoogleFonts.luckiestGuy(
                fontSize: 22,
                color: T.timeAttack,
                shadows: const [
                  Shadow(color: Colors.black45, offset: Offset(0, 2))
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompletedIcon extends StatelessWidget {
  const _CompletedIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: T.daily.withValues(alpha: 0.15),
        shape: BoxShape.circle,
        border: Border.all(color: T.daily, width: 2.5),
      ),
      child: const Icon(Icons.emoji_events_rounded, color: T.gold, size: 34),
    );
  }
}

class _DecorCircle extends StatelessWidget {
  final double size;
  final Color color;
  final double opacity;

  const _DecorCircle(
      {required this.size, required this.color, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: opacity),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  Stage Pipeline
// ══════════════════════════════════════════════════════════════════════════════

class _StagePipeline extends StatelessWidget {
  final int stage;
  final AppState appState;
  final String Function(int) formatTime;
  final AnimationController pulseAnim;
  final void Function(Difficulty) onPlay;

  const _StagePipeline({
    required this.stage,
    required this.appState,
    required this.formatTime,
    required this.pulseAnim,
    required this.onPlay,
  });

  static const _stageData = [
    (
      label: 'EASY',
      icon: Icons.sentiment_satisfied_alt_rounded,
      color: Color(0xFF38B6FF),
      gridLabel: '3×3',
      desc: 'Warm up your brain',
    ),
    (
      label: 'MEDIUM',
      icon: Icons.psychology_rounded,
      color: Color(0xFFF59E0B),
      gridLabel: '4×4',
      desc: 'Pick up the pace',
    ),
    (
      label: 'HARD',
      icon: Icons.whatshot_rounded,
      color: Color(0xFFF43F5E),
      gridLabel: '5×5',
      desc: 'Push your limits',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Section label
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Text(
                "TODAY'S STAGES",
                style: GoogleFonts.luckiestGuy(
                  fontSize: 16,
                  color: Colors.white.withValues(alpha: 0.5),
                  letterSpacing: 2.0,
                ),
              ),
            ],
          ),
        ),

        for (var i = 0; i < 3; i++) ...[
          _StageCard(
            index: i,
            data: _stageData[i],
            difficulty: Difficulty.values[i],
            isDone: stage > i,
            isCurrent: stage == i,
            isLocked: stage < i,
            moves: appState.dailyMoves[Difficulty.values[i].name] ?? 0,
            time: appState.dailyTimes[Difficulty.values[i].name] ?? 0,
            formatTime: formatTime,
            pulseAnim: pulseAnim,
            onPlay: stage == i ? () => onPlay(Difficulty.values[i]) : null,
            appState: appState,
          ),
          // Connector between cards
          if (i < 2)
            _StageConnector(
              completed: stage > i,
              active: stage == i + 1,
            ),
        ],
      ],
    );
  }
}

class _StageConnector extends StatelessWidget {
  final bool completed;
  final bool active;

  const _StageConnector({required this.completed, required this.active});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          const SizedBox(width: 35),
          Container(
            width: 3,
            height: 24,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: completed
                    ? [T.daily, T.daily.withValues(alpha: 0.5)]
                    : active
                        ? [Colors.white24, Colors.white12]
                        : [Colors.white12, Colors.white.withValues(alpha: 0.05)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  Stage Card
// ══════════════════════════════════════════════════════════════════════════════

class _StageCard extends StatefulWidget {
  final int index;
  final ({
    String label,
    IconData icon,
    Color color,
    String gridLabel,
    String desc,
  }) data;
  final Difficulty difficulty;
  final bool isDone;
  final bool isCurrent;
  final bool isLocked;
  final int moves;
  final int time;
  final String Function(int) formatTime;
  final AnimationController pulseAnim;
  final VoidCallback? onPlay;
  final AppState appState;

  const _StageCard({
    required this.index,
    required this.data,
    required this.difficulty,
    required this.isDone,
    required this.isCurrent,
    required this.isLocked,
    required this.moves,
    required this.time,
    required this.formatTime,
    required this.pulseAnim,
    required this.onPlay,
    required this.appState,
  });

  @override
  State<_StageCard> createState() => _StageCardState();
}

class _StageCardState extends State<_StageCard> {
  bool _pressed = false;

  Color get _color => widget.data.color;

  Color get _effectiveColor =>
      widget.isLocked ? Colors.grey.shade600 : _color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.isCurrent
          ? (_) => setState(() => _pressed = true)
          : null,
      onTapUp: widget.isCurrent
          ? (_) {
              setState(() => _pressed = false);
              HapticFeedback.mediumImpact();
              widget.onPlay?.call();
            }
          : null,
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedBuilder(
          animation: widget.pulseAnim,
          builder: (_, __) {
            final glowOpacity = widget.isCurrent
                ? 0.15 + widget.pulseAnim.value * 0.2
                : 0.0;
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  if (widget.isCurrent)
                    BoxShadow(
                      color: _color.withValues(alpha: glowOpacity),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  const BoxShadow(
                      color: Colors.black38, offset: Offset(0, 5)),
                ],
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 5),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: widget.isDone
                        ? _effectiveColor.withValues(alpha: 0.12)
                        : widget.isCurrent
                            ? _color.withValues(alpha: 0.1)
                            : Colors.white.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: widget.isDone
                          ? _effectiveColor.withValues(alpha: 0.4)
                          : widget.isCurrent
                              ? _color.withValues(alpha: 0.6)
                              : Colors.white.withValues(alpha: 0.07),
                      width: widget.isCurrent ? 2 : 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Left icon block
                      _StatusIcon(
                        index: widget.index,
                        isDone: widget.isDone,
                        isCurrent: widget.isCurrent,
                        isLocked: widget.isLocked,
                        color: _effectiveColor,
                        icon: widget.data.icon,
                        pulseAnim: widget.pulseAnim,
                      ),

                      const SizedBox(width: 14),

                      // Middle content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.data.label,
                              style: GoogleFonts.luckiestGuy(
                                fontSize: 20,
                                color: widget.isLocked
                                    ? Colors.white.withValues(alpha: 0.25)
                                    : Colors.white,
                                letterSpacing: 1.0,
                                shadows: widget.isLocked
                                    ? null
                                    : const [
                                        Shadow(
                                            color: Colors.black54,
                                            offset: Offset(0, 2))
                                      ],
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              widget.isDone
                                  ? '${widget.moves} moves · ${widget.formatTime(widget.time)}'
                                  : '${widget.data.gridLabel} · ${widget.data.desc}',
                              style: GoogleFonts.fredoka(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: widget.isDone
                                    ? _effectiveColor.withValues(alpha: 0.9)
                                    : Colors.white.withValues(
                                        alpha: widget.isLocked ? 0.2 : 0.55),
                              ),
                            ),
                            // Stars earned for this stage
                            if (widget.isDone) ...[
                              const SizedBox(height: 6),
                              _StarRow(
                                  moves: widget.moves,
                                  starA: widget.difficulty.starA,
                                  starB: widget.difficulty.starB,
                                  color: _effectiveColor),
                            ]
                          ],
                        ),
                      ),

                      // Right action
                      const SizedBox(width: 10),
                      _ActionWidget(
                        isDone: widget.isDone,
                        isCurrent: widget.isCurrent,
                        color: _effectiveColor,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ── Status Icon (left side of card) ──────────────────────────────────────────

class _StatusIcon extends StatelessWidget {
  final int index;
  final bool isDone;
  final bool isCurrent;
  final bool isLocked;
  final Color color;
  final IconData icon;
  final AnimationController pulseAnim;

  const _StatusIcon({
    required this.index,
    required this.isDone,
    required this.isCurrent,
    required this.isLocked,
    required this.color,
    required this.icon,
    required this.pulseAnim,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulseAnim,
      builder: (_, __) {
        final borderOpacity =
            isCurrent ? 0.5 + pulseAnim.value * 0.4 : 0.3;
        return Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: isDone
                ? color.withValues(alpha: 0.25)
                : isCurrent
                    ? color.withValues(alpha: 0.15)
                    : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDone
                  ? color.withValues(alpha: 0.5)
                  : isCurrent
                      ? color.withValues(alpha: borderOpacity)
                      : Colors.white.withValues(alpha: 0.1),
              width: 2,
            ),
          ),
          child: Center(
            child: isDone
                ? Icon(Icons.check_rounded, color: color, size: 26)
                : isLocked
                    ? Icon(Icons.lock_rounded,
                        color: Colors.white.withValues(alpha: 0.25), size: 22)
                    : Icon(icon, color: color, size: 26),
          ),
        );
      },
    );
  }
}

// ── Star Row ──────────────────────────────────────────────────────────────────

class _StarRow extends StatelessWidget {
  final int moves;
  final int starA;
  final int starB;
  final Color color;

  const _StarRow({
    required this.moves,
    required this.starA,
    required this.starB,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final stars = moves <= starA ? 3 : moves <= starB ? 2 : 1;
    return Row(
      children: List.generate(
        3,
        (i) => Padding(
          padding: const EdgeInsets.only(right: 2),
          child: Icon(
            i < stars ? Icons.star_rounded : Icons.star_outline_rounded,
            color: i < stars ? T.gold : Colors.white12,
            size: 16,
          ),
        ),
      ),
    );
  }
}

// ── Action Widget (right side of card) ───────────────────────────────────────

class _ActionWidget extends StatelessWidget {
  final bool isDone;
  final bool isCurrent;
  final Color color;

  const _ActionWidget({
    required this.isDone,
    required this.isCurrent,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (isCurrent) {
      return Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white, width: 2.5),
          boxShadow: const [
            BoxShadow(color: Colors.black45, offset: Offset(0, 3))
          ],
        ),
        child:
            const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 28),
      );
    }
    if (isDone) {
      return Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Text(
          'DONE',
          style: GoogleFonts.luckiestGuy(
            fontSize: 13,
            color: color,
          ),
        ),
      );
    }
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Icon(Icons.lock_outline_rounded,
          color: Colors.white.withValues(alpha: 0.2), size: 22),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  Completion Panel
// ══════════════════════════════════════════════════════════════════════════════

class _CompletionPanel extends StatelessWidget {
  final AnimationController celebAnim;
  final AppState appState;
  final String Function(int) formatTime;
  final int seed;

  const _CompletionPanel({
    required this.celebAnim,
    required this.appState,
    required this.formatTime,
    required this.seed,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: celebAnim,
      builder: (_, __) {
        final t = celebAnim.value;
        return Transform.scale(
          scale: 0.85 + t * 0.15,
          child: Opacity(
            opacity: t.clamp(0.0, 1.0),
            child: Column(
              children: [
                // All Clear Banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      vertical: 22, horizontal: 20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF5CB82E), Color(0xFF2E9B27)],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: const [
                      BoxShadow(color: Colors.black38, offset: Offset(0, 6)),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Trophy + Title
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('🏆', style: TextStyle(fontSize: 32)),
                          const SizedBox(width: 12),
                          Text(
                            'ALL CLEAR!',
                            style: GoogleFonts.luckiestGuy(
                              fontSize: 32,
                              color: Colors.white,
                              letterSpacing: 2.0,
                              shadows: const [
                                Shadow(
                                    color: Colors.black45,
                                    offset: Offset(0, 3))
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text('🏆', style: TextStyle(fontSize: 32)),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Stats row
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceAround,
                          children: [
                            _StatChip(
                              icon: Icons.pan_tool_alt_rounded,
                              label: 'Total Moves',
                              value:
                                  '${appState.dailyTotalMoves}',
                            ),
                            Container(
                              width: 1,
                              height: 40,
                              color: Colors.white24,
                            ),
                            _StatChip(
                              icon: Icons.timer_rounded,
                              label: 'Total Time',
                              value: formatTime(
                                  appState.dailyTotalTime),
                            ),
                            Container(
                              width: 1,
                              height: 40,
                              color: Colors.white24,
                            ),
                            _StatChip(
                              icon: Icons.local_fire_department_rounded,
                              label: 'Streak',
                              value: '${appState.streak}d',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Mini Leaderboard
                _MiniLeaderboard(
                    appState: appState, seed: seed),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatChip(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 18),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.luckiestGuy(
            fontSize: 18,
            color: Colors.white,
            shadows: const [
              Shadow(color: Colors.black45, offset: Offset(0, 1))
            ],
          ),
        ),
        Text(
          label,
          style: GoogleFonts.fredoka(
            fontSize: 11,
            color: Colors.white.withValues(alpha: 0.7),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  Mini Leaderboard
// ══════════════════════════════════════════════════════════════════════════════

class _MiniLeaderboard extends StatelessWidget {
  final AppState appState;
  final int seed;

  const _MiniLeaderboard({required this.appState, required this.seed});

  @override
  Widget build(BuildContext context) {
    // Show leaderboard for the last completed difficulty (hard if all done)
    final d = Difficulty.hard;
    final playerMoves = appState.dailyMoves[d.name] ?? 0;
    final playerSeconds = appState.dailyTimes[d.name] ?? 0;
    final entries = appState.getDailyStageLeaderboard(
      d: d,
      playerMoves: playerMoves,
      playerSeconds: playerSeconds,
    );

    // Show top 5 + player's position
    final playerIdx = entries.indexWhere((e) => e.isPlayer);
    final top5 = entries.take(5).toList();
    final playerInTop5 = playerIdx < 5;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF0D3A5C),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: Colors.white.withValues(alpha: 0.1), width: 1.5),
        boxShadow: const [
          BoxShadow(color: Colors.black38, offset: Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              children: [
                const Icon(Icons.leaderboard_rounded,
                    color: T.gold, size: 20),
                const SizedBox(width: 8),
                Text(
                  'DAILY LEADERBOARD',
                  style: GoogleFonts.luckiestGuy(
                    fontSize: 16,
                    color: Colors.white,
                    letterSpacing: 1.5,
                    shadows: const [
                      Shadow(
                          color: Colors.black45, offset: Offset(0, 1))
                    ],
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: T.gold.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    'HARD',
                    style: GoogleFonts.luckiestGuy(
                      fontSize: 12,
                      color: const Color(0xFFF43F5E),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Divider
          Container(
            height: 1,
            color: Colors.white.withValues(alpha: 0.07),
          ),

          // Entries
          ...top5.asMap().entries.map((entry) {
            final rank = entry.key + 1;
            final e = entry.value;
            return _LeaderboardRow(
                rank: rank, entry: e, isLast: rank == 5 && playerInTop5);
          }),

          // Player row if not in top 5
          if (!playerInTop5 && playerIdx >= 0) ...[
            Container(
              height: 1,
              margin:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              color: Colors.white.withValues(alpha: 0.07),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  const SizedBox(width: 8),
                  Text(
                    '...',
                    style: GoogleFonts.fredoka(
                        color: Colors.white38, fontSize: 14),
                  ),
                ],
              ),
            ),
            _LeaderboardRow(
              rank: playerIdx + 1,
              entry: entries[playerIdx],
              isLast: true,
            ),
          ],

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  final int rank;
  final LeaderboardEntry entry;
  final bool isLast;

  const _LeaderboardRow({
    required this.rank,
    required this.entry,
    this.isLast = false,
  });

  String _fmtTime(int s) {
    final m = (s ~/ 60).toString().padLeft(2, '0');
    final sec = (s % 60).toString().padLeft(2, '0');
    return '$m:$sec';
  }

  @override
  Widget build(BuildContext context) {
    final isPlayer = entry.isPlayer;
    final rankColor = rank == 1
        ? T.gold
        : rank == 2
            ? const Color(0xFFB0C4DE)
            : rank == 3
                ? const Color(0xFFCD7F32)
                : Colors.white54;
    final rankIcon = rank == 1
        ? '🥇'
        : rank == 2
            ? '🥈'
            : rank == 3
                ? '🥉'
                : null;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isPlayer
            ? T.daily.withValues(alpha: 0.12)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        border: isPlayer
            ? Border.all(color: T.daily.withValues(alpha: 0.4), width: 1.5)
            : null,
      ),
      child: Row(
        children: [
          // Rank
          SizedBox(
            width: 32,
            child: rankIcon != null
                ? Text(rankIcon,
                    style: const TextStyle(fontSize: 18),
                    textAlign: TextAlign.center)
                : Text(
                    '$rank',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.luckiestGuy(
                        fontSize: 14, color: rankColor),
                  ),
          ),
          const SizedBox(width: 8),
          // Name
          Expanded(
            child: Text(
              entry.name,
              style: GoogleFonts.fredoka(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isPlayer ? T.daily : Colors.white,
              ),
            ),
          ),
          // Moves
          Row(
            children: [
              Icon(Icons.swipe_rounded,
                  size: 14,
                  color: Colors.white.withValues(alpha: 0.5)),
              const SizedBox(width: 4),
              Text(
                '${entry.totalMoves}',
                style: GoogleFonts.fredoka(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(width: 10),
              Icon(Icons.timer_rounded,
                  size: 14,
                  color: Colors.white.withValues(alpha: 0.5)),
              const SizedBox(width: 4),
              Text(
                _fmtTime(entry.totalSeconds),
                style: GoogleFonts.fredoka(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
