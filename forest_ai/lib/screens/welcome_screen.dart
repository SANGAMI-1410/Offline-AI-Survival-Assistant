import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/database_service.dart';
import 'home_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool _isLoading = false;

  Future<void> _pickAndLoadDataset() async {
    setState(() => _isLoading = true);
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        final File file = File(result.files.single.path!);
        final String jsonString = await file.readAsString();

        DatabaseService.instance.loadFromJson(jsonString);

        if (DatabaseService.instance.isLoaded && mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        } else if (mounted) {
          _showError('Invalid JSON format or empty dataset.');
        }
      }
    } catch (e) {
      if (mounted) {
        _showError('Error loading file: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFc0392b),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a2e1a),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Forest icon
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF2d4a2d),
                    border: Border.all(
                      color: const Color(0xFFa8d5a2),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.forest,
                    size: 70,
                    color: Color(0xFFa8d5a2),
                  ),
                ),
                const SizedBox(height: 32),

                // App name
                const Text(
                  'ForestAI',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFf0ede6),
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),

                // Tagline
                const Text(
                  'Your offline survival guide',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFFa8d5a2),
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 16),

                // Offline badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2d4a2d),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFa8d5a2)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.wifi_off, size: 16, color: Color(0xFFa8d5a2)),
                      SizedBox(width: 8),
                      Text(
                        'Works 100% offline',
                        style: TextStyle(
                          color: Color(0xFFa8d5a2),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 60),

                // Upload button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _pickAndLoadDataset,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF1a2e1a),
                            ),
                          )
                        : const Icon(Icons.upload_file),
                    label: Text(
                      _isLoading ? 'Loading...' : 'Upload Forest Dataset',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFa8d5a2),
                      foregroundColor: const Color(0xFF1a2e1a),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                const Text(
                  'Select your plants.json file to begin',
                  style: TextStyle(
                    color: Color(0xFF6a8a6a),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
