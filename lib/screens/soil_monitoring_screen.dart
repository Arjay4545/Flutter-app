import 'package:flutter/material.dart';
import '../widgets/eggplant_illustration.dart';
import '../widgets/arduino_connection_widget.dart';
import '../widgets/esp32_device_widget.dart';
import '../models/nutrient_reading.dart';
import '../services/firebase_service.dart';
import '../services/arduino_service_web.dart';
import '../services/esp32_service.dart';
import 'analytics_screen.dart';
import 'package:logging/logging.dart';

class SoilMonitoringScreen extends StatefulWidget {
  const SoilMonitoringScreen({super.key});

  @override
  State<SoilMonitoringScreen> createState() => _SoilMonitoringScreenState();
}

class _SoilMonitoringScreenState extends State<SoilMonitoringScreen> {
  final _logger = Logger('SoilMonitoringScreen');
  // Sample NPK values (in real app, these would come from sensors)
  double nitrogenLevel = 75.0;
  double phosphorusLevel = 60.0;
  double potassiumLevel = 85.0;

  // Daily readings tracking
  List<NutrientReading> dailyReadings = [];
  DateTime lastReadingDate = DateTime.now();

  // Service instances
  final FirebaseService _firebaseService = FirebaseService();
  final ArduinoService _arduinoService = ArduinoService();
  final ESP32Service _esp32Service = ESP32Service();
  bool _isLoading = false;
  bool _isArduinoConnected = false;
  bool _isESP32Connected = false;
  DateTime? _lastArduinoUpdate;
  DateTime? _lastESP32Update;
  String _dataSource = 'Manual'; // 'Manual', 'Arduino', or 'ESP32'

  @override
  void initState() {
    super.initState();
    _initializeDailyReadings();
    _initializeArduino();
    _initializeESP32();
  }

  void _initializeDailyReadings() async {
    // Try to load current data from Firebase
    await _loadCurrentDataFromFirebase();
  }

  void _initializeArduino() {
    // Listen to Arduino connection status
    _arduinoService.connectionStream.listen((connected) {
      if (mounted) {
        setState(() {
          _isArduinoConnected = connected;
        });
      }
    });

    // Listen to Arduino sensor data
    _arduinoService.dataStream.listen((data) {
      if (mounted &&
          data.containsKey('nitrogen') &&
          data.containsKey('phosphorus') &&
          data.containsKey('potassium')) {
        setState(() {
          nitrogenLevel = data['nitrogen']!;
          phosphorusLevel = data['phosphorus']!;
          potassiumLevel = data['potassium']!;
          _lastArduinoUpdate = DateTime.now();
        });

        // Auto-save to Firebase when Arduino data is received
        _saveDataToFirebase();

        // Add to daily readings
        _addTodaysReading();

        // Show notification
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sensor data updated from Arduino'),
            backgroundColor: Color(0xFF4DB6AC),
            duration: Duration(seconds: 1),
          ),
        );
      }
    });
  }

  void _initializeESP32() {
    // Start listening to ESP32 data from Firebase
    _esp32Service.startListening();

    // Listen to ESP32 sensor data
    _esp32Service.sensorDataStream.listen((data) {
      if (mounted &&
          data.containsKey('nitrogen') &&
          data.containsKey('phosphorus') &&
          data.containsKey('potassium')) {
        setState(() {
          nitrogenLevel = (data['nitrogen'] as num).toDouble();
          phosphorusLevel = (data['phosphorus'] as num).toDouble();
          potassiumLevel = (data['potassium'] as num).toDouble();
          _lastESP32Update = DateTime.now();
          _isESP32Connected = true;
          _dataSource = 'ESP32';
        });

        // Add to daily readings
        _addTodaysReading();

        // Show notification
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Data updated from ESP32: ${data['deviceId'] ?? 'Unknown'}',
            ),
            backgroundColor: const Color(0xFF4DB6AC),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    });

    // Listen to ESP32 devices status
    _esp32Service.devicesStream.listen((devices) {
      if (mounted) {
        final onlineDevices = devices
            .where((d) => d['isOnline'] == true)
            .toList();
        setState(() {
          _isESP32Connected = onlineDevices.isNotEmpty;
          if (!_isESP32Connected) {
            _dataSource = _isArduinoConnected ? 'Arduino' : 'Manual';
          }
        });
      }
    });
  }

  Future<void> _loadCurrentDataFromFirebase() async {
    try {
      final currentData = await _firebaseService.getCurrentSoilData();
      if (currentData != null) {
        setState(() {
          nitrogenLevel = (currentData['nitrogen'] as num).toDouble();
          phosphorusLevel = (currentData['phosphorus'] as num).toDouble();
          potassiumLevel = (currentData['potassium'] as num).toDouble();
        });
        _logger.info('Loaded current data from Firebase');
      }
    } catch (e) {
      _logger.severe('Error loading data from Firebase: $e');
    }
  }

  Future<void> _saveDataToFirebase() async {
    try {
      setState(() {
        _isLoading = true;
      });

      await _firebaseService.saveSoilData(
        nitrogen: nitrogenLevel,
        phosphorus: phosphorusLevel,
        potassium: potassiumLevel,
      );

      _logger.info('Data saved to Firebase successfully');
    } catch (e) {
      _logger.severe('Error saving data to Firebase: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving to Firebase: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleManualRefresh() async {
    if (_isLoading) return;

    setState(() {
      nitrogenLevel =
          (50 + (50 * (DateTime.now().millisecond / 1000))).clamp(0, 100);
      phosphorusLevel =
          (40 + (60 * (DateTime.now().second / 60))).clamp(0, 100);
      potassiumLevel =
          (60 + (40 * (DateTime.now().minute / 60))).clamp(0, 100);

      // Add today's reading to analytics
      _addTodaysReading();
    });

    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    await _saveDataToFirebase();

    if (!mounted) return;

    messenger.showSnackBar(
      const SnackBar(
        content: Text('Data refreshed and saved to Firebase!'),
        backgroundColor: Color(0xFF4DB6AC),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _addTodaysReading() {
    final today = DateTime.now();
    final todayReading = NutrientReading(
      date: today,
      nitrogen: nitrogenLevel,
      phosphorus: phosphorusLevel,
      potassium: potassiumLevel,
    );

    // Check if we already have a reading for today
    final existingIndex = dailyReadings.indexWhere(
      (reading) =>
          reading.date.year == today.year &&
          reading.date.month == today.month &&
          reading.date.day == today.day,
    );

    if (existingIndex != -1) {
      dailyReadings[existingIndex] = todayReading;
    } else {
      dailyReadings.add(todayReading);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4DB6AC),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header section
              Row(
                children: [
                  const Icon(Icons.eco, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Soil Monitoring',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const Text(
                          'for Eggplant Farming',
                          style: TextStyle(fontSize: 16, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: _isLoading ? null : _handleManualRefresh,
                        icon: const Icon(Icons.refresh, color: Colors.white),
                        tooltip: 'Refresh & Save',
                      ),
                      IconButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AnalyticsScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.analytics, color: Colors.white),
                        tooltip: 'View Analytics',
                      ),
                      IconButton(
                        onPressed: () {
                          _showArduinoSettings(context);
                        },
                        icon: const Icon(Icons.settings, color: Colors.white),
                        tooltip: 'Arduino Settings',
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Eggplant illustration
              Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const EggplantIllustration(size: 120),
                ),
              ),
              const SizedBox(height: 24),

              // NPK Monitoring Card
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.all(Radius.circular(30)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.analytics,
                              color: Color(0xFF4DB6AC),
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'NPK Levels',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2E2E2E),
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _getDataSourceColor().withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: _getDataSourceColor(),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _dataSource,
                                    style: TextStyle(
                                      color: _getDataSourceColor(),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Nitrogen (N)
                        _buildNPKCard(
                          'Nitrogen (N)',
                          nitrogenLevel,
                          Colors.blue,
                          Icons.water_drop,
                          'Essential for leaf growth',
                        ),
                        const SizedBox(height: 16),

                        // Phosphorus (P)
                        _buildNPKCard(
                          'Phosphorus (P)',
                          phosphorusLevel,
                          Colors.orange,
                          Icons.local_florist,
                          'Promotes root development',
                        ),
                        const SizedBox(height: 16),

                        // Potassium (K)
                        _buildNPKCard(
                          'Potassium (K)',
                          potassiumLevel,
                          Colors.purple,
                          Icons.energy_savings_leaf,
                          'Improves fruit quality',
                        ),
                        const SizedBox(height: 24),

                        // Action buttons
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed:
                                    _isLoading ? null : _handleManualRefresh,
                                icon: _isLoading
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      )
                                    : const Icon(Icons.refresh),
                                label: Text(
                                  _isLoading ? 'Saving...' : 'Refresh',
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF4DB6AC),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  _showRecommendations(context);
                                },
                                icon: const Icon(Icons.lightbulb_outline),
                                label: const Text('Tips'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF4DB6AC),
                                  side: const BorderSide(
                                    color: Color(0xFF4DB6AC),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNPKCard(
    String title,
    double value,
    Color color,
    IconData icon,
    String description,
  ) {
    String status = _getNPKStatus(value);
    Color statusColor = _getStatusColor(value);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2E2E2E),
                      ),
                    ),
                    Text(
                      description,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${value.toInt()}%',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: value / 100,
            backgroundColor: color.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ],
      ),
    );
  }

  String _getNPKStatus(double value) {
    if (value >= 70) return 'Optimal';
    if (value >= 50) return 'Good';
    if (value >= 30) return 'Low';
    return 'Critical';
  }

  Color _getStatusColor(double value) {
    if (value >= 70) return Colors.green;
    if (value >= 50) return Colors.blue;
    if (value >= 30) return Colors.orange;
    return Colors.red;
  }

  void _showRecommendations(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Eggplant Farming Tips',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildTip(
              '💧',
              'Nitrogen',
              'Add compost or nitrogen-rich fertilizer for better leaf growth',
            ),
            _buildTip(
              '🌱',
              'Phosphorus',
              'Use bone meal to boost root development and flowering',
            ),
            _buildTip(
              '🍆',
              'Potassium',
              'Apply potash fertilizer to improve fruit size and quality',
            ),
            _buildTip(
              '🌡️',
              'Temperature',
              'Maintain soil temperature between 21-29°C for optimal growth',
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4DB6AC),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Got it!'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTip(String emoji, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  void _showArduinoSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DefaultTabController(
        length: 2,
        child: Container(
          padding: const EdgeInsets.all(16),
          height: MediaQuery.of(context).size.height * 0.8,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Sensor Connection Settings',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const TabBar(
                labelColor: Color(0xFF4DB6AC),
                unselectedLabelColor: Colors.grey,
                indicatorColor: Color(0xFF4DB6AC),
                tabs: [
                  Tab(icon: Icon(Icons.usb), text: 'Arduino (USB)'),
                  Tab(icon: Icon(Icons.wifi), text: 'ESP32 (WiFi)'),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: TabBarView(
                  children: [
                    // Arduino tab
                    ArduinoConnectionWidget(
                      onDataReceived: (data) {
                        // Data is already handled by the stream listener
                        // This is just for the widget's internal functionality
                      },
                    ),
                    // ESP32 tab
                    const ESP32DeviceWidget(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getDataSourceColor() {
    switch (_dataSource) {
      case 'ESP32':
        return Colors.blue;
      case 'Arduino':
        return Colors.green;
      case 'Manual':
      default:
        return Colors.orange;
    }
  }

  String _getLastUpdateText() {
    DateTime? lastUpdate;

    // Get the most recent update time
    if (_lastESP32Update != null && _lastArduinoUpdate != null) {
      lastUpdate = _lastESP32Update!.isAfter(_lastArduinoUpdate!)
          ? _lastESP32Update
          : _lastArduinoUpdate;
    } else if (_lastESP32Update != null) {
      lastUpdate = _lastESP32Update;
    } else if (_lastArduinoUpdate != null) {
      lastUpdate = _lastArduinoUpdate;
    }

    if (lastUpdate != null) {
      return 'Last update: ${_formatTime(lastUpdate)}';
    } else {
      return 'Waiting for sensor data';
    }
  }
}
