import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../core/theme.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../widgets/logo_widget.dart';
import '../home/home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _authService = AuthService();

  bool _register = false;
  bool _loading = false;
  bool _showPassword = false;
  String? _error;

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  late final AnimationController _shakeAnim;
  late final AnimationController _fadeAnim;
  late final Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _shakeAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeIn = CurvedAnimation(parent: _fadeAnim, curve: Curves.easeOut);
    _fadeAnim.forward();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _shakeAnim.dispose();
    _fadeAnim.dispose();
    super.dispose();
  }

  void _toggleMode() {
    setState(() {
      _register = !_register;
      _error = null;
    });
    _fadeAnim.forward(from: 0);
  }

  void _setError(String msg) {
    setState(() {
      _error = msg;
      _loading = false;
    });
    _shakeAnim.forward(from: 0);
    HapticFeedback.lightImpact();
  }

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    final name = _nameCtrl.text.trim();

    if (!email.contains('@') || email.length < 5) {
      _setError('Enter a valid email');
      return;
    }
    if (password.length < 8) {
      _setError('Password must be at least 8 characters');
      return;
    }
    if (_register && name.length < 2) {
      _setError('Enter your display name');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final user = _register
          ? await _authService.register(
              name: name,
              email: email,
              password: password,
            )
          : await _authService.login(email: email, password: password);

      if (!mounted) return;
      await context.read<AppState>().onAuthenticated(user);

      if (!mounted) return;
      HapticFeedback.heavyImpact();
      _goHome();
    } on ApiException catch (e) {
      final body = e.body;
      String msg = e.message;
      if (body != null && body['errors'] is Map) {
        final errs = body['errors'] as Map;
        final first = errs.values.first;
        if (first is List && first.isNotEmpty) msg = first.first.toString();
      }
      _setError(msg);
    } catch (_) {
      _setError('Something went wrong. Check your connection.');
    }
  }

  void _goHome() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (ctx, a, sec) => const HomeScreen(),
        transitionsBuilder: (ctx, a, sec, child) => FadeTransition(
          opacity: CurvedAnimation(parent: a, curve: Curves.easeOut),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: T.bg,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          Container(decoration: const BoxDecoration(gradient: T.bgGrad)),
          Positioned(
            top: -100,
            right: -80,
            child: _GlowOrb(color: T.classic, size: 320),
          ),
          Positioned(
            bottom: -80,
            left: -80,
            child: _GlowOrb(color: T.daily, size: 240),
          ),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeIn,
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),
                      const Center(child: SlydeLogo(size: 56)),
                      const SizedBox(height: 40),
                      Text(
                        _register ? 'Create your account ✨' : 'Welcome back 👋',
                        style: T.display(28),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _register
                            ? 'Track your streaks, best moves, and duels'
                            : 'Sign in to sync your progress',
                        style: T.body.copyWith(color: T.white(0.45)),
                      ),
                      const SizedBox(height: 36),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 250),
                        child: _register
                            ? _LabeledField(
                                label: 'DISPLAY NAME',
                                icon: Icons.person_outline_rounded,
                                controller: _nameCtrl,
                                focus: _nameFocus,
                                hint: 'Sam',
                                shakeAnim: _shakeAnim,
                                hasError: _error != null,
                                onSubmitted: (_) =>
                                    _emailFocus.requestFocus(),
                              )
                            : const SizedBox.shrink(),
                      ),
                      if (_register) const SizedBox(height: 18),
                      _LabeledField(
                        label: 'EMAIL',
                        icon: Icons.alternate_email_rounded,
                        controller: _emailCtrl,
                        focus: _emailFocus,
                        hint: 'you@example.com',
                        shakeAnim: _shakeAnim,
                        hasError: _error != null,
                        keyboardType: TextInputType.emailAddress,
                        onSubmitted: (_) => _passwordFocus.requestFocus(),
                      ),
                      const SizedBox(height: 18),
                      _LabeledField(
                        label: 'PASSWORD',
                        icon: Icons.lock_outline_rounded,
                        controller: _passwordCtrl,
                        focus: _passwordFocus,
                        hint: 'at least 8 characters',
                        shakeAnim: _shakeAnim,
                        hasError: _error != null,
                        obscure: !_showPassword,
                        trailing: IconButton(
                          onPressed: () => setState(
                              () => _showPassword = !_showPassword),
                          icon: Icon(
                            _showPassword
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                            color: T.white(0.45),
                            size: 18,
                          ),
                        ),
                        onSubmitted: (_) => _submit(),
                      ),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 250),
                        child: _error != null
                            ? Padding(
                                padding:
                                    const EdgeInsets.only(top: 10, left: 4),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.error_outline_rounded,
                                      color: T.timeAttack,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        _error!,
                                        style: TextStyle(
                                          color: T.timeAttack,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                      const SizedBox(height: 32),
                      _PrimaryBtn(
                        label: _register ? 'Create Account' : 'Sign In',
                        icon: _register
                            ? Icons.person_add_alt_1_rounded
                            : Icons.login_rounded,
                        color: _register ? T.daily : T.classic,
                        loading: _loading,
                        onTap: _submit,
                      ),
                      const SizedBox(height: 24),
                      Center(
                        child: GestureDetector(
                          onTap: _toggleMode,
                          child: RichText(
                            text: TextSpan(
                              style: T.caption.copyWith(fontSize: 13),
                              children: [
                                TextSpan(
                                  text: _register
                                      ? 'Already have an account? '
                                      : "Don't have an account? ",
                                ),
                                TextSpan(
                                  text: _register ? 'Sign in' : 'Create one',
                                  style: TextStyle(
                                    color: T.accent(T.classic, 0.9),
                                    decoration: TextDecoration.underline,
                                    decorationColor:
                                        T.accent(T.classic, 0.4),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  final String label;
  final IconData icon;
  final TextEditingController controller;
  final FocusNode focus;
  final String hint;
  final AnimationController shakeAnim;
  final bool hasError;
  final bool obscure;
  final TextInputType? keyboardType;
  final Widget? trailing;
  final ValueChanged<String>? onSubmitted;

  const _LabeledField({
    required this.label,
    required this.icon,
    required this.controller,
    required this.focus,
    required this.hint,
    required this.shakeAnim,
    required this.hasError,
    this.obscure = false,
    this.keyboardType,
    this.trailing,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: T.caption.copyWith(letterSpacing: 1.5, fontSize: 10),
        ),
        const SizedBox(height: 10),
        AnimatedBuilder(
          animation: shakeAnim,
          builder: (ctx, child) {
            final s = sin(shakeAnim.value * pi * 5);
            return Transform.translate(
              offset: Offset(hasError ? s * 6 : 0, 0),
              child: child,
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: T.white(0.05),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: hasError
                    ? T.accent(T.timeAttack, 0.6)
                    : T.white(0.1),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Icon(icon, color: T.white(0.45), size: 20),
                ),
                Expanded(
                  child: TextField(
                    controller: controller,
                    focusNode: focus,
                    obscureText: obscure,
                    keyboardType: keyboardType,
                    autocorrect: false,
                    enableSuggestions: false,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      hintText: hint,
                      hintStyle:
                          TextStyle(color: T.white(0.25), fontSize: 15),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 18),
                    ),
                    onSubmitted: onSubmitted,
                  ),
                ),
                if (trailing != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: trailing,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PrimaryBtn extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool loading;
  final VoidCallback onTap;
  const _PrimaryBtn({
    required this.label,
    required this.icon,
    required this.color,
    required this.loading,
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
        if (!widget.loading) widget.onTap();
      },
      onTapCancel: () => setState(() => _down = false),
      child: AnimatedScale(
        scale: _down ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
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
          child: Center(
            child: widget.loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
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
      ),
    );
  }
}

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
