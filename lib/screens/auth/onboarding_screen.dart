import 'dart:math';
import 'package:flutter/material.dart';

import '../../core/theme.dart';
import 'permissions_screen.dart';

// ── Onboarding data ───────────────────────────────────────────────────────────

class _Page {
  final String emoji;
  final String title;
  final String body;
  final Color accent;
  final List<Color> gradColors;
  const _Page({
    required this.emoji,
    required this.title,
    required this.body,
    required this.accent,
    required this.gradColors,
  });
}

const _pages = [
  _Page(
    emoji: '🧩',
    title: 'Slide & Solve',
    body:
        'Tap tiles next to the empty space to slide them into the right order. Simple to learn — tough to master.',
    accent: T.classic,
    gradColors: [Color(0xFF0D0F2E), Color(0xFF050714)],
  ),
  _Page(
    emoji: '🎨',
    title: 'Mystery Reveal',
    body:
        'Tiles start as shadows. Every piece you place correctly bursts into full color — revealing the hidden image.',
    accent: T.daily,
    gradColors: [Color(0xFF061A12), Color(0xFF050714)],
  ),
  _Page(
    emoji: '⚡',
    title: 'Race the Clock',
    body:
        'Time Attack, Daily Challenges, Duels — compete with friends or beat your own best score every single day.',
    accent: T.duel,
    gradColors: [Color(0xFF1A1006), Color(0xFF050714)],
  ),
];

// ── OnboardingScreen ──────────────────────────────────────────────────────────

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final _controller = PageController();
  int _page = 0;

  late AnimationController _floatAnim;

  @override
  void initState() {
    super.initState();
    _floatAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    _floatAnim.dispose();
    super.dispose();
  }

  void _next() {
    if (_page < _pages.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _goLogin();
    }
  }

  void _goLogin() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (ctx, a, sec) => const PermissionsScreen(),
        transitionsBuilder: (ctx, a, sec, child) => FadeTransition(
          opacity: CurvedAnimation(parent: a, curve: Curves.easeOut),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = _pages[_page];
    return Scaffold(
      backgroundColor: T.bg,
      body: Stack(
        children: [
          // Animated background gradient per page
          AnimatedContainer(
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: p.gradColors,
              ),
            ),
          ),

          // Decorative glow
          AnimatedPositioned(
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOut,
            top: -80,
            right: _page == 0 ? -60 : (_page == 1 ? 60.0 : -30.0),
            child: _GlowOrb(color: p.accent, size: 300),
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOut,
            bottom: 80,
            left: _page == 2 ? -40.0 : -80.0,
            child: _GlowOrb(color: p.accent, size: 200),
          ),

          // Pages
          SafeArea(
            child: Column(
              children: [
                // Skip
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12, right: 20),
                    child: GestureDetector(
                      onTap: _goLogin,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: T.white(0.07),
                          borderRadius: BorderRadius.circular(40),
                          border: Border.all(color: T.white(0.1)),
                        ),
                        child: Text(
                          'Skip',
                          style: TextStyle(
                            color: T.white(0.5),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Content
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    onPageChanged: (i) => setState(() => _page = i),
                    itemCount: _pages.length,
                    itemBuilder: (ctx, i) => _PageContent(
                      page: _pages[i],
                      floatAnim: _floatAnim,
                      isActive: i == _page,
                    ),
                  ),
                ),

                // Bottom: dots + button
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 0, 28, 40),
                  child: Column(
                    children: [
                      // Page dots
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_pages.length, (i) {
                          final active = i == _page;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOut,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: active ? 24 : 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: active ? p.accent : T.white(0.2),
                              borderRadius: BorderRadius.circular(4),
                              boxShadow: active
                                  ? [
                                      BoxShadow(
                                        color: T.accent(p.accent, 0.5),
                                        blurRadius: 8,
                                      ),
                                    ]
                                  : null,
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 28),
                      // CTA button
                      GestureDetector(
                        onTap: _next,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeOut,
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                p.accent,
                                Color.lerp(p.accent, Colors.white, 0.15)!,
                              ],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(40),
                            boxShadow: [
                              BoxShadow(
                                color: T.accent(p.accent, 0.4),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              _page == _pages.length - 1
                                  ? "Let's Go"
                                  : 'Continue',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
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

// ── Page Content ──────────────────────────────────────────────────────────────

class _PageContent extends StatelessWidget {
  final _Page page;
  final AnimationController floatAnim;
  final bool isActive;
  const _PageContent({
    required this.page,
    required this.floatAnim,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Floating emoji illustration
          AnimatedBuilder(
            animation: floatAnim,
            builder: (ctx, _) {
              final dy = sin(floatAnim.value * pi) * 12;
              return Transform.translate(
                offset: Offset(0, dy),
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    color: T.accent(page.accent, 0.08),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: T.accent(page.accent, 0.2),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: T.accent(page.accent, 0.2),
                        blurRadius: 40,
                        spreadRadius: -8,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      page.emoji,
                      style: const TextStyle(fontSize: 70),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 44),
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: T
                .display(34)
                .copyWith(
                  foreground: Paint()
                    ..shader = LinearGradient(
                      colors: [Colors.white, page.accent],
                    ).createShader(const Rect.fromLTWH(0, 0, 300, 50)),
                ),
          ),
          const SizedBox(height: 16),
          Text(
            page.body,
            textAlign: TextAlign.center,
            style: T.body.copyWith(
              fontSize: 15,
              height: 1.65,
              color: T.white(0.55),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Glow orb ─────────────────────────────────────────────────────────────────

class _GlowOrb extends StatelessWidget {
  final Color color;
  final double size;
  const _GlowOrb({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [T.accent(color, 0.2), Colors.transparent],
        ),
      ),
    );
  }
}
