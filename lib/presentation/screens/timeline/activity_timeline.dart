import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/constants/app_colors.dart';

class ActivityTimeline extends StatelessWidget {
  const ActivityTimeline({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Activity Timeline'), backgroundColor: AppColors.background, elevation: 0),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Focus Trend (Last 8 Hours)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (value) => FlLine(color: AppColors.surfaceHighlight, strokeWidth: 1)),
                    titlesData: FlTitlesData(
                      show: true,
                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30, interval: 1)),
                      leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
                    ),
                    borderData: FlBorderData(show: false),
                    minX: 0, maxX: 7, minY: 0, maxY: 100,
                    lineBarsData: [
                      LineChartBarData(
                        spots: const [
                          FlSpot(0, 40), FlSpot(1, 65), FlSpot(2, 50), FlSpot(3, 80), FlSpot(4, 90), FlSpot(5, 75), FlSpot(6, 40), FlSpot(7, 85),
                        ],
                        isCurved: true,
                        color: AppColors.primary,
                        barWidth: 4,
                        isStrokeCapRound: true,
                        dotData: FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: AppColors.primary.withOpacity(0.2),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Text('Interruption Density', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
                child: Center(child: Text('Bar chart logic implementation mapping interruptions.', style: TextStyle(color: AppColors.textSecondary))),
              ),
            )
          ],
        ),
      ),
    );
  }
}
