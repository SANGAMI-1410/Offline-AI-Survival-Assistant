import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class ModelService {
  ModelService._privateConstructor();
  static final ModelService instance = ModelService._privateConstructor();

  Interpreter? _interpreter;
  List<String> _labels = [];

  bool get isModelLoaded => _interpreter != null;
  bool get isLabelsLoaded => _labels.isNotEmpty;

  Future<void> loadModel() async {
    try {
      print('[ModelService] Extracting model from assets...');
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/model.tflite');
      // Always re-extract to ensure latest model
      final data = await rootBundle.load('assets/model.tflite');
      await file.writeAsBytes(data.buffer.asUint8List(), flush: true);
      print('[ModelService] Model file size: ${await file.length()} bytes');

      _interpreter = Interpreter.fromFile(file);
      final inp = _interpreter!.getInputTensor(0);
      final out = _interpreter!.getOutputTensor(0);
      print('[ModelService] Model loaded');
      print('[ModelService] Input  shape=${inp.shape} type=${inp.type}');
      print('[ModelService] Output shape=${out.shape} type=${out.type}');
    } catch (e) {
      print('[ModelService] FAILED to load model: $e');
      _interpreter = null;
    }
  }

  Future<void> loadLabels() async {
    try {
      final raw = await rootBundle.loadString('assets/labels.txt');
      _labels = raw.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
      print('[ModelService] Labels loaded count=${_labels.length}');
    } catch (e) {
      print('[ModelService] FAILED to load labels: $e');
      _labels = [];
    }
  }

  Future<Map<String, dynamic>> classify(File imageFile) async {
    print('[ModelService] classify() model=$isModelLoaded labels=${_labels.length}');

    if (_interpreter == null || _labels.isEmpty) {
      print('[ModelService] Not ready');
      return {'label': 'unknown', 'confidence': 0.0};
    }

    try {
      final bytes = await imageFile.readAsBytes();
      img.Image? decoded = img.decodeImage(bytes);
      if (decoded == null) return {'label': 'unknown', 'confidence': 0.0};

      // Fix EXIF rotation from camera
      decoded = img.bakeOrientation(decoded);

      final resized = img.copyResize(decoded, width: 224, height: 224);
      print('[ModelService] Image ${decoded.width}x${decoded.height} -> 224x224');

      // Build flat Float32List [1, 224, 224, 3] — matches Python's np.array exactly
      final inputBuffer = Float32List(1 * 224 * 224 * 3);
      int offset = 0;
      for (int y = 0; y < 224; y++) {
        for (int x = 0; x < 224; x++) {
          final p = resized.getPixel(x, y);
          inputBuffer[offset++] = p.r.toDouble();
          inputBuffer[offset++] = p.g.toDouble();
          inputBuffer[offset++] = p.b.toDouble();
        }
      }

      // Debug: first pixel values
      print('[ModelService] Pixel[0,0] R=${inputBuffer[0]} G=${inputBuffer[1]} B=${inputBuffer[2]}');

      // Run inference using raw byte buffer
      final outputBuffer = Float32List(1 * _labels.length);
      _interpreter!.run(inputBuffer.buffer, outputBuffer.buffer);

      // Find best match
      int bestIdx = 0;
      double bestConf = 0.0;
      for (int i = 0; i < _labels.length; i++) {
        if (outputBuffer[i] > bestConf) {
          bestConf = outputBuffer[i];
          bestIdx = i;
        }
      }

      // Debug: top predictions
      final indexed = List.generate(_labels.length, (i) => MapEntry(i, outputBuffer[i]));
      indexed.sort((a, b) => b.value.compareTo(a.value));
      final top3 = indexed.take(3).map((e) => '${_labels[e.key]}=${(e.value*100).toStringAsFixed(1)}%').join(', ');
      print('[ModelService] Top3: $top3');

      final label = _labels[bestIdx];
      print('[ModelService] Result: $label (${(bestConf * 100).toStringAsFixed(1)}%)');
      return {'label': label, 'confidence': bestConf};
    } catch (e) {
      print('[ModelService] Inference error: $e');
      return {'label': 'unknown', 'confidence': 0.0};
    }
  }
}
