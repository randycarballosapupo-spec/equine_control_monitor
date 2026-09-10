import 'dart:async';
import 'package:flutter/material.dart';
import '../service/app_language.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.languageController});

  final AppLanguageController languageController;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController progressController;
  Timer? navigationTimer;

  @override
  void initState() {
    super.initState();
    progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();
    navigationTimer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) Navigator.pushReplacementNamed(context, '/');
    });
  }

  @override
  void dispose() {
    navigationTimer?.cancel();
    progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/splash_horses.jpg', fit: BoxFit.cover),
          Container(color: Colors.black.withValues(alpha: 0.22)),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 48, 28, 36),
              child: Column(
                children: [
                  const Spacer(),
                  Image.asset('assets/images/equi_harmony_logo.png', width: 150, height: 150),
                  const SizedBox(height: 18),
                  const Text(
                    'Equi Harmony Monitor',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  AnimatedBuilder(
                    animation: progressController,
                    builder: (context, _) => LinearProgressIndicator(
                      value: progressController.value,
                      minHeight: 5,
                      borderRadius: BorderRadius.circular(8),
                      backgroundColor: Colors.white54,
                      color: Colors.white,
                    ),
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
