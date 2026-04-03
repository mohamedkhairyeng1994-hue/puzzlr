import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme.dart';
import '../../widgets/logo_widget.dart';
import '../home/home_screen.dart';

// ── LoginScreen ───────────────────────────────────────────────────────────────

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  // Steps: 0 = enter phone, 1 = enter OTP
  int _step = 0;

  final _phoneCtrl = TextEditingController();
  final _phoneFocus = FocusNode();

  // 4 OTP digit controllers
  final List<TextEditingController> _otpCtrl = List.generate(
    4,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _otpFocus = List.generate(4, (_) => FocusNode());

  String _selectedCode = '+966';
  bool _loading = false;
  String? _error;

  // Simulated OTP (in real app this comes from backend)
  String _fakeOtp = '';

  late AnimationController _shakeAnim;
  late AnimationController _fadeAnim;
  late Animation<double> _fadeIn;

  static const _codes = ['+966', '+1', '+44', '+971', '+20', '+90'];

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
    _phoneCtrl.dispose();
    _phoneFocus.dispose();
    for (final c in _otpCtrl) {
      c.dispose();
    }
    for (final f in _otpFocus) {
      f.dispose();
    }
    _shakeAnim.dispose();
    _fadeAnim.dispose();
    super.dispose();
  }

  // ── Phone submission ────────────────────────────────────────────────────────

  void _submitPhone() async {
    final phone = _phoneCtrl.text.trim();
    if (phone.length < 7) {
      _setError('Enter a valid phone number');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    await Future.delayed(const Duration(milliseconds: 1200));
    // Generate fake OTP
    _fakeOtp = (1000 + Random().nextInt(8999)).toString();
    debugPrint('🔐 OTP (dev only): $_fakeOtp');
    if (!mounted) return;
    setState(() {
      _loading = false;
      _step = 1;
    });
    _fadeAnim.forward(from: 0);
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _otpFocus[0].requestFocus();
    });
  }

  // ── OTP verification ────────────────────────────────────────────────────────

  void _verifyOtp() async {
    final otp = _otpCtrl.map((c) => c.text).join();
    if (otp.length < 4) {
      _setError('Enter the 4-digit code');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;

    if (otp == _fakeOtp) {
      // Save login state
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString(
        'phone',
        '$_selectedCode ${_phoneCtrl.text.trim()}',
      );
      if (!mounted) return;
      HapticFeedback.heavyImpact();
      _goHome();
    } else {
      setState(() {
        _loading = false;
      });
      _setError('Incorrect code. Try again.');
      _shakeAnim.forward(from: 0);
      for (final c in _otpCtrl) {
        c.clear();
      }
      _otpFocus[0].requestFocus();
    }
  }

  void _setError(String msg) {
    setState(() {
      _error = msg;
      _loading = false;
    });
    _shakeAnim.forward(from: 0);
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

  void _backToPhone() {
    for (final c in _otpCtrl) {
      c.clear();
    }
    setState(() {
      _step = 0;
      _error = null;
    });
    _fadeAnim.forward(from: 0);
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _phoneFocus.requestFocus();
    });
  }

  // ── OTP box input handling ─────────────────────────────────────────────────

  void _onOtpChanged(int index, String val) {
    if (val.length == 1 && index < 3) {
      _otpFocus[index + 1].requestFocus();
    }
    if (val.isEmpty && index > 0) {
      _otpFocus[index - 1].requestFocus();
    }
    // Auto-verify when last digit filled
    if (index == 3 && val.isNotEmpty) {
      final full = _otpCtrl.map((c) => c.text).join();
      if (full.length == 4) _verifyOtp();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: T.bg,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // Background
          Container(decoration: const BoxDecoration(gradient: T.bgGrad)),
          // Glow blobs
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
                      // ── Logo ────────────────────────────────────────────────
                      Center(child: _Logo()),
                      const SizedBox(height: 40),

                      // ── Step indicator ──────────────────────────────────────
                      _StepIndicator(step: _step),
                      const SizedBox(height: 36),

                      // ── Content ─────────────────────────────────────────────
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        transitionBuilder: (child, anim) => FadeTransition(
                          opacity: anim,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0.06, 0),
                              end: Offset.zero,
                            ).animate(anim),
                            child: child,
                          ),
                        ),
                        child: _step == 0
                            ? _PhoneStep(
                                key: const ValueKey('phone'),
                                controller: _phoneCtrl,
                                focus: _phoneFocus,
                                selectedCode: _selectedCode,
                                codes: _codes,
                                onCodeChanged: (v) =>
                                    setState(() => _selectedCode = v!),
                                onSubmit: _submitPhone,
                                loading: _loading,
                                error: _error,
                                shakeAnim: _shakeAnim,
                              )
                            : _OtpStep(
                                key: const ValueKey('otp'),
                                phone:
                                    '$_selectedCode ${_phoneCtrl.text.trim()}',
                                controllers: _otpCtrl,
                                focuses: _otpFocus,
                                onChanged: _onOtpChanged,
                                onVerify: _verifyOtp,
                                onBack: _backToPhone,
                                loading: _loading,
                                error: _error,
                                shakeAnim: _shakeAnim,
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

// ── Logo ──────────────────────────────────────────────────────────────────────

class _Logo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const SlydeLogo(size: 56);
  }
}

// ── Step Indicator ────────────────────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  final int step;
  const _StepIndicator({required this.step});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(2, (i) {
        final done = i < step;
        final active = i == step;
        return Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: active ? 32 : 10,
              height: 10,
              decoration: BoxDecoration(
                color: done
                    ? T.daily
                    : active
                    ? T.classic
                    : T.white(0.15),
                borderRadius: BorderRadius.circular(5),
                boxShadow: active
                    ? [
                        BoxShadow(
                          color: T.accent(T.classic, 0.5),
                          blurRadius: 8,
                        ),
                      ]
                    : null,
              ),
              child: done
                  ? const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 8,
                    )
                  : null,
            ),
            if (i < 1) const SizedBox(width: 6),
          ],
        );
      }),
    );
  }
}

// ── Phone Step ────────────────────────────────────────────────────────────────

class _PhoneStep extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focus;
  final String selectedCode;
  final List<String> codes;
  final void Function(String?) onCodeChanged;
  final VoidCallback onSubmit;
  final bool loading;
  final String? error;
  final AnimationController shakeAnim;

  const _PhoneStep({
    super.key,
    required this.controller,
    required this.focus,
    required this.selectedCode,
    required this.codes,
    required this.onCodeChanged,
    required this.onSubmit,
    required this.loading,
    required this.error,
    required this.shakeAnim,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Welcome back 👋', style: T.display(28)),
        const SizedBox(height: 8),
        Text(
          'Enter your phone number to continue',
          style: T.body.copyWith(color: T.white(0.45)),
        ),
        const SizedBox(height: 36),

        // ── Phone field ──────────────────────────────────────────────────────
        Text(
          'PHONE NUMBER',
          style: T.caption.copyWith(letterSpacing: 1.5, fontSize: 10),
        ),
        const SizedBox(height: 10),
        AnimatedBuilder(
          animation: shakeAnim,
          builder: (ctx, child) {
            final s = sin(shakeAnim.value * pi * 5);
            return Transform.translate(
              offset: Offset(error != null ? s * 6 : 0, 0),
              child: child,
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: T.white(0.05),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: error != null
                    ? T.accent(T.timeAttack, 0.6)
                    : T.white(0.1),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                // Country code dropdown
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    border: Border(right: BorderSide(color: T.white(0.1))),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedCode,
                      onChanged: onCodeChanged,
                      dropdownColor: T.surface,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                      icon: Icon(
                        Icons.expand_more_rounded,
                        color: T.white(0.4),
                        size: 18,
                      ),
                      items: codes
                          .map(
                            (c) => DropdownMenuItem(value: c, child: Text(c)),
                          )
                          .toList(),
                    ),
                  ),
                ),
                // Phone number input
                Expanded(
                  child: TextField(
                    controller: controller,
                    focusNode: focus,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                    ),
                    decoration: InputDecoration(
                      hintText: '5XX XXX XXXX',
                      hintStyle: TextStyle(color: T.white(0.25), fontSize: 15),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 18,
                      ),
                    ),
                    onSubmitted: (_) => onSubmit(),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Error text
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          child: error != null
              ? Padding(
                  padding: const EdgeInsets.only(top: 10, left: 4),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        color: T.timeAttack,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        error!,
                        style: TextStyle(
                          color: T.timeAttack,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),

        const SizedBox(height: 32),

        // Send OTP button
        _PrimaryBtn(
          label: 'Send Code',
          icon: Icons.send_rounded,
          color: T.classic,
          loading: loading,
          onTap: onSubmit,
        ),

        const SizedBox(height: 24),
        Center(
          child: Text(
            'We\'ll send a one-time code to verify your number.',
            textAlign: TextAlign.center,
            style: T.caption.copyWith(fontSize: 12, height: 1.6),
          ),
        ),
      ],
    );
  }
}

// ── OTP Step ──────────────────────────────────────────────────────────────────

class _OtpStep extends StatelessWidget {
  final String phone;
  final List<TextEditingController> controllers;
  final List<FocusNode> focuses;
  final void Function(int, String) onChanged;
  final VoidCallback onVerify;
  final VoidCallback onBack;
  final bool loading;
  final String? error;
  final AnimationController shakeAnim;

  const _OtpStep({
    super.key,
    required this.phone,
    required this.controllers,
    required this.focuses,
    required this.onChanged,
    required this.onVerify,
    required this.onBack,
    required this.loading,
    required this.error,
    required this.shakeAnim,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Back link
        GestureDetector(
          onTap: onBack,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 14,
                color: T.white(0.5),
              ),
              const SizedBox(width: 6),
              Text(
                'Change number',
                style: TextStyle(
                  color: T.white(0.5),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),

        Text('Check your SMS 📱', style: T.display(28)),
        const SizedBox(height: 8),
        RichText(
          text: TextSpan(
            style: T.body.copyWith(color: T.white(0.45), height: 1.5),
            children: [
              const TextSpan(text: 'We sent a 4-digit code to\n'),
              TextSpan(
                text: phone,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),

        Text(
          'VERIFICATION CODE',
          style: T.caption.copyWith(letterSpacing: 1.5, fontSize: 10),
        ),
        const SizedBox(height: 14),

        // OTP boxes
        AnimatedBuilder(
          animation: shakeAnim,
          builder: (ctx, child) {
            final s = sin(shakeAnim.value * pi * 5);
            return Transform.translate(
              offset: Offset(error != null ? s * 6 : 0, 0),
              child: child,
            );
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(
              4,
              (i) => _OtpBox(
                controller: controllers[i],
                focusNode: focuses[i],
                onChanged: (v) => onChanged(i, v),
                hasError: error != null,
              ),
            ),
          ),
        ),

        // Error
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          child: error != null
              ? Padding(
                  padding: const EdgeInsets.only(top: 12, left: 4),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        color: T.timeAttack,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        error!,
                        style: TextStyle(
                          color: T.timeAttack,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),

        const SizedBox(height: 36),

        _PrimaryBtn(
          label: 'Verify & Continue',
          icon: Icons.check_circle_outline_rounded,
          color: T.daily,
          loading: loading,
          onTap: onVerify,
        ),

        const SizedBox(height: 24),
        Center(
          child: GestureDetector(
            onTap: onBack,
            child: Text(
              "Didn't receive the code? Resend",
              style: T.caption.copyWith(
                fontSize: 13,
                color: T.accent(T.classic, 0.7),
                decoration: TextDecoration.underline,
                decorationColor: T.accent(T.classic, 0.4),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── OTP Box ───────────────────────────────────────────────────────────────────

class _OtpBox extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final void Function(String) onChanged;
  final bool hasError;
  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.hasError,
  });

  @override
  State<_OtpBox> createState() => _OtpBoxState();
}

class _OtpBoxState extends State<_OtpBox> {
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(() {
      if (mounted) setState(() => _focused = widget.focusNode.hasFocus);
    });
  }

  @override
  Widget build(BuildContext context) {
    final filled = widget.controller.text.isNotEmpty;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 68,
      height: 72,
      decoration: BoxDecoration(
        color: _focused
            ? T.accent(T.classic, 0.12)
            : filled
            ? T.accent(T.daily, 0.08)
            : T.white(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: widget.hasError
              ? T.accent(T.timeAttack, 0.7)
              : _focused
              ? T.classic
              : filled
              ? T.accent(T.daily, 0.5)
              : T.white(0.12),
          width: _focused ? 2 : 1.5,
        ),
        boxShadow: _focused
            ? [BoxShadow(color: T.accent(T.classic, 0.3), blurRadius: 12)]
            : null,
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: widget.focusNode,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: const TextStyle(
          color: Colors.white,
          fontSize: 26,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        ),
        decoration: const InputDecoration(
          border: InputBorder.none,
          counterText: '',
          contentPadding: EdgeInsets.zero,
        ),
        onChanged: widget.onChanged,
      ),
    );
  }
}

// ── Primary Button ────────────────────────────────────────────────────────────

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
