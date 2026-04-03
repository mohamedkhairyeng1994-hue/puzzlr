import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class T {
  static const Color bg = Color(0xFF0F2640);
  static const Color surface = Color(0xFF265b82);
  static const Color surfaceHi = Color(0xFF38B6FF);

  static const Color classic = Color(0xFF38B6FF); // Blue
  static const Color timeAttack = Color(0xFFFF5757); // Red
  static const Color daily = Color(0xFF8CD83A); // Green
  static const Color duel = Color(0xFFFFDE59); // Yellow
  static const Color custom = Color(0xFFCB6CE6); // Purple
  static const Color gold = Color(0xFFFFDE59);

  static Color white(double alpha) => Colors.white.withValues(alpha: alpha);
  static Color accent(Color c, double alpha) => c.withValues(alpha: alpha);

  static TextStyle display(double size) => GoogleFonts.luckiestGuy(
    fontSize: size,
    color: const Color(0xFFFFDE59), // Yellow
    letterSpacing: 2.0,
    shadows: [
      const Shadow(color: Colors.black, offset: Offset(0, 3), blurRadius: 0),
    ],
  );

  static final TextStyle h2 = GoogleFonts.luckiestGuy(
    fontSize: 24,
    color: Colors.white,
    letterSpacing: 1.0,
  );

  static final TextStyle caption = GoogleFonts.fredoka(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: Colors.white.withValues(alpha: 0.9),
  );

  static final TextStyle body = GoogleFonts.fredoka(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: Colors.white,
  );

  static BoxDecoration card({Color? glow}) => BoxDecoration(
    color: const Color(0xFF2E7CA8),
    borderRadius: BorderRadius.circular(24),
    border: Border.all(color: Colors.black, width: 3),
    boxShadow: const [
      BoxShadow(color: Colors.black45, offset: Offset(0, 6), blurRadius: 0),
    ],
  );

  static BoxShadow glowShadow(Color color) => BoxShadow(
    color: color,
    blurRadius: 0,
    spreadRadius: -4,
  );

  static const LinearGradient bgGrad = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0F2640), Color(0xFF226290)],
    stops: [0.0, 1.0],
  );
}

// ── Fun Casual Game Panels replacing the Modern Cards ──

class GlassCard extends StatelessWidget {
  final Widget child;
  final double radius;
  final Color? glow;
  final EdgeInsetsGeometry? padding;

  const GlassCard({
    super.key,
    required this.child,
    this.radius = 24, // Chunky radius
    this.glow,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = glow ?? const Color(0xFF2E7CA8);
    // Darken for bottom 3D lip effect
    final hsl = HSLColor.fromColor(bgColor);
    final lipColor = hsl.withLightness(max(0.0, hsl.lightness - 0.15)).toColor();

    return Container(
      decoration: BoxDecoration(
        color: Colors.black, // Dark outline / shadow base
        borderRadius: BorderRadius.circular(radius),
        boxShadow: const [
           BoxShadow(color: Colors.black38, offset: Offset(0, 6), blurRadius: 0),
        ],
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6), // bottom 3D lip
        decoration: BoxDecoration(
          color: lipColor,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: Colors.black, width: 2.5),
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: 2), // Main Face
          padding: padding,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 2), // Top specular highlight
          ),
          child: child,
        ),
      ),
    );
  }
}

// ── Sunburst Casual Game Background ──

class AnimatedBg extends StatefulWidget {
  final Widget child;
  const AnimatedBg({super.key, required this.child});

  @override
  State<AnimatedBg> createState() => _AnimatedBgState();
}

class _AnimatedBgState extends State<AnimatedBg> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 40))..repeat();
  }
  
  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF0A1F33), Color(0xFF1E5279), Color(0xFF1389CD)],
            ),
          ),
        ),
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (ctx, _) => Transform.rotate(
              angle: _ctrl.value * 2 * pi,
              child: CustomPaint(painter: _SunburstPainter()),
            ),
          ),
        ),
        Positioned.fill(
          child: CustomPaint(painter: _StarsPainter()),
        ),
        widget.child,
      ],
    );
  }
}

class _SunburstPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.04);
    final double radius = size.height * 1.5;
    
    // Draw thick rays
    for (int i = 0; i < 20; i++) {
        final angle1 = i * (2 * pi / 20);
        final angle2 = (i + 0.4) * (2 * pi / 20);
        final path = Path()
          ..moveTo(center.dx, center.dy)
          ..lineTo(center.dx + cos(angle1) * radius, center.dy + sin(angle1) * radius)
          ..lineTo(center.dx + cos(angle2) * radius, center.dy + sin(angle2) * radius)
          ..close();
        canvas.drawPath(path, paint);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _StarsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rnd = Random(42);
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.6);
    for (int i = 0; i < 50; i++) {
      final x = rnd.nextDouble() * size.width;
      final y = rnd.nextDouble() * size.height;
      final r = rnd.nextDouble() * 2 + 0.5;
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
