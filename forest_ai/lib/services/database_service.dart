import 'dart:convert';
import '../models/plant_model.dart';

class DatabaseService {
  DatabaseService._privateConstructor();
  static final DatabaseService instance = DatabaseService._privateConstructor();

  List<Plant> _plants = [];
  String _forestName = 'Forest Dataset';

  List<Plant> get plants => _plants;
  String get forestName => _forestName;

  void loadFromJson(String jsonString) {
    final data = json.decode(jsonString);
    if (data is Map && data.containsKey('plants')) {
      _forestName = data['name'] ?? data['forestName'] ?? 'Forest Dataset';
      final List<dynamic> plantsJson = data['plants'];
      _plants = plantsJson.map((p) => Plant.fromJson(p)).toList();
    } else if (data is List) {
      _plants = data.map((p) => Plant.fromJson(p)).toList();
    } else {
      _plants = [];
    }
  }

  Plant? getPlantById(String id) {
    try {
      return _plants.firstWhere(
        (p) => p.id.toLowerCase() == id.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }

  bool get isLoaded => _plants.isNotEmpty;
}
