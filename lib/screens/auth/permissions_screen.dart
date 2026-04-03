import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/theme.dart';
import 'login_screen.dart';

// ── Permission item data ──────────────────────────────────────────────────────

class _PermItem {
  final Permission permission;
  final IconData icon;
  final Color color;
  final String title;
  final String reason;
  PermissionStatus status = PermissionStatus.denied;

  _PermItem({
    required this.permission,
    required this.icon,
    required this.color,
    required this.title,
    required this.reason,
  });
}

// ── PermissionsScreen ─────────────────────────────────────────────────────────

class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen>
    with TickerProviderStateMixin {
  late final List<_PermItem> _items;
  late final List<AnimationController> _anims;
  late final List<Animation<double>> _fades;

  bool _checking = true;

  @override
  void initState() {
    super.initState();

    _items = [
      _PermItem(
        permission: Permission.notification,
        icon: Icons.notifications_outlined,
        color: T.classic,
        title: 'Notifications',
        reason: 'Daily puzzle reminders & challenge alerts',
      ),
      _PermItem(
        permission: Permission.contacts,
        icon: Icons.people_outline_rounded,
        color: T.duel,
        title: 'Contacts',
        reason: 'Invite friends to Duel Mode',
      ),
      _PermItem(
        permission: Permission.appTrackingTransparency,
        icon: Icons.track_changes_outlined,
        color: T.custom,
        title: 'Tracking',
        reason: 'Personalise your experience & show relevant content',
      ),
    ];

    _anims = List.generate(
      _items.length,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 450),
      ),
    );
    _fades = _anims
        .map((a) => CurvedAnimation(parent: a, curve: Curves.easeOut))
        .toList();

    _init();
  }

  Future<void> _init() async {
    // Check current statuses
    for (final item in _items) {
      item.status = await item.permission.status;
    }
    if (!mounted) return;
    setState(() => _checking = false);

    // Staggered entrance
    for (int i = 0; i < _anims.length; i++) {
      await Future.delayed(Duration(milliseconds: 80 * i));
      if (mounted) _anims[i].forward();
    }
  }

  Future<void> _request(_PermItem item, int idx) async {
    final result = await item.permission.request();
    if (!mounted) return;
    setState(() => item.status = result);

    if (result.isPermanentlyDenied) {
      await openAppSettings();
    }
  }

  void _continue() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (ctx, a, sec) => const LoginScreen(),
        transitionsBuilder: (ctx, a, sec, child) => FadeTransition(
          opacity: CurvedAnimation(parent: a, curve: Curves.easeOut),
          child: child,
        ),
      ),
    );
  }

  @override
  void dispose() {
    for (final a in _anims) {
      a.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: T.bg,
      body: Stack(
        children: [
          Container(decoration: const BoxDecoration(gradient: T.bgGrad)),
          // Glow blobs
          Positioned(
            top: -80,
            right: -80,
            child: _GlowOrb(color: T.classic, size: 280),
          ),
          Positioned(
            bottom: -60,
            left: -60,
            child: _GlowOrb(color: T.duel, size: 220),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 26),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 32),

                  // ── Header ──────────────────────────────────────────────────
                  Center(
                    child: Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        color: T.accent(T.classic, 0.12),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: T.accent(T.classic, 0.3),
                          width: 1.5,
                        ),
                        boxShadow: [T.glowShadow(T.classic)],
                      ),
                      child: const Icon(
                        Icons.shield_outlined,
                        color: T.classic,
                        size: 32,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: Text(
                      'Allow Access',
                      style: T.display(30),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'Puzzlr works better with these permissions.\nAll are optional — tap to allow.',
                      textAlign: TextAlign.center,
                      style: T.body.copyWith(color: T.white(0.45), height: 1.6),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // ── Permission cards ─────────────────────────────────────────
                  if (_checking)
                    const Expanded(
                      child: Center(
                        child: CircularProgressIndicator(
                          color: T.classic,
                          strokeWidth: 2,
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: Column(
                        children: List.generate(_items.length, (i) {
                          return FadeTransition(
                            opacity: _fades[i],
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0, 0.12),
                                end: Offset.zero,
                              ).animate(_fades[i]),
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: _PermCard(
                                  item: _items[i],
                                  onTap: () => _request(_items[i], i),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),

                  // ── Bottom buttons ───────────────────────────────────────────
                  Column(
                    children: [
                      _PrimaryBtn(
                        label: 'Continue',
                        icon: Icons.arrow_forward_rounded,
                        color: T.classic,
                        onTap: _continue,
                      ),
                      const SizedBox(height: 14),
                      GestureDetector(
                        onTap: _continue,
                        child: Center(
                          child: Text(
                            'Skip for now',
                            style: T.caption.copyWith(
                              fontSize: 13,
                              color: T.white(0.35),
                              decoration: TextDecoration.underline,
                              decorationColor: T.white(0.2),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Permission Card ───────────────────────────────────────────────────────────

class _PermCard extends StatefulWidget {
  final _PermItem item;
  final VoidCallback onTap;
  const _PermCard({required this.item, required this.onTap});

  @override
  State<_PermCard> createState() => _PermCardState();
}

class _PermCardState extends State<_PermCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final granted = item.status.isGranted;
    final denied = item.status.isPermanentlyDenied;

    return GestureDetector(
      onTapDown: granted ? null : (_) => setState(() => _pressed = true),
      onTapUp: granted
          ? null
          : (_) {
              setState(() => _pressed = false);
              widget.onTap();
            },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: granted ? T.accent(item.color, 0.09) : T.white(0.04),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: granted
                  ? T.accent(item.color, 0.4)
                  : denied
                  ? T.accent(T.timeAttack, 0.3)
                  : T.white(0.09),
              width: 1.5,
            ),
            boxShadow: granted ? [T.glowShadow(item.color)] : null,
          ),
          child: Row(
            children: [
              // Icon badge
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: T.accent(item.color, granted ? 0.18 : 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: T.accent(item.color, granted ? 0.45 : 0.2),
                    width: 1,
                  ),
                ),
                child: Icon(
                  item.icon,
                  color: granted ? item.color : T.white(0.4),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),

              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: TextStyle(
                        color: granted ? Colors.white : T.white(0.75),
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.reason,
                      style: T.caption.copyWith(
                        fontSize: 12,
                        color: T.white(granted ? 0.5 : 0.35),
                      ),
                    ),
                    if (denied)
                      Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: Text(
                          'Tap to open Settings',
                          style: TextStyle(
                            color: T.accent(T.timeAttack, 0.8),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // Status indicator
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: granted
                    ? Container(
                        key: const ValueKey('granted'),
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: T.accent(item.color, 0.2),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: T.accent(item.color, 0.5),
                            width: 1.5,
                          ),
                        ),
                        child: Icon(
                          Icons.check_rounded,
                          color: item.color,
                          size: 16,
                        ),
                      )
                    : Container(
                        key: const ValueKey('allow'),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: T.accent(item.color, 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: T.accent(item.color, 0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          denied ? 'Open' : 'Allow',
                          style: TextStyle(
                            color: item.color,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
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

// ── Primary button ────────────────────────────────────────────────────────────

class _PrimaryBtn extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _PrimaryBtn({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  State<_PrimaryBtn> createState() => _PrimaryBtnState();
}

class _PrimaryBtnState extends State<_PrimaryBtn> {
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
        scale: _down ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                widget.color,
                Color.lerp(widget.color, Colors.white, 0.15)!,
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: T.accent(widget.color, 0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Text(
                widget.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
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
          colors: [T.accent(color, 0.18), Colors.transparent],
        ),
      ),
    );
  }
}
