import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/soil_monitoring_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Soil Monitoring for Eggplant Farming',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4DB6AC)),
        useMaterial3: true,
        textTheme: const TextTheme(
          titleLarge: TextStyle(fontWeight: FontWeight.w700),
          bodyMedium: TextStyle(height: 1.3),
        ),
      ),
      home: const SoilMonitoringScreen(),
    );
  }
}

