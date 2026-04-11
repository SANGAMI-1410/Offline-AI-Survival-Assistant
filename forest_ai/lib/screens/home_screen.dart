import 'package:flutter/material.dart';
import 'camera_screen.dart';
import 'map_screen.dart';
import '../services/database_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final db = DatabaseService.instance;

    return Scaffold(
      backgroundColor: const Color(0xFF1a2e1a),
      body: SafeArea(
        child: Column(
          children: [
            // App bar area
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                children: [
                  const Text(
                    'ForestAI',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFf0ede6),
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Identify any fruit instantly',
                    style: TextStyle(
                      fontSize: 15,
                      color: Color(0xFFa8d5a2),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Circular SCAN PLANT button
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CameraScreen()),
                );
              },
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    colors: [Color(0xFF3d6b3d), Color(0xFF2d4a2d)],
                  ),
                  border: Border.all(
                    color: const Color(0xFFa8d5a2),
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFa8d5a2).withValues(alpha: 0.3),
                      blurRadius: 30,
                      spreadRadius: 8,
                    ),
                  ],
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.camera_alt,
                      size: 80,
                      color: Color(0xFFa8d5a2),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'SCAN PLANT',
                      style: TextStyle(
                        color: Color(0xFFf0ede6),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 40),

            // GPS MAP button
            OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MapScreen()),
                );
              },
              icon: const Icon(Icons.map, color: Color(0xFFe8a020)),
              label: const Text(
                'GPS MAP',
                style: TextStyle(
                  color: Color(0xFFe8a020),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 14),
                side: const BorderSide(color: Color(0xFFe8a020), width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),

            const Spacer(),

            // Bottom dataset info bar
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              color: const Color(0xFF0d1a0d),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.storage,
                    size: 18,
                    color: Color(0xFFa8d5a2),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      db.forestName,
                      style: const TextStyle(
                        color: Color(0xFFf0ede6),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF27ae60),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'LOADED · ${db.plants.length} plants',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
