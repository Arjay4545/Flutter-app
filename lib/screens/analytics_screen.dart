import 'package:flutter/material.dart';
import '../models/nutrient_reading.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  List<NutrientReading> readings = [];
  String selectedPeriod = '7 Days';
  String selectedNutrient = 'Nitrogen';

  @override
  void initState() {
    super.initState();
    readings = AnalyticsData.generateSampleData();
  }

  @override
  Widget build(BuildContext context) {
    final filteredReadings = _getFilteredReadings();

    return Scaffold(
      backgroundColor: const Color(0xFF14532D),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bool isWide = constraints.maxWidth > 800;
            final double horizontalPadding = isWide ? 32.0 : 20.0;

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: 20.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Nutrient Analytics',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => _exportData(),
                            icon: const Icon(
                              Icons.download,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Analytics Content
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius:
                                const BorderRadius.all(Radius.circular(30)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Period and Nutrient Selection
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildDropdown(
                                        'Period',
                                        selectedPeriod,
                                        [
                                          '7 Days',
                                          '14 Days',
                                          '30 Days',
                                        ],
                                        (value) => setState(
                                          () => selectedPeriod = value!,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _buildDropdown(
                                        'Nutrient',
                                        selectedNutrient,
                                        [
                                          'Nitrogen',
                                          'Phosphorus',
                                          'Potassium',
                                        ],
                                        (value) => setState(
                                          () => selectedNutrient = value!,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),

                                // Chart Area
                                Container(
                                  height: 200,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.grey[200]!,
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: _buildChart(filteredReadings),
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // Statistics Cards
                                const Text(
                                  'Statistics',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2E2E2E),
                                  ),
                                ),
                                const SizedBox(height: 12),

                                Expanded(
                                  child: GridView.count(
                                    crossAxisCount: 2,
                                    crossAxisSpacing: 16,
                                    mainAxisSpacing: 12,
                                    childAspectRatio: 1.8,
                                    children: [
                                      _buildStatCard(
                                        'Average',
                                        _getAverage(filteredReadings),
                                        Colors.blue,
                                      ),
                                      _buildStatCard(
                                        'Highest',
                                        _getHighest(filteredReadings),
                                        Colors.green,
                                      ),
                                      _buildStatCard(
                                        'Lowest',
                                        _getLowest(filteredReadings),
                                        Colors.orange,
                                      ),
                                      _buildStatCard(
                                        'Trend',
                                        _getTrend(filteredReadings),
                                        Colors.purple,
                                      ),
                                    ],
                                  ),
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
          },
        ),
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    String value,
    List<String> items,
    Function(String?) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2E2E2E),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              items: items
                  .map(
                    (item) => DropdownMenuItem(value: item, child: Text(item)),
                  )
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChart(List<NutrientReading> data) {
    if (data.isEmpty) {
      return const Center(child: Text('No data available'));
    }

    final maxValue = _getMaxValue(data);
    final minValue = _getMinValue(data);

    return Column(
      children: [
        // Chart Title
        Text(
          '$selectedNutrient Levels Over Time',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2E2E2E),
          ),
        ),
        const SizedBox(height: 16),

        // Simple Line Chart
        Expanded(
          child: CustomPaint(
            size: Size.infinite,
            painter: LineChartPainter(
              data: data,
              nutrient: selectedNutrient,
              maxValue: maxValue,
              minValue: minValue,
            ),
          ),
        ),

        // X-axis labels
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _formatDate(data.first.date),
              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            ),
            Text(
              _formatDate(data.last.date),
              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(_getStatIcon(title), color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getStatIcon(String title) {
    switch (title) {
      case 'Average':
        return Icons.trending_flat;
      case 'Highest':
        return Icons.trending_up;
      case 'Lowest':
        return Icons.trending_down;
      case 'Trend':
        return Icons.show_chart;
      default:
        return Icons.analytics;
    }
  }

  List<NutrientReading> _getFilteredReadings() {
    final days = int.parse(selectedPeriod.split(' ')[0]);
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    return readings
        .where((reading) => reading.date.isAfter(cutoffDate))
        .toList();
  }

  double _getNutrientValue(NutrientReading reading) {
    switch (selectedNutrient) {
      case 'Nitrogen':
        return reading.nitrogen;
      case 'Phosphorus':
        return reading.phosphorus;
      case 'Potassium':
        return reading.potassium;
      default:
        return reading.nitrogen;
    }
  }

  double _getMaxValue(List<NutrientReading> data) {
    return data.map(_getNutrientValue).reduce((a, b) => a > b ? a : b);
  }

  double _getMinValue(List<NutrientReading> data) {
    return data.map(_getNutrientValue).reduce((a, b) => a < b ? a : b);
  }

  String _getAverage(List<NutrientReading> data) {
    if (data.isEmpty) return '0%';
    final sum = data.map(_getNutrientValue).reduce((a, b) => a + b);
    return '${(sum / data.length).toStringAsFixed(1)}%';
  }

  String _getHighest(List<NutrientReading> data) {
    if (data.isEmpty) return '0%';
    return '${_getMaxValue(data).toStringAsFixed(1)}%';
  }

  String _getLowest(List<NutrientReading> data) {
    if (data.isEmpty) return '0%';
    return '${_getMinValue(data).toStringAsFixed(1)}%';
  }

  String _getTrend(List<NutrientReading> data) {
    if (data.length < 2) return 'Stable';
    final first = _getNutrientValue(data.first);
    final last = _getNutrientValue(data.last);
    final diff = last - first;

    if (diff > 5) return '↗ Rising';
    if (diff < -5) return '↘ Falling';
    return '→ Stable';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}';
  }

  void _exportData() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Analytics data exported successfully!'),
        backgroundColor: Color(0xFF4DB6AC),
      ),
    );
  }
}

class LineChartPainter extends CustomPainter {
  final List<NutrientReading> data;
  final String nutrient;
  final double maxValue;
  final double minValue;

  LineChartPainter({
    required this.data,
    required this.nutrient,
    required this.maxValue,
    required this.minValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = _getNutrientColor()
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final pointPaint = Paint()
      ..color = _getNutrientColor()
      ..style = PaintingStyle.fill;

    final path = Path();
    final points = <Offset>[];

    for (int i = 0; i < data.length; i++) {
      final x = (i / (data.length - 1)) * size.width;
      final value = _getNutrientValue(data[i]);
      final normalizedValue = (value - minValue) / (maxValue - minValue);
      final y = size.height - (normalizedValue * size.height);

      points.add(Offset(x, y));

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    // Draw line
    canvas.drawPath(path, paint);

    // Draw points
    for (final point in points) {
      canvas.drawCircle(point, 3, pointPaint);
    }
  }

  double _getNutrientValue(NutrientReading reading) {
    switch (nutrient) {
      case 'Nitrogen':
        return reading.nitrogen;
      case 'Phosphorus':
        return reading.phosphorus;
      case 'Potassium':
        return reading.potassium;
      default:
        return reading.nitrogen;
    }
  }

  Color _getNutrientColor() {
    switch (nutrient) {
      case 'Nitrogen':
        return Colors.blue;
      case 'Phosphorus':
        return Colors.orange;
      case 'Potassium':
        return Colors.purple;
      default:
        return Colors.blue;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
