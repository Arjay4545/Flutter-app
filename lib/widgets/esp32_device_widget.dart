import 'package:flutter/material.dart';
import '../services/esp32_service.dart';

class ESP32DeviceWidget extends StatefulWidget {
  const ESP32DeviceWidget({super.key});

  @override
  State<ESP32DeviceWidget> createState() => _ESP32DeviceWidgetState();
}

class _ESP32DeviceWidgetState extends State<ESP32DeviceWidget> {
  final ESP32Service _esp32Service = ESP32Service();
  List<Map<String, dynamic>> _devices = [];
  Map<String, dynamic>? _statistics;
  bool _isLoading = true;
  String _statusMessage = 'Initializing...';

  @override
  void initState() {
    super.initState();
    _initializeESP32Service();
  }

  void _initializeESP32Service() {
    // Start listening to ESP32 data
    _esp32Service.startListening();

    // Listen to devices stream
    _esp32Service.devicesStream.listen((devices) {
      if (mounted) {
        setState(() {
          _devices = devices;
          _statistics = _esp32Service.getDeviceStatistics();
          _isLoading = false;
        });
      }
    });

    // Listen to status messages
    _esp32Service.statusStream.listen((status) {
      if (mounted) {
        setState(() {
          _statusMessage = status;
        });
      }
    });

    // Load initial devices
    _loadDevices();
  }

  Future<void> _loadDevices() async {
    final devices = await _esp32Service.getConnectedDevices();
    if (mounted) {
      setState(() {
        _devices = devices;
        _statistics = _esp32Service.getDeviceStatistics();
        _isLoading = false;
      });
    }
  }

  Future<void> _sendCommand(String deviceId, String command) async {
    final success = await _esp32Service.sendCommandToDevice(deviceId, command);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Command "$command" sent to device'
                : 'Failed to send command',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.developer_board, color: Color(0xFF4DB6AC)),
                const SizedBox(width: 8),
                const Text(
                  'ESP32 Devices',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (_statistics != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_statistics!['onlineDevices']}/${_statistics!['totalDevices']} Online',
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Status message
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _statusMessage,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ),
            const SizedBox(height: 16),

            // Loading or devices list
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_devices.isEmpty)
              _buildNoDevicesFound()
            else
              _buildDevicesList(),
          ],
        ),
      ),
    );
  }

  Widget _buildNoDevicesFound() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.search_off, color: Colors.orange, size: 48),
          const SizedBox(height: 12),
          const Text(
            'No ESP32 Devices Found',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.orange,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Make sure your ESP32 is connected to WiFi and sending data to Firebase',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadDevices,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDevicesList() {
    return Column(
      children: [
        // Statistics summary
        if (_statistics != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF4DB6AC).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFF4DB6AC).withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  'Total',
                  _statistics!['totalDevices'].toString(),
                  Icons.devices,
                ),
                _buildStatItem(
                  'Online',
                  _statistics!['onlineDevices'].toString(),
                  Icons.wifi,
                ),
                _buildStatItem(
                  'Offline',
                  _statistics!['offlineDevices'].toString(),
                  Icons.wifi_off,
                ),
              ],
            ),
          ),

        // Devices list
        ..._devices.map((device) => _buildDeviceCard(device)),

        const SizedBox(height: 12),

        // Refresh button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _loadDevices,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh Devices'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF4DB6AC),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF4DB6AC), size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF4DB6AC),
          ),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildDeviceCard(Map<String, dynamic> device) {
    final isOnline = device['isOnline'] as bool? ?? false;
    final deviceId = device['id'] as String? ?? 'Unknown';
    final location = device['location'] as String? ?? 'Unknown Location';
    final lastSeen = device['lastSeen'] as int? ?? 0;
    final firmware = device['firmware'] as String? ?? 'Unknown';
    final sensors = device['sensors'] as String? ?? 'Unknown';

    final lastSeenDate = DateTime.fromMillisecondsSinceEpoch(lastSeen * 1000);
    final timeDiff = DateTime.now().difference(lastSeenDate);

    String lastSeenText;
    if (timeDiff.inMinutes < 1) {
      lastSeenText = 'Just now';
    } else if (timeDiff.inMinutes < 60) {
      lastSeenText = '${timeDiff.inMinutes}m ago';
    } else if (timeDiff.inHours < 24) {
      lastSeenText = '${timeDiff.inHours}h ago';
    } else {
      lastSeenText = '${timeDiff.inDays}d ago';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isOnline
            ? Colors.green.withValues(alpha: 0.05)
            : Colors.red.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOnline
              ? Colors.green.withValues(alpha: 0.3)
              : Colors.red.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Device header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isOnline
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.memory,
                  color: isOnline ? Colors.green : Colors.red,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      deviceId,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      location,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isOnline
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: isOnline ? Colors.green : Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isOnline ? 'Online' : 'Offline',
                      style: TextStyle(
                        color: isOnline ? Colors.green : Colors.red,
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Device info
          Row(
            children: [
              Expanded(child: _buildDeviceInfo('Last Seen', lastSeenText)),
              Expanded(child: _buildDeviceInfo('Firmware', firmware)),
            ],
          ),
          const SizedBox(height: 8),
          _buildDeviceInfo('Sensors', sensors),
          const SizedBox(height: 12),

          // Action buttons
          if (isOnline)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _sendCommand(deviceId, 'READ'),
                    icon: const Icon(Icons.sensors, size: 16),
                    label: const Text('Read', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _sendCommand(deviceId, 'CALIBRATE'),
                    icon: const Icon(Icons.tune, size: 16),
                    label: const Text(
                      'Calibrate',
                      style: TextStyle(fontSize: 12),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF4DB6AC),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildDeviceInfo(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _esp32Service.stopListening();
    super.dispose();
  }
}
