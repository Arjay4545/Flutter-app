import 'package:firebase_database/firebase_database.dart';
import 'package:logging/logging.dart';
import '../models/nutrient_reading.dart';

class FirebaseService {
  final _logger = Logger('FirebaseService');
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  // Save soil monitoring data to Firebase
  Future<void> saveSoilData({
    required double nitrogen,
    required double phosphorus,
    required double potassium,
    DateTime? timestamp,
  }) async {
    try {
      final now = timestamp ?? DateTime.now();
      final data = {
        'nitrogen': nitrogen,
        'phosphorus': phosphorus,
        'potassium': potassium,
        'timestamp': now.millisecondsSinceEpoch,
        'date': now.toIso8601String(),
      };

      // Save to current readings
      await _database.child('soil_monitoring/current').set(data);

      // Save to historical data with timestamp as key
      await _database
          .child('soil_monitoring/history/${now.millisecondsSinceEpoch}')
          .set(data);

      _logger.info('Soil data saved to Firebase successfully');
    } catch (e) {
      _logger.severe('Error saving soil data to Firebase: $e');
      rethrow;
    }
  }

  // Get current soil monitoring data from Firebase
  Future<Map<String, dynamic>?> getCurrentSoilData() async {
    try {
      final snapshot = await _database.child('soil_monitoring/current').get();
      if (snapshot.exists) {
        return Map<String, dynamic>.from(snapshot.value as Map);
      }
      return null;
    } catch (e) {
      _logger.severe('Error getting current soil data from Firebase: $e');
      return null;
    }
  }

  // Get historical soil monitoring data from Firebase
  Future<List<NutrientReading>> getHistoricalSoilData({
    int? limitToLast,
  }) async {
    try {
      Query query = _database.child('soil_monitoring/history').orderByKey();

      if (limitToLast != null) {
        query = query.limitToLast(limitToLast);
      }

      final snapshot = await query.get();

      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        final readings = <NutrientReading>[];

        data.forEach((key, value) {
          final reading = Map<String, dynamic>.from(value);
          readings.add(
            NutrientReading(
              date: DateTime.fromMillisecondsSinceEpoch(reading['timestamp']),
              nitrogen: (reading['nitrogen'] as num).toDouble(),
              phosphorus: (reading['phosphorus'] as num).toDouble(),
              potassium: (reading['potassium'] as num).toDouble(),
            ),
          );
        });

        // Sort by date (newest first)
        readings.sort((a, b) => b.date.compareTo(a.date));
        return readings;
      }

      return [];
    } catch (e) {
      _logger.severe('Error getting historical soil data from Firebase: $e');
      return [];
    }
  }

  // Listen to real-time updates of current soil data
  Stream<Map<String, dynamic>?> listenToCurrentSoilData() {
    return _database.child('soil_monitoring/current').onValue.map((event) {
      if (event.snapshot.exists) {
        return Map<String, dynamic>.from(event.snapshot.value as Map);
      }
      return null;
    });
  }

  // Delete old historical data (keep only last N days)
  Future<void> cleanupOldData({int keepLastDays = 30}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: keepLastDays));
      final cutoffTimestamp = cutoffDate.millisecondsSinceEpoch;

      final snapshot = await _database
          .child('soil_monitoring/history')
          .orderByKey()
          .endAt(cutoffTimestamp.toString())
          .get();

      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        for (String key in data.keys) {
          await _database.child('soil_monitoring/history/$key').remove();
        }
        _logger.info(
          'Cleaned up old data before ${cutoffDate.toIso8601String()}',
        );
      }
    } catch (e) {
      _logger.severe('Error cleaning up old data: $e');
    }
  }

  // Save device/sensor information
  Future<void> saveDeviceInfo({
    required String deviceId,
    required String deviceName,
    Map<String, dynamic>? additionalInfo,
  }) async {
    try {
      final data = {
        'deviceId': deviceId,
        'deviceName': deviceName,
        'lastSeen': DateTime.now().millisecondsSinceEpoch,
        'status': 'active',
        ...?additionalInfo,
      };

      await _database.child('devices/$deviceId').set(data);
      _logger.info('Device info saved to Firebase successfully');
    } catch (e) {
      _logger.severe('Error saving device info to Firebase: $e');
      rethrow;
    }
  }

  // Get all registered devices
  Future<List<Map<String, dynamic>>> getDevices() async {
    try {
      final snapshot = await _database.child('devices').get();
      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        return data.values
            .map((device) => Map<String, dynamic>.from(device))
            .toList();
      }
      return [];
    } catch (e) {
      _logger.severe('Error getting devices from Firebase: $e');
      return [];
    }
  }
}
