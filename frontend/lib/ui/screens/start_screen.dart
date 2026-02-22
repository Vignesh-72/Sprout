import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart'; // Needed for the safety check
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';
import 'main_wrapper.dart';

class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> with TickerProviderStateMixin {
  late AnimationController _entranceController;
  late AnimationController _breathingController;

  late Animation<double> _logoScaleAnim;
  late Animation<Offset> _textSlideAnim;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _buttonSlideAnim;

  @override
  void initState() {
    super.initState();

    // 1. Setup Controllers
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2), // Total entrance time
    );

    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    // 2. Define Animations
    _logoScaleAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _textSlideAnim = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.3, 0.8, curve: Curves.easeOutQuart),
      ),
    );

    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeIn),
      ),
    );

    _buttonSlideAnim = Tween<Offset>(begin: const Offset(0, 1.0), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.6, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    // 3. 🚀 FORCE START after build
    // This ensures the animation plays even if the frame takes a moment to load
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _entranceController.forward().then((_) {
        // Only start breathing loop after entrance is 100% done
        if (mounted) _breathingController.repeat(reverse: true);
      });
    });
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _breathingController.dispose();
    super.dispose();
  }

  void _onStartPressed() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const MainWrapper(),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SproutColors.deepOlive,
      body: SafeArea(
        child: AnimatedBuilder(
          // Bind the builder to the main controller so it rebuilds on every tick
          animation: _entranceController, 
          builder: (context, child) {
            return Column(
              children: [
                const Spacer(),

                // --- LOGO ---
                ScaleTransition(
                  scale: _logoScaleAnim,
                  child: AnimatedBuilder(
                    animation: _breathingController,
                    builder: (ctx, child) {
                      final breathe = 1.0 + (_breathingController.value * 0.05);
                      return Transform.scale(
                        scale: breathe,
                        child: Container(
                          padding: const EdgeInsets.all(30),
                          decoration: BoxDecoration(
                            color: SproutColors.creamWhite,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 30,
                                spreadRadius: 5,
                                offset: const Offset(0, 10),
                              )
                            ],
                          ),
                          child: const Icon(Icons.eco, size: 80, color: SproutColors.deepOlive),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 40),

                // --- TEXT ---
                SlideTransition(
                  position: _textSlideAnim,
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: Column(
                      children: [
                        Text(
                          "SPROUT",
                          style: GoogleFonts.dmSans(
                            fontSize: 48,
                            fontWeight: FontWeight.w900,
                            color: SproutColors.creamWhite,
                            letterSpacing: 4,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "By Vignesh, Umar, Vikram & Shashasthri",
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.white54,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const Spacer(),

                // --- BUTTON ---
                SlideTransition(
                  position: _buttonSlideAnim,
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
                      child: SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: ElevatedButton(
                          onPressed: _onStartPressed,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: SproutColors.creamWhite,
                            foregroundColor: SproutColors.deepOlive,
                            elevation: 5,
                            shadowColor: Colors.black45,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Get Started",
                                style: GoogleFonts.dmSans(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward_rounded, size: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}