// Stub implementation for web platform
import 'dart:async';

class ArduinoService {
  static final ArduinoService _instance = ArduinoService._internal();
  factory ArduinoService() => _instance;
  ArduinoService._internal();

  // Stream controllers
  final StreamController<Map<String, double>> _dataStreamController =
      StreamController<Map<String, double>>.broadcast();
  final StreamController<String> _statusStreamController =
      StreamController<String>.broadcast();
  final StreamController<bool> _connectionStreamController =
      StreamController<bool>.broadcast();

  // Public streams
  Stream<Map<String, double>> get dataStream => _dataStreamController.stream;
  Stream<String> get statusStream => _statusStreamController.stream;
  Stream<bool> get connectionStream => _connectionStreamController.stream;

  // Properties
  bool get isConnected => false;
  List<String> get availablePorts => [];
  String? get connectedPort => null;

  // Methods (no-op for web)
  Future<void> initialize() async {
    _statusStreamController.add('Arduino not supported on web platform');
  }

  Future<bool> connect(String port, {int baudRate = 9600}) async {
    _statusStreamController.add('Arduino not supported on web platform');
    return false;
  }

  Future<void> disconnect() async {
    // No-op
  }

  Future<bool> sendCommand(String command) async {
    _statusStreamController.add('Arduino not supported on web platform');
    return false;
  }

  Future<bool> requestReading() async {
    _statusStreamController.add('Arduino not supported on web platform');
    return false;
  }

  Future<bool> calibrateSensors() async {
    _statusStreamController.add('Arduino not supported on web platform');
    return false;
  }

  Future<bool> autoConnect() async {
    _statusStreamController.add('Arduino not supported on web platform');
    return false;
  }

  List<String> getAvailablePorts() {
    return [];
  }

  Future<void> startAutoReading() async {
    _statusStreamController.add('Arduino not supported on web platform');
  }

  Future<void> stopAutoReading() async {
    // No-op
  }

  Future<void> dispose() async {
    await _dataStreamController.close();
    await _statusStreamController.close();
    await _connectionStreamController.close();
  }
}
