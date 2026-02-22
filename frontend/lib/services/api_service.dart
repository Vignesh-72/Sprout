import 'dart:convert';
import 'package:http/http.dart' as http;

class SproutApiService {
  // ✅ YOUR LIVE BACKEND URL
  static const String _baseUrl = "https://sprout-backend-g3ok.onrender.com"; 

  // 1. Get Care Profile
  static Future<Map<String, dynamic>> getPlantCareProfile(String plantName) async {
    try {
      final response = await http.post(
        Uri.parse("$_baseUrl/plant/care_profile"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"plant_name": plantName}),
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (e) { print("Care Profile Error: $e"); }
    return {};
  }

  // 2. Chat with Plant
  static Future<String> chatWithPlant(String message, Map<String, dynamic> sensors, String plantName) async {
    try {
      final response = await http.post(
        Uri.parse("$_baseUrl/chat"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_message": message,
          "current_sensors": sensors,
          "plant_name": plantName
        }),
      );
      if (response.statusCode == 200) return jsonDecode(response.body)['reply'];
    } catch (e) { print("Chat Error: $e"); }
    return "I'm focusing on growing right now... (Connection Error)";
  }

  // 3. Update Sensors (Logging only)
  static Future<void> updateSensors(int s, double t, int h, int l) async {
    try {
      await http.post(
        Uri.parse("$_baseUrl/update_sensors"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"soil_moisture": s, "temperature": t, "humidity": h, "light_level": l}),
      );
    } catch (e) { print("Update Error: $e"); }
  }

  // 4. Analytics
  static Future<Map<String, dynamic>> getWeeklyAnalytics() async {
    try {
      final response = await http.get(Uri.parse("$_baseUrl/analytics/week"));
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (e) { print("Analytics Error: $e"); }
    return {};
  }
}