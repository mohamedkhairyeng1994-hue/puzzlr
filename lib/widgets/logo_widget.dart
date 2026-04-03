import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SlydeLogo extends StatelessWidget {
  final double size;
  const SlydeLogo({super.key, this.size = 64});

  @override
  Widget build(BuildContext context) {
    return GameTitleText('PUZZLR', size: size);
  }
}

class GameTitleText extends StatelessWidget {
  final String text;
  final double size;
  const GameTitleText(this.text, {this.size = 64, super.key});

  @override
  Widget build(BuildContext context) {
    final styleBase = GoogleFonts.luckiestGuy(
      fontSize: size,
      letterSpacing: 2,
    );

    return Center(
      child: Stack(
        children: [
          // Outer Black Stroke
          Text(
            text,
            style: styleBase.copyWith(
              foreground: Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = 14
                ..color = Colors.black,
            ),
          ),
          // Inner Red Stroke
          Text(
            text,
            style: styleBase.copyWith(
              foreground: Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = 8
                ..color = const Color(0xFFD40000), // Deep red
            ),
          ),
          // Inner Fill Yellow
          Text(
            text,
            style: styleBase.copyWith(
              color: const Color(0xFFFFDE59), // Bright yellow
            ),
          ),
        ],
      ),
    );
  }
}
