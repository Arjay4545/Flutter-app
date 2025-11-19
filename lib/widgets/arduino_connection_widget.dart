import 'package:flutter/material.dart';
import '../services/arduino_service.dart';

class ArduinoConnectionWidget extends StatefulWidget {
  final Function(Map<String, double>)? onDataReceived;

  const ArduinoConnectionWidget({super.key, this.onDataReceived});

  @override
  State<ArduinoConnectionWidget> createState() =>
      _ArduinoConnectionWidgetState();
}

class _ArduinoConnectionWidgetState extends State<ArduinoConnectionWidget> {
  final ArduinoService _arduinoService = ArduinoService();
  bool _isConnected = false;
  String _statusMessage = 'Not connected';
  List<String> _availablePorts = [];
  String? _selectedPort;
  bool _isConnecting = false;

  @override
  void initState() {
    super.initState();
    _initializeArduino();
  }

  void _initializeArduino() {
    // Listen to connection status
    _arduinoService.connectionStream.listen((connected) {
      if (mounted) {
        setState(() {
          _isConnected = connected;
        });
      }
    });

    // Listen to status messages
    _arduinoService.statusStream.listen((status) {
      if (mounted) {
        setState(() {
          _statusMessage = status;
        });
      }
    });

    // Listen to sensor data
    _arduinoService.dataStream.listen((data) {
      if (widget.onDataReceived != null) {
        widget.onDataReceived!(data);
      }
    });

    // Get available ports
    _refreshPorts();
  }

  void _refreshPorts() {
    setState(() {
      _availablePorts = _arduinoService.getAvailablePorts();
      if (_availablePorts.isNotEmpty && _selectedPort == null) {
        _selectedPort = _availablePorts.first;
      }
    });
  }

  Future<void> _connect() async {
    if (_selectedPort == null) return;

    setState(() {
      _isConnecting = true;
    });

    final success = await _arduinoService.connect(_selectedPort!);

    setState(() {
      _isConnecting = false;
    });

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Connected to $_selectedPort'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _disconnect() async {
    await _arduinoService.disconnect();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Disconnected from Arduino'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _autoConnect() async {
    setState(() {
      _isConnecting = true;
    });

    final success = await _arduinoService.autoConnect();

    setState(() {
      _isConnecting = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Auto-connected to Arduino' : 'No Arduino found',
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
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  Icons.developer_board,
                  color: _isConnected ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Arduino Connection',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _isConnected
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _isConnected ? Colors.green : Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _isConnected ? 'Connected' : 'Disconnected',
                        style: TextStyle(
                          color: _isConnected ? Colors.green : Colors.red,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
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

            if (!_isConnected) ...[
              // Port selection
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedPort,
                      decoration: const InputDecoration(
                        labelText: 'Select Port',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      items: _availablePorts.map((port) {
                        return DropdownMenuItem(value: port, child: Text(port));
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedPort = value;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _refreshPorts,
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Refresh Ports',
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Connection buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isConnecting ? null : _connect,
                      icon: _isConnecting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.link),
                      label: Text(_isConnecting ? 'Connecting...' : 'Connect'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4DB6AC),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isConnecting ? null : _autoConnect,
                      icon: const Icon(Icons.search),
                      label: const Text('Auto Connect'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF4DB6AC),
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              // Connected actions
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _arduinoService.requestReading(),
                      icon: const Icon(Icons.sensors),
                      label: const Text('Read Sensors'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _disconnect,
                      icon: const Icon(Icons.link_off),
                      label: const Text('Disconnect'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _arduinoService.calibrateSensors(),
                  icon: const Icon(Icons.tune),
                  label: const Text('Calibrate Sensors'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF4DB6AC),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Don't dispose the service here as it might be used elsewhere
    super.dispose();
  }
}
