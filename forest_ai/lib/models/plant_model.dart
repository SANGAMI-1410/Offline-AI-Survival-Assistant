class Plant {
  final String id;
  final String commonName;
  final String scientificName;
  final String category; // EDIBLE or TOXIC
  final String dangerLevel;
  final bool eatRaw;
  final bool eatCooked;
  final String taste;
  final String season;
  final String identification;
  final List<String> preparation;
  final String nutrition;
  final List<String> warnings;
  final String whyToxic;
  final List<String> symptoms;
  final String emergency;

  Plant({
    required this.id,
    required this.commonName,
    required this.scientificName,
    required this.category,
    required this.dangerLevel,
    required this.eatRaw,
    required this.eatCooked,
    required this.taste,
    required this.season,
    required this.identification,
    required this.preparation,
    required this.nutrition,
    required this.warnings,
    required this.whyToxic,
    required this.symptoms,
    required this.emergency,
  });

  factory Plant.fromJson(Map<String, dynamic> json) {
    return Plant(
      id: json['id'] ?? '',
      commonName: json['commonName'] ?? '',
      scientificName: json['scientificName'] ?? '',
      category: json['category'] ?? '',
      dangerLevel: json['dangerLevel'] ?? '',
      eatRaw: json['eatRaw'] ?? false,
      eatCooked: json['eatCooked'] ?? false,
      taste: json['taste'] ?? '',
      season: json['season'] ?? 'Year-round',
      identification: json['identification'] is String
          ? json['identification']
          : (json['identification'] ?? '').toString(),
      preparation: List<String>.from(json['preparation'] ?? []),
      nutrition: json['nutrition'] is String
          ? json['nutrition']
          : (json['nutrition'] ?? '').toString(),
      warnings: List<String>.from(json['warnings'] ?? []),
      whyToxic: json['whyToxic'] ?? '',
      symptoms: List<String>.from(json['symptoms'] ?? []),
      emergency: json['emergency'] ?? '',
    );
  }
}
