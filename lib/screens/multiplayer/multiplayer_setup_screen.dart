import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';
import '../../models/puzzle_model.dart';
import 'duel_game_screen.dart';

class MultiplayerSetupScreen extends StatefulWidget {
  const MultiplayerSetupScreen({super.key});

  @override
  State<MultiplayerSetupScreen> createState() => _MultiplayerSetupScreenState();
}

class _MultiplayerSetupScreenState extends State<MultiplayerSetupScreen> {
  Difficulty _difficulty = Difficulty.easy;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      body: AnimatedBg(
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(
                  children: [
                    _SetupBackBtn(onTap: () => Navigator.of(context).pop()),
                    const Spacer(),
                    Text(
                      'MULTIPLAYER',
                      style: GoogleFonts.luckiestGuy(
                        fontSize: 26,
                        color: T.duel,
                        letterSpacing: 2,
                        shadows: [
                          const Shadow(color: Colors.black, offset: Offset(0, 3)),
                        ],
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(width: 44), // Balancer
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    Text(
                      'READY FOR A DUEL?',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.luckiestGuy(
                        fontSize: 32,
                        color: Colors.white,
                        shadows: [
                          const Shadow(color: Colors.black45, offset: Offset(0, 4)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Challenge your friend on the same device! First to solve the puzzle wins.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.fredoka(
                        fontSize: 16,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Difficulty Grid
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    _DiffCard(
                      diff: Difficulty.easy,
                      selected: _difficulty == Difficulty.easy,
                      onTap: () => setState(() => _difficulty = Difficulty.easy),
                    ),
                    const SizedBox(height: 16),
                    _DiffCard(
                      diff: Difficulty.medium,
                      selected: _difficulty == Difficulty.medium,
                      onTap: () => setState(() => _difficulty = Difficulty.medium),
                    ),
                    const SizedBox(height: 16),
                    _DiffCard(
                      diff: Difficulty.hard,
                      selected: _difficulty == Difficulty.hard,
                      onTap: () => setState(() => _difficulty = Difficulty.hard),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Start Button
              Padding(
                padding: const EdgeInsets.fromLTRB(32, 0, 32, 48),
                child: _StartButton(
                  onTap: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => DuelGameScreen(difficulty: _difficulty),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DiffCard extends StatelessWidget {
  final Difficulty diff;
  final bool selected;
  final VoidCallback onTap;

  const _DiffCard({
    required this.diff,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: BoxDecoration(
          color: selected ? T.duel.withValues(alpha: 0.15) : Colors.black26,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected ? T.duel : Colors.white12,
            width: selected ? 3 : 2,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: T.duel.withValues(alpha: 0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: diff.accent.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(diff.icon, color: diff.accent, size: 28),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    diff.gridLabel,
                    style: GoogleFonts.luckiestGuy(
                      fontSize: 18,
                      color: selected ? T.duel : Colors.white70,
                      letterSpacing: 1,
                    ),
                  ),
                  Text(
                    diff.label.toUpperCase(),
                    style: GoogleFonts.fredoka(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle_rounded, color: T.duel, size: 32),
          ],
        ),
      ),
    );
  }
}

class _StartButton extends StatefulWidget {
  final VoidCallback onTap;
  const _StartButton({required this.onTap});

  @override
  State<_StartButton> createState() => _StartButtonState();
}

class _StartButtonState extends State<_StartButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: double.infinity,
          height: 72,
          decoration: const BoxDecoration(
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.all(Radius.circular(24)),
            color: Colors.black87,
            boxShadow: [
              BoxShadow(color: Colors.black45, offset: Offset(0, 6)),
            ],
          ),
          child: Container(
            margin: const EdgeInsets.only(bottom: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: const Color(0xFFE2Eef5),
              border: Border.all(color: const Color(0xFF42566b), width: 2),
            ),
            child: Container(
              margin: const EdgeInsets.only(bottom: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: T.duel,
                border: Border.all(color: Colors.white, width: 4),
              ),
              child: Center(
                child: Text(
                  'START DUEL!',
                  style: GoogleFonts.luckiestGuy(
                    fontSize: 28,
                    color: Colors.white,
                    letterSpacing: 2,
                    shadows: [
                      const Shadow(color: Colors.black26, offset: Offset(0, 2)),
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

class _SetupBackBtn extends StatelessWidget {
  final VoidCallback onTap;
  const _SetupBackBtn({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.black26,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white24, width: 2),
        ),
        child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
      ),
    );
  }
}
