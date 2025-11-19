import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:logging/logging.dart';

class ESP32Service {
  final _logger = Logger('ESP32Service');
  static final ESP32Service _instance = ESP32Service._internal();
  factory ESP32Service() => _instance;
  ESP32Service._internal();

  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  // Stream controllers for real-time data
  final StreamController<Map<String, dynamic>> _sensorDataController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<List<Map<String, dynamic>>> _devicesController =
      StreamController<List<Map<String, dynamic>>>.broadcast();
  final StreamController<String> _statusController =
      StreamController<String>.broadcast();

  // Getters for streams
  Stream<Map<String, dynamic>> get sensorDataStream =>
      _sensorDataController.stream;
  Stream<List<Map<String, dynamic>>> get devicesStream =>
      _devicesController.stream;
  Stream<String> get statusStream => _statusController.stream;

  StreamSubscription? _currentDataSubscription;
  StreamSubscription? _devicesSubscription;

  bool _isListening = false;
  List<Map<String, dynamic>> _connectedDevices = [];

  /// Start listening to ESP32 data from Firebase
  void startListening() {
    if (_isListening) return;

    _isListening = true;
    _updateStatus('Starting ESP32 data monitoring...');

    // Listen to current sensor data
    _currentDataSubscription = _database
        .child('soil_monitoring/current')
        .onValue
        .listen(
          (event) {
            if (event.snapshot.exists) {
              try {
                final data = Map<String, dynamic>.from(
                  event.snapshot.value as Map,
                );
                _sensorDataController.add(data);
                _updateStatus(
                  'Received data from ESP32: ${data['deviceId'] ?? 'Unknown'}',
                );
              } catch (e) {
                _updateStatus('Error parsing sensor data: $e');
              }
            }
          },
          onError: (error) {
            _updateStatus('Error listening to sensor data: $error');
          },
        );

    // Listen to connected devices
    _devicesSubscription = _database
        .child('devices')
        .onValue
        .listen(
          (event) {
            if (event.snapshot.exists) {
              try {
                final devicesMap = Map<String, dynamic>.from(
                  event.snapshot.value as Map,
                );
                final devices = <Map<String, dynamic>>[];

                devicesMap.forEach((key, value) {
                  final device = Map<String, dynamic>.from(value as Map);
                  device['id'] = key;
                  devices.add(device);
                });

                _connectedDevices = devices;
                _devicesController.add(devices);
                _updateStatus('Found ${devices.length} ESP32 device(s)');
              } catch (e) {
                _updateStatus('Error parsing devices data: $e');
              }
            }
          },
          onError: (error) {
            _updateStatus('Error listening to devices: $error');
          },
        );
  }

  /// Stop listening to ESP32 data
  void stopListening() {
    if (!_isListening) return;

    _isListening = false;
    _currentDataSubscription?.cancel();
    _devicesSubscription?.cancel();
    _updateStatus('Stopped ESP32 data monitoring');
  }

  /// Get historical data for a specific time range
  Future<List<Map<String, dynamic>>> getHistoricalData({
    DateTime? startDate,
    DateTime? endDate,
    int? limitToLast,
  }) async {
    try {
      _updateStatus('Fetching historical data...');

      Query query = _database.child('soil_monitoring/history');

      if (startDate != null) {
        query = query.orderByKey().startAt(
          startDate.millisecondsSinceEpoch.toString(),
        );
      }

      if (endDate != null) {
        query = query.orderByKey().endAt(
          endDate.millisecondsSinceEpoch.toString(),
        );
      }

      if (limitToLast != null) {
        query = query.limitToLast(limitToLast);
      }

      final snapshot = await query.get();

      if (snapshot.exists) {
        final historyMap = Map<String, dynamic>.from(snapshot.value as Map);
        final historyList = <Map<String, dynamic>>[];

        historyMap.forEach((timestamp, data) {
          final entry = Map<String, dynamic>.from(data as Map);
          entry['timestamp'] = int.parse(timestamp);
          entry['date'] = DateTime.fromMillisecondsSinceEpoch(
            int.parse(timestamp) * 1000,
          );
          historyList.add(entry);
        });

        // Sort by timestamp (newest first)
        historyList.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));

        _updateStatus('Retrieved ${historyList.length} historical records');
        return historyList;
      } else {
        _updateStatus('No historical data found');
        return [];
      }
    } catch (e) {
      _updateStatus('Error fetching historical data: $e');
      return [];
    }
  }

  /// Get current sensor data (one-time read)
  Future<Map<String, dynamic>?> getCurrentData() async {
    try {
      final snapshot = await _database.child('soil_monitoring/current').get();

      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        _updateStatus('Retrieved current data');
        return data;
      } else {
        _updateStatus('No current data available');
        return null;
      }
    } catch (e) {
      _updateStatus('Error getting current data: $e');
      return null;
    }
  }

  /// Get list of connected ESP32 devices
  Future<List<Map<String, dynamic>>> getConnectedDevices() async {
    try {
      final snapshot = await _database.child('devices').get();

      if (snapshot.exists) {
        final devicesMap = Map<String, dynamic>.from(snapshot.value as Map);
        final devices = <Map<String, dynamic>>[];

        devicesMap.forEach((key, value) {
          final device = Map<String, dynamic>.from(value as Map);
          device['id'] = key;

          // Check if device is online (last seen within 5 minutes)
          final lastSeen = device['lastSeen'] as int? ?? 0;
          final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
          device['isOnline'] = (now - lastSeen) < 300; // 5 minutes

          devices.add(device);
        });

        _connectedDevices = devices;
        _updateStatus('Found ${devices.length} ESP32 device(s)');
        return devices;
      } else {
        _updateStatus('No devices found');
        return [];
      }
    } catch (e) {
      _updateStatus('Error getting devices: $e');
      return [];
    }
  }

  /// Send command to ESP32 device (via Firebase)
  Future<bool> sendCommandToDevice(String deviceId, String command) async {
    try {
      final commandData = {
        'command': command,
        'timestamp': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        'status': 'pending',
      };

      await _database
          .child('devices/$deviceId/commands')
          .push()
          .set(commandData);

      _updateStatus('Command "$command" sent to device $deviceId');
      return true;
    } catch (e) {
      _updateStatus('Error sending command: $e');
      return false;
    }
  }

  /// Update device configuration
  Future<bool> updateDeviceConfig(
    String deviceId,
    Map<String, dynamic> config,
  ) async {
    try {
      await _database.child('devices/$deviceId/config').update(config);

      _updateStatus('Configuration updated for device $deviceId');
      return true;
    } catch (e) {
      _updateStatus('Error updating device config: $e');
      return false;
    }
  }

  /// Get device statistics
  Map<String, dynamic> getDeviceStatistics() {
    final onlineDevices = _connectedDevices
        .where((d) => d['isOnline'] == true)
        .length;
    final totalDevices = _connectedDevices.length;

    return {
      'totalDevices': totalDevices,
      'onlineDevices': onlineDevices,
      'offlineDevices': totalDevices - onlineDevices,
      'lastUpdate': DateTime.now(),
    };
  }

  /// Check if any ESP32 devices are connected
  bool get hasConnectedDevices => _connectedDevices.isNotEmpty;

  /// Get the most recently active device
  Map<String, dynamic>? get mostRecentDevice {
    if (_connectedDevices.isEmpty) return null;

    _connectedDevices.sort((a, b) {
      final aLastSeen = a['lastSeen'] as int? ?? 0;
      final bLastSeen = b['lastSeen'] as int? ?? 0;
      return bLastSeen.compareTo(aLastSeen);
    });

    return _connectedDevices.first;
  }

  /// Update status message
  void _updateStatus(String message) {
    _logger.info('ESP32Service: $message');
    _statusController.add(message);
  }

  /// Dispose resources
  void dispose() {
    stopListening();
    _sensorDataController.close();
    _devicesController.close();
    _statusController.close();
  }
}
