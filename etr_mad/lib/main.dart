import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    runApp(const HanapTubigApp());
  } catch (e) {
    print('Error initializing Firebase: $e');
    runApp(const HanapTubigApp());
  }
}

class HanapTubigApp extends StatelessWidget {
  const HanapTubigApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HanapTubig',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: SplashScreen(),
    );
  }
}
