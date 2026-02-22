import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';
import '../../services/api_service.dart';

class SettingsAboutScreen extends StatefulWidget {
  const SettingsAboutScreen({super.key});

  @override
  State<SettingsAboutScreen> createState() => _SettingsAboutScreenState();
}

// ⭐ Added Mixin to prevent data vanish during swipes
class _SettingsAboutScreenState extends State<SettingsAboutScreen> with AutomaticKeepAliveClientMixin {
  bool _isApiLive = false;
  bool _checkingStatus = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _checkSystemHealth();
  }

  Future<void> _checkSystemHealth() async {
    if (!mounted) return;
    setState(() => _checkingStatus = true);

    final health = await SproutApiService.getWeeklyAnalytics();
    await Future.delayed(const Duration(milliseconds: 600));

    if (mounted) {
      setState(() {
        _isApiLive = health.isNotEmpty;
        _checkingStatus = false;
      });
    }
  }

  void _showTroubleshootDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A261B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text("Connection Help", style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDialogStep("1", "Sync Wi-Fi", "Phone and PC must match."),
            _buildDialogStep("2", "Start Backend", "Run the Python script."),
            _buildDialogStep("3", "Check IP", "Update api_service.dart."),
            _buildDialogStep("4", "Firewall", "Allow Python access."),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("GOT IT", style: GoogleFonts.inter(color: SproutColors.sageAccent, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  Widget _buildDialogStep(String num, String title, String sub) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(radius: 10, backgroundColor: SproutColors.sageAccent, child: Text(num, style: const TextStyle(fontSize: 10, color: Colors.white))),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          Text(sub, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        ])),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for Mixin
    return Scaffold(
      backgroundColor: SproutColors.deepOlive,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _checkSystemHealth,
          color: SproutColors.sage,
          backgroundColor: SproutColors.creamWhite,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              _buildHeader(),
              const SizedBox(height: 32),

              _buildSectionTitle("INTELLIGENCE HUB"),
              GestureDetector(
                onTap: _isApiLive ? null : _showTroubleshootDialog,
                child: _buildHealthTile(),
              ),
              
              const SizedBox(height: 32),

              _buildSectionTitle("CONNECTIVITY"),
              _buildDarkSettingTile(Icons.bluetooth_searching_rounded, "Neural Link", "HC-05 Hardware: Bonded"),
              _buildDarkSettingTile(Icons.auto_awesome_mosaic_rounded, "AI Services", _isApiLive ? "Render Backend: Active" : "Internal Buffer Only"),

              const SizedBox(height: 40),

              _buildSectionTitle("THE SPROUT ARCHITECTS"),
              _buildTeamCard(),
              
              const SizedBox(height: 40),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHealthTile() {
    Color accentColor = _isApiLive ? Colors.greenAccent : Colors.redAccent;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accentColor.withOpacity(0.2)),
        boxShadow: [
          if (_isApiLive) BoxShadow(color: Colors.green.withOpacity(0.05), blurRadius: 20, spreadRadius: 1)
        ],
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              if (_checkingStatus) 
                const SizedBox(width: 40, height: 40, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white24)),
              Icon(_isApiLive ? Icons.sensors_rounded : Icons.sensors_off_rounded, color: accentColor, size: 32),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_isApiLive ? "Systems Online" : "Link Severed", 
                  style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 4),
                Text(_checkingStatus ? "Syncing..." : (_isApiLive ? "Backend processing active" : "Tap for diagnostics"), 
                  style: GoogleFonts.inter(color: Colors.white38, fontSize: 13)),
              ],
            ),
          ),
          if (!_isApiLive && !_checkingStatus)
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 14),
        ],
      ),
    );
  }

  Widget _buildHeader() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("VERSION 1.0", style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: SproutColors.sageAccent, letterSpacing: 2)),
          const Icon(Icons.info_outline_rounded, color: Colors.white24, size: 20),
        ],
      ),
      Text("Settings", style: GoogleFonts.dmSans(fontSize: 38, fontWeight: FontWeight.bold, color: SproutColors.creamWhite)),
    ],
  );

  Widget _buildSectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 16, left: 4),
    child: Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 11, color: Colors.white24, letterSpacing: 1.5)),
  );

  Widget _buildDarkSettingTile(IconData icon, String title, String sub) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.symmetric(vertical: 8),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.02),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white.withOpacity(0.05)),
    ),
    child: ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), shape: BoxShape.circle),
        child: Icon(icon, color: SproutColors.sageAccent, size: 22),
      ),
      title: Text(title, style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
      subtitle: Text(sub, style: GoogleFonts.inter(color: Colors.white38, fontSize: 12)),
    ),
  );

  Widget _buildTeamCard() => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.03),
      borderRadius: BorderRadius.circular(28),
      border: Border.all(color: Colors.white.withOpacity(0.05)),
    ),
    child: Column(
      children: [
        _buildMemberRow("Vignesh S"),
        const Divider(color: Colors.white10, height: 24),
        _buildMemberRow("Umar Farooq"),
        const Divider(color: Colors.white10, height: 24),
        _buildMemberRow("Vikram M"),
        const Divider(color: Colors.white10, height: 24),
        _buildMemberRow("Shashasthri"),
      ],
    ),
  );

  Widget _buildMemberRow(String name) => Row(
    children: [
      const Icon(Icons.verified_user_rounded, size: 18, color: SproutColors.sageAccent),
      const SizedBox(width: 16),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(name, style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
      ]),
    ],
  );

  Widget _buildFooter() => Column(
    children: [
      Container(width: 40, height: 2, color: SproutColors.sageAccent.withOpacity(0.2)),
      const SizedBox(height: 16),
      Text("STABLE BUILD", style: GoogleFonts.inter(color: Colors.white10, fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.bold)),
    ],
  );
}