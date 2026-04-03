import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/app_state.dart';
import '../../core/theme.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Player Profile', style: T.h2.copyWith(fontSize: 20)),
        centerTitle: true,
      ),
      body: AnimatedBg(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: MediaQuery.of(context).padding.top + 80,
            bottom: 40,
          ),
          child: Column(
            children: [
              // Avatar Section
              Center(
                child: GlassCard(
                  radius: 100,
                  glow: T.classic,
                  padding: const EdgeInsets.all(20),
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [T.classic, T.timeAttack],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text('Puzzlr Master', style: T.display(32)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: T.daily.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: T.daily.withValues(alpha: 0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded, color: T.daily, size: 18),
                    const SizedBox(width: 6),
                    Text('Level 42', style: T.caption.copyWith(color: T.white(0.9), fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // Stats Grid
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      title: 'Current Streak',
                      value: '${appState.streak} Days',
                      icon: Icons.local_fire_department_rounded,
                      color: T.duel,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _StatCard(
                      title: 'Puzzles Solved',
                      value: '${appState.unlockedCount * 3 + 12}', // Fake mock data metric based on unlocks
                      icon: Icons.grid_on_rounded,
                      color: T.classic,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      title: 'Powerups Used',
                      value: '142',
                      icon: Icons.bolt_rounded,
                      color: T.gold,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _StatCard(
                      title: 'Time Played',
                      value: '12h 4m',
                      icon: Icons.timer_rounded,
                      color: T.timeAttack,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 48),
              
              // Progression Card
              GlassCard(
                glow: T.timeAttack,
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.trending_up_rounded, color: Colors.white, size: 28),
                        const SizedBox(width: 12),
                        Text('Next Rank: Grandmaster', style: T.h2.copyWith(fontSize: 18)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: const LinearProgressIndicator(
                        value: 0.72,
                        minHeight: 12,
                        backgroundColor: Colors.white12,
                        valueColor: AlwaysStoppedAnimation(T.timeAttack),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Text('7,200 / 10,000 XP', style: T.caption),
                    )
                  ],
                ),
              ),

              const SizedBox(height: 56),

              // Logout Button
              GestureDetector(
                onTap: () => _logout(context),
                child: Container(
                  height: 64,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white10, width: 2),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.logout_rounded, color: T.timeAttack, size: 24),
                      const SizedBox(width: 12),
                      Text(
                        'LOGOUT',
                        style: T.display(20).copyWith(color: T.timeAttack),
                      ),
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

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    if (!context.mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 16),
          Text(value, style: T.h2.copyWith(fontSize: 22)),
          const SizedBox(height: 4),
          Text(title, style: T.caption.copyWith(color: T.white(0.6))),
        ],
      ),
    );
  }
}
