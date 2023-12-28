import 'dart:math';

import 'package:find_your_way_admin/login/login.dart';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late Animation<double> _textAnimation;
  late Animation<double> _fadeInAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller)
      ..addListener(() {
        setState(() {});
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _controller.stop();
        }
      });

    _textAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.0, 0.8, curve: Curves.easeIn)),
    );

    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.8, 1.0, curve: Curves.easeIn)),
    );

    _controller.forward();

    Future.delayed(const Duration(seconds: 6), () {
      Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const Login(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
          ));
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          // Animated Gradient Triangles
          CustomPaint(
            painter: GradientTrianglePainter(_animation.value, context),
            child: Container(),
          ),
          // Logo in the center
          Center(
            child: Opacity(
              opacity: _textAnimation.value.clamp(0.0, 1.0),
              child: Image.asset(
                'assets/logo.png',
                width: 200,
                height: 200,
              ),
            ),
          ),
          // Animated Text "Find Your Way"
          Positioned(
            bottom: 60,
            child: Opacity(
              opacity: _textAnimation.value.clamp(0.0, 1.0),
              child: const Text(
                "Find Your Way - Admin",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          // Fade-in Text "made by Davide Paolillo"
          Positioned(
            bottom: 40,
            child: Opacity(
              opacity: _fadeInAnimation.value,
              child: const Text("made by Davide Paolillo",
                  style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}

class GradientTrianglePainter extends CustomPainter {
  final double progress;
  final BuildContext context;

  GradientTrianglePainter(this.progress, this.context);

  @override
  void paint(Canvas canvas, Size size) {
    // Gradient and Triangle Setup
    var topGradient = const LinearGradient(
      colors: [
        Color.fromARGB(255, 255, 143, 102),
        Color.fromARGB(255, 252, 224, 9)
      ],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ).createShader(Rect.fromLTRB(0, 0, size.width, size.height * 0.5));

    // Bottom Triangle Gradient
    var bottomGradient = const LinearGradient(
      colors: [
        Color.fromARGB(255, 214, 6, 127),
        Color.fromARGB(255, 208, 0, 255)
      ],
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
    ).createShader(
        Rect.fromLTRB(0, size.height * 0.5, size.width, size.height));

    var topTrianglePaint = Paint()
      ..shader = topGradient
      ..style = PaintingStyle.fill;

    var bottomTrianglePaint = Paint()
      ..shader = bottomGradient
      ..style = PaintingStyle.fill;

    // Draw Top Triangle
    var topPath = Path();
    topPath.moveTo(0, 0);
    topPath.lineTo(size.width, size.height * progress);
    topPath.lineTo(size.width, 0);
    topPath.close();
    canvas.drawPath(topPath, topTrianglePaint);

    // Draw Bottom Triangle
    var bottomPath = Path();
    bottomPath.moveTo(size.width, size.height);
    bottomPath.lineTo(0, size.height * (1 - progress));
    bottomPath.lineTo(0, size.height);
    bottomPath.close();
    canvas.drawPath(bottomPath, bottomTrianglePaint);

    // Draw Progressive Black Line along the hypotenuse of the top triangle
    if (progress >= 0.5) {
      var linePaint = Paint()
        ..color = const Color.fromARGB(255, 255, 255, 255)
        ..strokeWidth = 3;

      // Normalize progress for the second half of the animation
      double lineProgress = max(0, (progress - 0.5) * 2);

      // Center point of the screen
      double centerX = size.width / 2;
      double centerY = size.height / 2;

      // Calculate start and end points along the hypotenuse of the top triangle
      Offset start = Offset(centerX + centerX * lineProgress / 2,
          centerY + centerY * lineProgress / 2);
      Offset end = Offset(centerX - centerX * lineProgress / 2,
          centerY - centerY * lineProgress / 2);

      canvas.drawLine(start, end, linePaint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

class AnimatedTextPainter extends CustomPainter {
  final double progress;
  final String text;

  AnimatedTextPainter(this.progress, this.text);

  @override
  void paint(Canvas canvas, Size size) {
    TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Color(0xffef476f),
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout(maxWidth: size.width);

    // Calculate the portion of the text to be shown
    double textWidth = textPainter.width * progress;

    canvas.save();
    canvas.clipRect(Rect.fromLTRB(0, 0, textWidth, textPainter.height));
    textPainter.paint(canvas, const Offset(0, 0));
    canvas.restore();
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
