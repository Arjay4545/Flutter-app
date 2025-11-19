import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_libserialport/flutter_libserialport.dart';
import 'package:permission_handler/permission_handler.dart';

class ArduinoService {
  static final ArduinoService _instance = ArduinoService._internal();
  factory ArduinoService() => _instance;
  ArduinoService._internal();

  SerialPort? _port;
  SerialPortReader? _reader;
  StreamSubscription? _subscription;
  bool _isConnected = false;
  String? _connectedPortName;

  // Stream controllers for real-time data
  final StreamController<Map<String, double>> _dataController =
      StreamController<Map<String, double>>.broadcast();
  final StreamController<bool> _connectionController =
      StreamController<bool>.broadcast();
  final StreamController<String> _statusController =
      StreamController<String>.broadcast();

  // Getters for streams
  Stream<Map<String, double>> get dataStream => _dataController.stream;
  Stream<bool> get connectionStream => _connectionController.stream;
  Stream<String> get statusStream => _statusController.stream;

  bool get isConnected => _isConnected;
  String? get connectedPort => _connectedPortName;

  /// Get list of available serial ports
  List<String> getAvailablePorts() {
    try {
      final ports = SerialPort.availablePorts;
      _updateStatus('Found ${ports.length} available ports');
      return ports;
    } catch (e) {
      _updateStatus('Error getting ports: $e');
      return [];
    }
  }

  /// Connect to Arduino on specified port
  Future<bool> connect(String portName, {int baudRate = 9600}) async {
    try {
      // Request permissions if needed
      if (!kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.android ||
              defaultTargetPlatform == TargetPlatform.iOS)) {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          _updateStatus('Storage permission denied');
          return false;
        }
      }

      // Disconnect if already connected
      if (_isConnected) {
        await disconnect();
      }

      _updateStatus('Connecting to $portName...');

      _port = SerialPort(portName);

      // Configure port settings
      final config = SerialPortConfig()
        ..baudRate = baudRate
        ..bits = 8
        ..parity = SerialPortParity.none
        ..stopBits = 1
        ..setFlowControl(SerialPortFlowControl.none);

      _port!.config = config;

      // Open the port
      if (!_port!.openReadWrite()) {
        final error = SerialPort.lastError;
        _updateStatus(
          'Failed to open port: ${error?.message ?? 'Unknown error'}',
        );
        return false;
      }

      _isConnected = true;
      _connectedPortName = portName;
      _connectionController.add(true);
      _updateStatus('Connected to $portName');

      // Start reading data
      _startReading();

      return true;
    } catch (e) {
      _updateStatus('Connection error: $e');
      return false;
    }
  }

  /// Disconnect from Arduino
  Future<void> disconnect() async {
    try {
      _updateStatus('Disconnecting...');

      await _subscription?.cancel();
      _reader?.close();
      _port?.close();

      _isConnected = false;
      _connectedPortName = null;
      _connectionController.add(false);
      _updateStatus('Disconnected');
    } catch (e) {
      _updateStatus('Disconnect error: $e');
    }
  }

  /// Start reading data from Arduino
  void _startReading() {
    try {
      _reader = SerialPortReader(_port!);
      _subscription = _reader!.stream.listen(
        _handleData,
        onError: (error) {
          _updateStatus('Read error: $error');
          _handleConnectionLost();
        },
        onDone: () {
          _updateStatus('Connection closed');
          _handleConnectionLost();
        },
      );
    } catch (e) {
      _updateStatus('Failed to start reading: $e');
    }
  }

  /// Handle incoming data from Arduino
  void _handleData(Uint8List data) {
    try {
      final dataString = String.fromCharCodes(data).trim();
      if (dataString.isEmpty) return;

      _updateStatus('Received: $dataString');

      // Parse JSON data from Arduino
      // Expected format: {"nitrogen": 75.5, "phosphorus": 60.2, "potassium": 85.1}
      final jsonData = jsonDecode(dataString);

      if (jsonData is Map<String, dynamic>) {
        final sensorData = <String, double>{};

        // Extract NPK values
        if (jsonData.containsKey('nitrogen')) {
          sensorData['nitrogen'] = (jsonData['nitrogen'] as num).toDouble();
        }
        if (jsonData.containsKey('phosphorus')) {
          sensorData['phosphorus'] = (jsonData['phosphorus'] as num).toDouble();
        }
        if (jsonData.containsKey('potassium')) {
          sensorData['potassium'] = (jsonData['potassium'] as num).toDouble();
        }

        // Add timestamp
        sensorData['timestamp'] = DateTime.now().millisecondsSinceEpoch
            .toDouble();

        // Emit data to listeners
        _dataController.add(sensorData);
        _updateStatus('Data parsed successfully');
      }
    } catch (e) {
      _updateStatus('Data parsing error: $e');
      // Try to parse as simple comma-separated values
      _parseSimpleFormat(String.fromCharCodes(data).trim());
    }
  }

  /// Parse simple comma-separated format: "N,P,K"
  void _parseSimpleFormat(String data) {
    try {
      final parts = data.split(',');
      if (parts.length >= 3) {
        final sensorData = <String, double>{
          'nitrogen': double.parse(parts[0].trim()),
          'phosphorus': double.parse(parts[1].trim()),
          'potassium': double.parse(parts[2].trim()),
          'timestamp': DateTime.now().millisecondsSinceEpoch.toDouble(),
        };

        _dataController.add(sensorData);
        _updateStatus('Simple format data parsed');
      }
    } catch (e) {
      _updateStatus('Simple format parsing error: $e');
    }
  }

  /// Handle connection lost
  void _handleConnectionLost() {
    _isConnected = false;
    _connectedPortName = null;
    _connectionController.add(false);
  }

  /// Send command to Arduino
  Future<bool> sendCommand(String command) async {
    if (!_isConnected || _port == null) {
      _updateStatus('Not connected to Arduino');
      return false;
    }

    try {
      final data = Uint8List.fromList('$command\n'.codeUnits);
      final bytesWritten = _port!.write(data);
      _updateStatus('Sent command: $command ($bytesWritten bytes)');
      return bytesWritten > 0;
    } catch (e) {
      _updateStatus('Send command error: $e');
      return false;
    }
  }

  /// Request fresh sensor reading
  Future<bool> requestReading() async {
    return await sendCommand('READ_SENSORS');
  }

  /// Calibrate sensors
  Future<bool> calibrateSensors() async {
    return await sendCommand('CALIBRATE');
  }

  /// Update status message
  void _updateStatus(String message) {
    if (kDebugMode) {
      print('ArduinoService: $message');
    }
    _statusController.add(message);
  }

  /// Auto-discover and connect to Arduino
  Future<bool> autoConnect() async {
    final ports = getAvailablePorts();

    for (final port in ports) {
      _updateStatus('Trying to connect to $port...');
      if (await connect(port)) {
        // Send a test command and wait for response
        await sendCommand('PING');
        await Future.delayed(const Duration(seconds: 2));

        if (_isConnected) {
          _updateStatus('Auto-connected to $port');
          return true;
        }
      }
      await disconnect();
    }

    _updateStatus('Auto-connect failed - no Arduino found');
    return false;
  }

  /// Dispose resources
  void dispose() {
    disconnect();
    _dataController.close();
    _connectionController.close();
    _statusController.close();
  }
}
