import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/app_state.dart';
import '../../core/theme.dart';
import '../../widgets/logo_widget.dart';
import '../../widgets/game_mode_button.dart';
import '../daily/daily_screen.dart';
import '../levels/levels_screen.dart';
import '../rando/rando_levels_screen.dart';
import '../settings/settings_screen.dart';
import '../profile/profile_screen.dart';
import '../multiplayer/multiplayer_setup_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final dailyStage = appState.dailyStage;

    // Subtitle shows progress
    String dailySub;
    if (dailyStage >= 3) {
      dailySub = '✅ All 3 stages cleared!';
    } else if (dailyStage == 0) {
      dailySub = 'Easy → Medium → Hard';
    } else {
      dailySub = 'Stage $dailyStage/3 completed';
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      body: AnimatedBg(
        child: SafeArea(
          child: Column(
            children: [
              // Top Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Row(
                  children: [
                    Row(
                      children: [
                        // Tries Badge
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
                        // Flames Badge
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
                      ],
                    ),
                    const Spacer(),
                    // Profile Button
                    GestureDetector(
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfileScreen())),
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: const Color(0xFF9C27B0),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2.5),
                          boxShadow: const [BoxShadow(color: Colors.black45, offset: Offset(0, 4))],
                        ),
                        child: const Center(
                          child: Icon(Icons.person_rounded, color: Colors.white, size: 28),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Settings Button
                    GestureDetector(
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: const Color(0xFF6C7A89),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2.5),
                          boxShadow: const [BoxShadow(color: Colors.black45, offset: Offset(0, 4))],
                        ),
                        child: const Center(
                          child: Icon(Icons.settings_rounded, color: Colors.white, size: 28),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              const SlydeLogo(size: 72),
              const SizedBox(height: 48),

              // Game Modes
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      GameModeButton(
                        title: 'PLAY LEVELS',
                        subtitle: 'Embark on the journey!',
                        color: const Color(0xFF8CD83A),
                        icon: Icons.play_arrow_rounded,
                        onTap: () {
                          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LevelsScreen()));
                        },
                      ),
                      const SizedBox(height: 24),
                      // Daily Puzzle
                      Stack(
                        children: [
                          GameModeButton(
                            title: 'DAILY PUZZLE',
                            subtitle: dailySub,
                            color: const Color(0xFFFF5757),
                            icon: dailyStage >= 3 ? Icons.check_circle_rounded : Icons.calendar_today_rounded,
                            onTap: () {
                              Navigator.of(context).push(
                                PageRouteBuilder(
                                  transitionDuration: const Duration(milliseconds: 400),
                                  pageBuilder: (ctx, a, sec) => const DailyScreen(),
                                  transitionsBuilder: (ctx, a, sec, child) => FadeTransition(
                                    opacity: CurvedAnimation(parent: a, curve: Curves.easeOut),
                                    child: child,
                                  ),
                                ),
                              );
                            },
                          ),
                          // Streak badge
                          if (appState.streak > 0)
                            Positioned(
                              top: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: T.gold,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.black, width: 2),
                                  boxShadow: const [BoxShadow(color: Colors.black45, offset: Offset(0, 2))],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.local_fire_department_rounded, color: Colors.black, size: 16),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${appState.streak}',
                                      style: GoogleFonts.luckiestGuy(fontSize: 16, color: Colors.black),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      GameModeButton(
                        title: 'MULTIPLAYER',
                        subtitle: 'Duel your friends',
                        color: const Color(0xFFFFDE59),
                        icon: Icons.people_rounded,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const MultiplayerSetupScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      GameModeButton(
                        title: 'RANDO GAME',
                        subtitle: appState.randoSolved > 0
                            ? '${appState.randoSolved}/30 levels · mixed challenges'
                            : 'Every level a different game',
                        color: const Color(0xFF9C27B0),
                        icon: Icons.shuffle_rounded,
                        onTap: () {
                          Navigator.of(context).push(
                            PageRouteBuilder(
                              transitionDuration:
                                  const Duration(milliseconds: 400),
                              pageBuilder: (ctx, a, sec) =>
                                  const RandoLevelsScreen(),
                              transitionsBuilder: (ctx, a, sec, child) =>
                                  FadeTransition(
                                opacity: CurvedAnimation(
                                    parent: a, curve: Curves.easeOut),
                                child: child,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
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
