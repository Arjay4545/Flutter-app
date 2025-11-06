class NutrientReading {
  final DateTime date;
  final double nitrogen;
  final double phosphorus;
  final double potassium;
  final double temperature;
  final double humidity;

  NutrientReading({
    required this.date,
    required this.nitrogen,
    required this.phosphorus,
    required this.potassium,
    this.temperature = 25.0,
    this.humidity = 60.0,
  });

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'nitrogen': nitrogen,
      'phosphorus': phosphorus,
      'potassium': potassium,
      'temperature': temperature,
      'humidity': humidity,
    };
  }

  factory NutrientReading.fromJson(Map<String, dynamic> json) {
    return NutrientReading(
      date: DateTime.parse(json['date']),
      nitrogen: json['nitrogen'].toDouble(),
      phosphorus: json['phosphorus'].toDouble(),
      potassium: json['potassium'].toDouble(),
      temperature: json['temperature']?.toDouble() ?? 25.0,
      humidity: json['humidity']?.toDouble() ?? 60.0,
    );
  }
}

class AnalyticsData {
  static List<NutrientReading> generateSampleData() {
    final List<NutrientReading> readings = [];
    final now = DateTime.now();
    
    // Generate 30 days of sample data
    for (int i = 29; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      
      // Simulate realistic nutrient variations
      final baseNitrogen = 70.0 + (i * 0.5) + (DateTime.now().millisecond % 20 - 10);
      final basePhosphorus = 55.0 + (i * 0.3) + (DateTime.now().second % 15 - 7);
      final basePotassium = 80.0 + (i * 0.4) + (DateTime.now().minute % 18 - 9);
      
      readings.add(NutrientReading(
        date: date,
        nitrogen: (baseNitrogen).clamp(30.0, 100.0),
        phosphorus: (basePhosphorus).clamp(25.0, 95.0),
        potassium: (basePotassium).clamp(40.0, 100.0),
        temperature: 22.0 + (i % 10) + (DateTime.now().hour % 8),
        humidity: 55.0 + (i % 15) + (DateTime.now().day % 12),
      ));
    }
    
    return readings;
  }
}
