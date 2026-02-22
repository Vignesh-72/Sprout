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
  
  final List<String> _loadingMessages = [
    "Searching for Sprout signal...",
    "Pinging the roots...",
    "Translating photosynthesis...",
    "Asking the leaves how they feel...",
    "Measuring good vibes...",
    "Handshaking with nature...",
  ];

  String _currentMessage = "Searching for Sprout signal...";
  Timer? _textTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

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
    return Container(
      color: SproutColors.deepOlive.withOpacity(0.96),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                ScaleTransition(
                  scale: Tween(begin: 0.8, end: 1.6).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut)),
                  child: FadeTransition(
                    opacity: Tween(begin: 0.5, end: 0.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut)),
                    child: Container(width: 160, height: 160, decoration: BoxDecoration(shape: BoxShape.circle, color: SproutColors.sage.withOpacity(0.3))),
                  ),
                ),
                Container(
                  width: 110, height: 110,
                  decoration: const BoxDecoration(color: SproutColors.creamWhite, shape: BoxShape.circle),
                  child: const Icon(Icons.energy_savings_leaf, size: 55, color: SproutColors.deepOlive),
                ),
              ],
            ),
            const SizedBox(height: 50),
            Text(
              _currentMessage,
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(color: SproutColors.creamWhite, fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 30),
            TextButton(
              onPressed: widget.onCancel,
              style: TextButton.styleFrom(foregroundColor: SproutColors.sage),
              child: const Text("Stop Listening"),
            )
          ],
        ),
      ),
    );
  }
}