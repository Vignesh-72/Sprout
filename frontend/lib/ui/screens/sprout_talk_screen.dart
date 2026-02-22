import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_colors.dart';
import '../../services/bluetooth_service.dart';
import '../../services/api_service.dart';
import '../../services/plant_mood_service.dart';

class SproutTalkScreen extends StatefulWidget {
  const SproutTalkScreen({super.key});

  @override
  State<SproutTalkScreen> createState() => _SproutTalkScreenState();
}

class _SproutTalkScreenState extends State<SproutTalkScreen> {
  final ble = SproutBluetoothService();
  final TextEditingController _chatController = TextEditingController();
  
  StreamSubscription? _sensorSubscription;
  Timer? _rotationTimer;

  String _currentMessage = "Connect to Sprout to start chatting...";
  String _plantName = "Sprout";
  bool _isThinking = false;
  bool _isAiGenerated = false;
  bool _isEmergency = false;

  DateTime _lastTextUpdateTime = DateTime.now().subtract(const Duration(minutes: 1));
  String _lastMoodState = "";

  @override
  void initState() {
    super.initState();
    _loadName();
    _initListeners();
    _startLogicLoop();
  }

  Future<void> _loadName() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) setState(() => _plantName = prefs.getString('plant_name') ?? "Sprout");
  }

  void _initListeners() {
    _sensorSubscription = ble.sensorStream.listen((data) {
      if (!_isAiGenerated && !_isThinking) _checkAndApplySensorUpdate();
    });
  }

  void _startLogicLoop() {
    _rotationTimer?.cancel();
    _rotationTimer = Timer.periodic(const Duration(seconds: 45), (timer) {
      if (mounted && !_isThinking && !_isAiGenerated) _forceNewUpdate();
    });
  }

  void _checkAndApplySensorUpdate() {
    final data = ble.lastKnownData;
    final mood = PlantMoodService.analyze(data);
    bool stateChanged = mood.mainMessage != _lastMoodState;
    bool cooldownOver = DateTime.now().difference(_lastTextUpdateTime).inSeconds > 40;

    if (stateChanged || cooldownOver) {
      setState(() {
        _currentMessage = mood.subMessage;
        _isEmergency = mood.isEmergency;
        _lastMoodState = mood.mainMessage;
        _lastTextUpdateTime = DateTime.now();
      });
    }
  }

  void _forceNewUpdate() {
    final data = ble.lastKnownData;
    final mood = PlantMoodService.analyze(data);
    if (mounted) {
      setState(() {
        _currentMessage = mood.subMessage;
        _isEmergency = mood.isEmergency;
        _lastMoodState = mood.mainMessage;
        _lastTextUpdateTime = DateTime.now();
      });
    }
  }

  Future<void> _handleUserChat() async {
    if (_chatController.text.trim().isEmpty || _isThinking) return;
    String txt = _chatController.text.trim();
    _chatController.clear();
    FocusScope.of(context).unfocus();

    setState(() {
      _isThinking = true;
      _isAiGenerated = false;
      _currentMessage = "Consulting the mycelial network...";
    });

    try {
      String reply = await SproutApiService.chatWithPlant(txt, ble.lastKnownData, _plantName);
      if (mounted) {
        setState(() {
          _isThinking = false;
          _currentMessage = reply;
          _isAiGenerated = true;
          _isEmergency = false; 
          _lastTextUpdateTime = DateTime.now();
        });

        Future.delayed(const Duration(seconds: 60), () {
          if (mounted && _isAiGenerated) {
            setState(() => _isAiGenerated = false);
            _forceNewUpdate();
          }
        });
      }
    } catch (e) {
      if (mounted) setState(() { _isThinking = false; _currentMessage = "Connection to roots lost."; });
    }
  }

  @override
  void dispose() {
    _rotationTimer?.cancel();
    _sensorSubscription?.cancel();
    _chatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = _isEmergency ? Colors.red[900]! : SproutColors.deepOlive;

    return Scaffold(
      backgroundColor: bgColor,
      // Stack remains for the chat capsule positioning, but glow is removed
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildHeroIcon(),
                        const SizedBox(height: 40),
                        _buildMessageArea(),
                      ],
                    ),
                  ),
                ),
                _buildChatCapsule(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroIcon() {
    return Stack(
      alignment: Alignment.center,
      children: [
        if (_isThinking)
          const SizedBox(
            width: 140,
            height: 140,
            child: CircularProgressIndicator(
              color: Colors.white24,
              strokeWidth: 2,
            ),
          ),
        Container(
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.05),
          ),
          child: Icon(
            _isEmergency ? Icons.warning_amber_rounded : Icons.eco,
            size: 70,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildMessageArea() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
      child: Text(
        _currentMessage,
        key: ValueKey(_currentMessage),
        textAlign: TextAlign.center,
        style: GoogleFonts.dmSans(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: Colors.white.withOpacity(0.9),
          height: 1.4,
        ),
      ),
    );
  }

  Widget _buildChatCapsule() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(25, 0, 25, 25),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.07),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _chatController,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    decoration: InputDecoration(
                      hintText: "Talk to your plant...",
                      hintStyle: GoogleFonts.dmSans(color: Colors.white24),
                      border: InputBorder.none,
                    ),
                    onSubmitted: (_) => _handleUserChat(),
                  ),
                ),
                _isThinking
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : IconButton(
                        onPressed: _handleUserChat,
                        icon: const Icon(Icons.arrow_upward_rounded, color: Colors.white70),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}