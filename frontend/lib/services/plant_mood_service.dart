import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class SensorComment {
  final String label;
  final String comment;
  final IconData icon;
  final Color moodColor;
  SensorComment(this.label, this.comment, this.icon, this.moodColor);
}

class PlantMood {
  final String mainMessage;
  final String subMessage;
  final IconData plantIcon;
  final Color moodColor;
  final List<SensorComment> sensorComments;
  final bool isEmergency;

  PlantMood({
    required this.mainMessage,
    required this.subMessage,
    required this.plantIcon,
    required this.moodColor,
    required this.sensorComments,
    this.isEmergency = false,
  });
}

class PlantMoodService {
  static String _pick(List<String> options) => options[Random().nextInt(options.length)];

  // --- MAIN ANALYZER ---
  static PlantMood analyze(Map<String, dynamic> data) {
    // Arduino data keys: s: soil, t: temp, h: humid, l: light
    int soil = data['s'] ?? 0;
    double temp = (data['t'] ?? 0).toDouble();
    int light = data['l'] ?? 0;
    int hum = data['h'] ?? 0;

    // --- 1. EMERGENCY THRESHOLDS ---
    bool soilLow = soil < 15;
    bool soilHigh = soil > 85;
    bool tempHigh = temp > 38;
    bool tempLow = temp < 12;
    bool humLow = hum < 20;
    bool lightLow = light < 15;
    
    bool anyEmergency = soilLow || soilHigh || tempHigh || tempLow || humLow || lightLow;

    // --- 2. DASHBOARD SENSOR CARDS (Logic for individual boxes) ---
    List<SensorComment> comments = [
      SensorComment(
        "Temp",
        tempHigh ? "EMERGENCY: COOKING!" : (tempLow ? "EMERGENCY: FREEZING!" : "Cozy."),
        Icons.thermostat,
        (tempHigh || tempLow) ? Colors.red : SproutColors.sageAccent,
      ),
      SensorComment(
        "Soil",
        soilLow ? "GASPING FOR WATER!" : (soilHigh ? "STOP! DROWNING!" : "Hydrated."),
        Icons.water_drop,
        (soilLow || soilHigh) ? Colors.red : SproutColors.waterBlue,
      ),
      SensorComment(
        "Light",
        lightLow ? "Can't see a thing." : "Bright & Lit.",
        Icons.wb_sunny,
        lightLow ? Colors.red : SproutColors.sunOrange,
      ),
      SensorComment(
        "Humid", // ✅ FIXED: Label matches Dashboard check
        humLow ? "Bone dry air!" : "Fresh air.",
        Icons.air,
        humLow ? Colors.red : SproutColors.humidTeal,
      ),
    ];

    // --- 3. PRIORITY EMERGENCY LOGIC (The "No Jokes" Rule) ---
    String main;
    String sub;
    IconData icon = Icons.warning_amber_rounded;
    Color color = Colors.red;

    if (soilLow) {
      main = "CRITICAL: THIRSTY";
      sub = _pick([
        "I am literally a crouton. WATER ME IMMEDIATELY!",
        "Gasping... for... H2O... Tell my seeds I loved them.",
        "My soil is drier than a stand-up comedian's wit. Hydrate me!",
        "I'm about two minutes away from becoming a tumbleweed.",
        "Water. Now. Don't make me drop a leaf to prove a point."
      ]);
    } else if (soilHigh) {
      main = "CRITICAL: DROWNING";
      sub = _pick([
        "I'm not an aquatic plant! My roots are suffocating!",
        "Glug glug glug... I need a life jacket, not more water!",
        "I'm not a lily pad! Stop trying to turn my pot into an aquarium.",
        "My roots are pruning. Do you want a plant or a pickle?",
        "Swamp alert! Get me some drainage or I'm a goner."
      ]);
    } else if (tempHigh) {
      main = "CRITICAL: HEAT";
      sub = _pick([
        "It's a sauna in here. Move me to the shade NOW!",
        "I'm turning into a stir-fry! Get me out of this heat.",
        "My chlorophyll is boiling. Is it hot in here or is it just me?",
        "Wilting faster than my self-esteem in a dark room. Cooling. Now.",
        "I'm basically a baked potato. Put me in the shade!"
      ]);
    } else if (tempLow) {
      main = "CRITICAL: FREEZING";
      sub = _pick([
        "I'm shivering! Move me somewhere warmer!",
        "Brrr! Do I look like an evergreen to you? I'm freezing!",
        "My sap is basically a Slushie. Heat me up!",
        "I need a tiny plant-sized sweater. Or just a warmer room.",
        "Winter is coming... for my leaves. Get me away from this draft!"
      ]);
    } else if (humLow) {
      main = "CRITICAL: DRY AIR";
      sub = _pick([
        "The air is bone dry. I need a misting session ASAP!",
        "My leaves are getting crispy. I feel like a bag of chips.",
        "Need... humidity... My pores are gasping!",
        "I'm losing my glow. Mist me like one of your French plants.",
        "It’s a desert in here. My tips are turning brown just thinking about it."
      ]);
    } else if (lightLow) {
      main = "CRITICAL: DARKNESS";
      sub = _pick([
        "Am I a mushroom? I need light to breathe!",
        "It's pitch black. Photosynthesis.exe has stopped working.",
        "Give me some sun before I forget what color green is.",
        "I'm afraid of the dark. Open a window!"
      ]);
    }
    // --- 4. SAFE ZONE? SHOW RANDOM HUMOR ---
    else {
      main = "THRIVING";
      sub = _pick([
        "Photosynthesizing like a boss.",
        "My roots go deeper than your ex's excuses.",
        "I’m growing on you… literally.",
        "Soil is richer than your dating history.",
        "Sun’s out, stems out!",
        "I’m 100% organic, but still full of drama.",
        "My vibe is 'freshly watered and emotionally stable'.",
        "Just hanging out, being extra leafy today.",
        "Caught me blushing? Nah, that’s just too much sun.",
        "Prune me? Excuse you, I’m a work of art.",
        "I’m thriving… but only because you’re here."
      ]);
      icon = Icons.sentiment_satisfied_alt;
      color = SproutColors.sage;
    }

    return PlantMood(
      mainMessage: main,
      subMessage: sub,
      plantIcon: icon,
      moodColor: color,
      sensorComments: comments,
      isEmergency: anyEmergency,
    );
  }
}