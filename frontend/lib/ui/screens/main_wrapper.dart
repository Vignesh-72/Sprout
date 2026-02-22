import 'package:flutter/material.dart';
import 'sprout_talk_screen.dart';
import 'dashboard_screen.dart';
import 'settings_about_screen.dart'; // New import
import '../../theme/app_colors.dart';

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  // Start at index 1 so the Sprout Talk screen is the first thing users see
  final PageController _controller = PageController(initialPage: 1);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SproutColors.deepOlive,
      body: PageView(
        controller: _controller,
        physics: const BouncingScrollPhysics(),
        children: const [
          SproutTalkScreen(), // Page 0: Swipe Left from Center
          DashboardScreen(),    // Page 1: Center (Home)
          SettingsAboutScreen(),     // Page 2: Swipe Right from Center
        ],
      ),
    );
  }
}