import 'package:flutter/material.dart';
import 'ui/screens/start_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: StartScreen(),
  ));
}