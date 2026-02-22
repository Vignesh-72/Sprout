import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';

class PlantConnectionLoader extends StatefulWidget {
  final VoidCallback onCancel;

  const PlantConnectionLoader({super.key, required this.onCancel});

  @override
  State<PlantConnectionLoader> createState() => _PlantConnectionLoaderState();
}

class _PlantConnectionLoaderState extends State<PlantConnectionLoader> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  // Humorous messages to display during the connection process
  final List<String> _loadingMessages = [
    "Searching for Sprout signal...",
    "Pinging the roots...",
    "Translating photosynthesis...",
    "Asking the leaves how they feel...",
    "Measuring good vibes...",
    "Deciphering plant wiggles...",
    "Handshaking with nature...",
    "Calibrating chlorophyll sensors..."
  ];

  String _currentMessage = "Searching for Sprout signal...";
  Timer? _textTimer;

  @override
  void initState() {
    super.initState();
    
    // Setup the pulse animation
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    // Cycle through humorous messages every 1.8 seconds
    int index = 0;
    _textTimer = Timer.periodic(const Duration(milliseconds: 1800), (timer) {
      if (mounted) {
        setState(() {
          index = (index + 1) % _loadingMessages.length;
          _currentMessage = _loadingMessages[index];
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _textTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        color: SproutColors.deepOlive.withOpacity(0.96), // Dark overlay matching theme
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // --- PULSING RADAR ANIMATION ---
              Stack(
                alignment: Alignment.center,
                children: [
                  // Outer Animated Ripple
                  ScaleTransition(
                    scale: Tween<double>(begin: 0.8, end: 1.6).animate(
                      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
                    ),
                    child: FadeTransition(
                      opacity: Tween<double>(begin: 0.5, end: 0.0).animate(
                        CurvedAnimation(parent: _controller, curve: Curves.easeOut),
                      ),
                      child: Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: SproutColors.sageAccent.withOpacity(0.3),
                        ),
                      ),
                    ),
                  ),
                  
                  // Inner Static Circle with Icon
                  Container(
                    width: 110,
                    height: 110,
                    decoration: const BoxDecoration(
                      color: SproutColors.creamWhite,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 20,
                          spreadRadius: 2,
                        )
                      ],
                    ),
                    child: const Icon(
                      Icons.energy_savings_leaf,
                      size: 55,
                      color: SproutColors.deepOlive,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 50),
              
              // --- DYNAMIC STATUS TEXT ---
              SizedBox(
                height: 60, 
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  child: Text(
                    _currentMessage,
                    key: ValueKey<String>(_currentMessage),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.dmSans(
                      color: SproutColors.creamWhite,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // --- CANCEL BUTTON ---
              TextButton(
                onPressed: widget.onCancel,
                style: TextButton.styleFrom(
                  foregroundColor: SproutColors.sageAccent,
                ),
                child: Text(
                  "Stop Listening",
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    decoration: TextDecoration.underline,
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}