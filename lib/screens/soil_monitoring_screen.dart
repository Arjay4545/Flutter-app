import 'package:flutter/material.dart';
import '../widgets/eggplant_illustration.dart';
import '../models/nutrient_reading.dart';
import 'analytics_screen.dart';

class SoilMonitoringScreen extends StatefulWidget {
  const SoilMonitoringScreen({super.key});

  @override
  State<SoilMonitoringScreen> createState() => _SoilMonitoringScreenState();
}

class _SoilMonitoringScreenState extends State<SoilMonitoringScreen> {
  // Sample NPK values (in real app, these would come from sensors)
  double nitrogenLevel = 75.0;
  double phosphorusLevel = 60.0;
  double potassiumLevel = 85.0;
  
  // Daily readings tracking
  List<NutrientReading> dailyReadings = [];
  DateTime lastReadingDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _initializeDailyReadings();
  }

  void _initializeDailyReadings() {
    // Generate sample historical data
    dailyReadings = AnalyticsData.generateSampleData();
    _addTodaysReading();
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
                  const Icon(
                    Icons.eco,
                    color: Colors.white,
                    size: 28,
                  ),
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
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AnalyticsScreen(),
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.analytics,
                          color: Colors.white,
                        ),
                        tooltip: 'View Analytics',
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(
                          Icons.settings,
                          color: Colors.white,
                        ),
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
                    color: Colors.white.withOpacity(0.1),
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
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Live',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
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
                        
                        // Daily Summary
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4DB6AC).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF4DB6AC).withOpacity(0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.calendar_today,
                                    color: Color(0xFF4DB6AC),
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Today\'s Summary',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF2E2E2E),
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '${dailyReadings.length} days tracked',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Readings automatically saved daily for analytics tracking',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Action buttons
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  // Refresh data and save daily reading
                                  setState(() {
                                    nitrogenLevel = (50 + (50 * (DateTime.now().millisecond / 1000))).clamp(0, 100);
                                    phosphorusLevel = (40 + (60 * (DateTime.now().second / 60))).clamp(0, 100);
                                    potassiumLevel = (60 + (40 * (DateTime.now().minute / 60))).clamp(0, 100);
                                    
                                    // Add today's reading to analytics
                                    _addTodaysReading();
                                  });
                                  
                                  // Show success message
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Data refreshed and saved to analytics!'),
                                      backgroundColor: Color(0xFF4DB6AC),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.refresh),
                                label: const Text('Refresh'),
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
                                  side: const BorderSide(color: Color(0xFF4DB6AC)),
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

  Widget _buildNPKCard(String title, double value, Color color, IconData icon, String description) {
    String status = _getNPKStatus(value);
    Color statusColor = _getStatusColor(value);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
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
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
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
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
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
            backgroundColor: color.withOpacity(0.2),
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
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildTip('💧', 'Nitrogen', 'Add compost or nitrogen-rich fertilizer for better leaf growth'),
            _buildTip('🌱', 'Phosphorus', 'Use bone meal to boost root development and flowering'),
            _buildTip('🍆', 'Potassium', 'Apply potash fertilizer to improve fruit size and quality'),
            _buildTip('🌡️', 'Temperature', 'Maintain soil temperature between 21-29°C for optimal growth'),
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
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
