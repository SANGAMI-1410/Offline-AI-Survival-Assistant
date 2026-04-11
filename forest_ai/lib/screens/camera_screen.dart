import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/model_service.dart';
import '../services/database_service.dart';
import '../models/plant_model.dart';
import 'result_screen.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  File? _selectedImage;
  bool _isAnalyzing = false;
  bool _isPicking = false;

  Future<void> _pickImage(ImageSource source) async {
    if (_isPicking) return;
    setState(() => _isPicking = true);

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? picked = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 95,
      );

      if (picked == null) {
        setState(() => _isPicking = false);
        return;
      }

      setState(() {
        _selectedImage = File(picked.path);
        _isPicking = false;
      });

      await _analyzeImage();
    } catch (e) {
      setState(() => _isPicking = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: const Color(0xFFc0392b),
          ),
        );
      }
    }
  }

  Future<void> _analyzeImage() async {
    if (_selectedImage == null) return;
    setState(() => _isAnalyzing = true);

    // Wait for model to finish loading if still in progress
    int waited = 0;
    while (!ModelService.instance.isModelLoaded && waited < 10) {
      await Future.delayed(const Duration(seconds: 1));
      waited++;
    }

    final result = await ModelService.instance.classify(_selectedImage!);

    final String labelId = result['label'] as String;
    final double confidence = (result['confidence'] as num).toDouble();

    final Plant? plant = DatabaseService.instance.getPlantById(labelId);

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ResultScreen(
            plant: plant,
            confidence: confidence,
            imagePath: _selectedImage!.path,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a2e1a),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1a2e1a),
        iconTheme: const IconThemeData(color: Color(0xFFf0ede6)),
        title: const Text(
          'Identify Plant',
          style: TextStyle(color: Color(0xFFf0ede6)),
        ),
      ),
      body: Center(
        child: _isAnalyzing
            ? _buildAnalyzingView()
            : _isPicking
                ? _buildPickingView()
                : _selectedImage != null
                    ? _buildAnalyzingView()
                    : _buildChoiceView(),
      ),
    );
  }

  Widget _buildChoiceView() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.eco,
            size: 80,
            color: Color(0xFFa8d5a2),
          ),
          const SizedBox(height: 24),
          const Text(
            'Choose an image source',
            style: TextStyle(
              color: Color(0xFFf0ede6),
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Take a clear photo of the fruit or plant',
            style: TextStyle(color: Color(0xFF6a8a6a), fontSize: 14),
          ),
          const SizedBox(height: 48),

          // Camera button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _pickImage(ImageSource.camera),
              icon: const Icon(Icons.camera_alt, size: 28),
              label: const Text(
                'Take Photo',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFa8d5a2),
                foregroundColor: const Color(0xFF1a2e1a),
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Gallery button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _pickImage(ImageSource.gallery),
              icon: const Icon(Icons.photo_library, size: 28),
              label: const Text(
                'Pick from Gallery',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFa8d5a2),
                side: const BorderSide(color: Color(0xFFa8d5a2), width: 2),
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPickingView() {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(color: Color(0xFFa8d5a2)),
        SizedBox(height: 24),
        Text(
          'Opening...',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildAnalyzingView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (_selectedImage != null)
          Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              image: DecorationImage(
                image: FileImage(_selectedImage!),
                fit: BoxFit.cover,
              ),
            ),
          ),
        const SizedBox(height: 48),
        const CircularProgressIndicator(
          color: Color(0xFFa8d5a2),
          strokeWidth: 3,
        ),
        const SizedBox(height: 24),
        const Text(
          'AI is analyzing the plant...',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'This may take a few seconds',
          style: TextStyle(color: Colors.grey, fontSize: 14),
        ),
      ],
    );
  }
}
