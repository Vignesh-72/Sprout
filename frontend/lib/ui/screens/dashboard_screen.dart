import 'dart:ui';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../theme/app_colors.dart';
import '../../services/bluetooth_service.dart';
import '../../services/plant_mood_service.dart';
import '../../services/api_service.dart';
import '../widgets/plant_connection_loader.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with AutomaticKeepAliveClientMixin {
  final _ble = SproutBluetoothService();
  final TextEditingController _nameController = TextEditingController();
  
  bool _isConnecting = false;
  bool _loadingAnalytics = false;

  String _plantName = "Sprout";
  String _careTip = "Enter my name above to get specific tips!";
  String _diseaseInfo = "I can tell you my common sicknesses if you identify me.";
  
  List<dynamic> _weeklyStats = [];
  String _weeklyReport = "Analyzing biological history...";

  @override
  bool get wantKeepAlive => true; 

  @override
  void initState() {
    super.initState();
    _initializeDashboard();
  }

  Future<void> _initializeDashboard() async {
    await _loadAllCachedData(); 
    _fetchWeeklyAnalytics(); 
  }

  Future<void> _loadAllCachedData() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    setState(() {
      _plantName = prefs.getString('plant_name') ?? "Sprout";
      _careTip = prefs.getString('care_tip') ?? "Enter my name above to get specific tips!";
      _diseaseInfo = prefs.getString('disease_info') ?? "I can tell you my common sicknesses if you identify me.";
      _weeklyReport = prefs.getString('weekly_report') ?? "Analyzing biological history...";
      
      String? statsJson = prefs.getString('weekly_stats');
      if (statsJson != null && statsJson.isNotEmpty) {
        _weeklyStats = jsonDecode(statsJson);
      }
    });
  }

  Future<void> _fetchWeeklyAnalytics() async {
    if (!mounted) return;
    setState(() => _loadingAnalytics = true);
    
    final data = await SproutApiService.getWeeklyAnalytics();
    
    if (mounted && data.isNotEmpty) {
      final newStats = data['daily_stats'] ?? [];
      final newReport = data['report_card'] ?? "No data yet.";

      setState(() {
        _weeklyStats = newStats;
        _weeklyReport = newReport;
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('weekly_stats', jsonEncode(newStats));
      await prefs.setString('weekly_report', newReport);
    }
    if (mounted) setState(() => _loadingAnalytics = false);
  }

  Future<void> _fetchAndCachePlantInfo(String name) async {
    if (name.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    setState(() => _plantName = name);
    await prefs.setString('plant_name', name);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Asking Sprout Brain...")));
    final data = await SproutApiService.getPlantCareProfile(name);
    if (data.isNotEmpty) {
      setState(() {
        _careTip = data['tip'] ?? "Keep me happy!";
        _diseaseInfo = data['diseases'] ?? "No info available.";
      });
      await prefs.setString('care_tip', _careTip);
      await prefs.setString('disease_info', _diseaseInfo);
    }
  }

  Future<void> _handleConnect() async {
    setState(() => _isConnecting = true);
    await _ble.scanAndConnect();
    if (mounted) setState(() => _isConnecting = false);
  }

  void _showNameDialog() {
    showDialog(
      context: context, 
      builder: (ctx) => AlertDialog(
        title: const Text("Who am I?"),
        content: TextField(
          controller: _nameController, 
          decoration: const InputDecoration(hintText: "e.g. Tomato, Rose")
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _fetchAndCachePlantInfo(_nameController.text);
            }, 
            child: const Text("Save Identity")
          )
        ],
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); 

    return Scaffold(
      backgroundColor: SproutColors.deepOlive,
      body: StreamBuilder<fbp.BluetoothConnectionState>(
        stream: _ble.connectionStream,
        initialData: fbp.BluetoothConnectionState.disconnected,
        builder: (context, conn) {
          final isConnected = conn.data == fbp.BluetoothConnectionState.connected;

          return StreamBuilder<Map<String, dynamic>>(
            stream: _ble.sensorStream,
            initialData: _ble.lastKnownData,
            builder: (context, snapshot) {
              final data = snapshot.data ?? _ble.lastKnownData;
              final mood = PlantMoodService.analyze(data); 

              return Stack(
                children: [
                  Positioned.fill(
                    child: SafeArea(
                      child: Column(
                        children: [
                          const SizedBox(height: 40), 
                          GestureDetector(
                            onTap: _showNameDialog,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(_plantName, style: GoogleFonts.dmSans(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold)),
                                const SizedBox(width: 8),
                                const Icon(Icons.edit, color: Colors.white54, size: 20)
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Icon(Icons.eco, size: 80, color: isConnected ? Colors.white : Colors.white24),
                          const SizedBox(height: 10),
                          isConnected 
                            ? Chip(label: const Text("Connected"), backgroundColor: Colors.greenAccent, avatar: const Icon(Icons.bluetooth_connected, size: 16))
                            : ElevatedButton.icon(
                                icon: const Icon(Icons.bluetooth),
                                label: const Text("Connect Hardware"),
                                onPressed: _handleConnect,
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: SproutColors.deepOlive),
                              ),

                          const Spacer(),

                          Transform.translate(
                            offset: const Offset(0, -120), 
                            child: Opacity(
                              opacity: 0.9, 
                              child: Column(
                                children: [
                                  const Icon(Icons.eco, color: SproutColors.sageAccent, size: 30),
                                  const SizedBox(height: 5),
                                  Text("Sprout v1.0", style: GoogleFonts.dmSans(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                                  Text("AI-Powered Plant Companion", style: GoogleFonts.dmSans(color: Colors.white70, fontSize: 14)),
                                  const SizedBox(height: 15),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 40),
                                    child: Text(
                                      "Sprout bridges nature and technology by giving your plants a voice through smart sensors and AI.",
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.dmSans(color: Colors.white54, fontSize: 12, height: 1.5),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      _buildBadge("Flutter"),
                                      const SizedBox(width: 10),
                                      _buildBadge("FastAPI"),
                                      const SizedBox(width: 10),
                                      _buildBadge("Python"),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const Spacer(), 
                        ],
                      ),
                    ),
                  ),

                  DraggableScrollableSheet(
                    initialChildSize: 0.66, 
                    minChildSize: 0.18, 
                    maxChildSize: 0.9, 
                    snap: true,         
                    snapSizes: const [0.18, 0.66, 0.9], 
                    builder: (context, scrollController) {
                      return Container(
                        decoration: const BoxDecoration(
                          color: SproutColors.creamWhite, 
                          borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
                          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, spreadRadius: 2)]
                        ),
                        child: ListView(
                          controller: scrollController,
                          padding: const EdgeInsets.all(32),
                          children: [
                            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)))),
                            const SizedBox(height: 20),
                            
                            Text("Live Vitals", style: GoogleFonts.dmSans(fontSize: 22, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 15),
                            // Map over sensor comments
                            ...mood.sensorComments.map((c) => _buildVitalCard(c, data)).toList(),
                            
                            const SizedBox(height: 30),
                            Text("My Needs", style: GoogleFonts.dmSans(fontSize: 22, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 10),
                            _buildInfoCard(Icons.lightbulb, "Pro Tip", _careTip, Colors.orange),
                            const SizedBox(height: 10),
                            _buildInfoCard(Icons.medical_services, "Threats", _diseaseInfo, Colors.redAccent),

                            const SizedBox(height: 30),
                            Text("Botanist's Report", style: GoogleFonts.dmSans(fontSize: 22, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            _buildWeeklyReportCard(),

                            const SizedBox(height: 30),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("Weekly Pulse", style: GoogleFonts.dmSans(fontSize: 22, fontWeight: FontWeight.bold)),
                                if (_loadingAnalytics) const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2)),
                              ],
                            ),
                            const SizedBox(height: 15),
                            _buildChartSection(), 
                            const SizedBox(height: 100),
                          ],
                        ),
                      );
                    },
                  ),
                  
                  if (_isConnecting) 
                    Positioned.fill(child: PlantConnectionLoader(onCancel: () => setState(() => _isConnecting = false))),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildWeeklyReportCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: SproutColors.sage.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: SproutColors.deepOlive.withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.eco, color: SproutColors.deepOlive, size: 18),
              ),
              const SizedBox(width: 10),
              Text("LATEST INSIGHT", style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w900, color: SproutColors.deepOlive, letterSpacing: 1.2)),
            ],
          ),
          const SizedBox(height: 14),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 250), 
            child: SingleChildScrollView(
              child: Text(
                _weeklyReport,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  height: 1.6,
                  color: Colors.black.withOpacity(0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVitalCard(SensorComment comment, Map<String, dynamic> data) {
    String val = "--";
    String label = comment.label;

    if (label.startsWith("Temp")) val = "${data['t'] ?? 0}°C";
    
    // ⭐ RENAMED: Changed display name from Soil to Moist
    if (label.startsWith("Soil")) {
      val = "${data['s'] ?? 0}%";
      label = "Moist"; 
    }
    
    if (label.startsWith("Light")) val = "${data['l'] ?? 0}%";
    if (label.startsWith("Humid")) val = "${data['h'] ?? 0}%"; 
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Row(children: [
        Icon(comment.icon, color: comment.moodColor),
        const SizedBox(width: 15),
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
        const Spacer(),
        Text(val, style: GoogleFonts.dmSans(fontSize: 18, fontWeight: FontWeight.bold)),
      ]),
    );
  }

  Widget _buildInfoCard(IconData icon, String title, String content, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: color.withOpacity(0.06), borderRadius: BorderRadius.circular(20)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(icon, color: color, size: 20), const SizedBox(width: 10), Text(title, style: const TextStyle(fontWeight: FontWeight.bold))]),
        const SizedBox(height: 10),
        Text(content, style: GoogleFonts.inter(fontSize: 14, height: 1.4)),
      ]),
    );
  }
  
  Widget _buildBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text, style: GoogleFonts.dmSans(color: Colors.white70, fontSize: 10)),
    );
  }

  Widget _buildChartSection() {
    if (_weeklyStats.isEmpty) return const SizedBox(height: 100, child: Center(child: Text("No history yet.")));
    return Container(
      height: 220, 
      padding: const EdgeInsets.only(top: 20, right: 10),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 100,
          barTouchData: BarTouchData(enabled: false), 
          titlesData: FlTitlesData(
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 50, 
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  String text = '';
                  if (value == 0) text = 'Dry';
                  else if (value == 50) text = 'Moist';
                  else if (value == 100) text = 'Wet';
                  return Text(text, style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold));
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                  if (value.toInt() >= 0 && value.toInt() < days.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(days[value.toInt()], style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 50, 
            getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey[200], strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          barGroups: _weeklyStats.asMap().entries.map((entry) {
            final index = entry.key;
            final moistVal = (entry.value['avg_soil'] ?? 0.0).toDouble(); // Internal key remains avg_soil for logic
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: moistVal,
                  color: moistVal < 30 ? Colors.redAccent : SproutColors.waterBlue,
                  width: 14,
                  borderRadius: BorderRadius.circular(4),
                  backDrawRodData: BackgroundBarChartRodData(show: true, toY: 100, color: Colors.grey[100]),
                )
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}