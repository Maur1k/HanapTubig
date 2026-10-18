import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'data/station_repository.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const dataSource = String.fromEnvironment(
    'HANAPTUBIG_DATA_SOURCE',
    defaultValue: 'local',
  );
  StationRepository repository = const LocalStationRepository();

  if (dataSource == 'firebase') {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      repository = FirebaseStationRepository();
    } catch (error) {
      debugPrint('Firebase initialization failed; using local mode: $error');
    }
  }

  runApp(HanapTubigApp(repository: repository));
}

class HanapTubigApp extends StatelessWidget {
  const HanapTubigApp({super.key, required this.repository});

  final StationRepository repository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HanapTubig',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: SplashScreen(repository: repository),
    );
  }
}
