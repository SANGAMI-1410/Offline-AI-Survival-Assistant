import 'package:flutter/material.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'screens/welcome_screen.dart';
import 'services/model_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize tile cache for offline map support
  await FMTCObjectBoxBackend().initialise();
  await FMTCStore('mapStore').manage.create();

  // Load model in background — does not block UI
  ModelService.instance.loadModel().then((_) {
    ModelService.instance.loadLabels();
  });

  runApp(const ForestAiApp());
}

class ForestAiApp extends StatelessWidget {
  const ForestAiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ForestAI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1a2e1a),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF1a2e1a),
        useMaterial3: true,
      ),
      home: const WelcomeScreen(),
    );
  }
}
