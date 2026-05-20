import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../core/utils/date_formatter.dart';
import '../data/models/tick.dart';
import '../core/utils/number_formatter.dart';

class CustomChart extends StatefulWidget {
  final List<Tick> ticks;
  final String symbol;
  final bool isFullScreen;
  final bool isHistorical;

  const CustomChart({
    super.key,
    required this.ticks,
    required this.symbol,
    this.isFullScreen = false,
    this.isHistorical = false,
  });

  @override
  State<CustomChart> createState() => _CustomChartState();
}

class _CustomChartState extends State<CustomChart> {
  List<FlSpot> _spots = [];

  @override
  void initState() {
    super.initState();
    _updateSpots();
  }

  @override
  void didUpdateWidget(CustomChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ticks != widget.ticks) {
      _updateSpots();
    }
  }

  void _updateSpots() {
    _spots = widget.ticks.asMap().entries.map((entry) {
      return FlSpot(
        entry.key.toDouble(),
        entry.value.ltp,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_spots.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading chart data...'),
          ],
        ),
      );
    }

    final minY = _spots.map((s) => s.y).reduce((a, b) => a < b ? a : b) * 0.995;
    final maxY = _spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) * 1.005;

    return Container(
      margin: const EdgeInsets.all(8),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            horizontalInterval: (maxY - minY) / 5,
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 60,
                getTitlesWidget: (value, meta) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text(
                      NumberFormatter.formatCurrency(value),
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() % 20 == 0 && value.toInt() < _spots.length) {
                    final tick = widget.ticks[value.toInt()];
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '${tick.timestamp.hour}:${tick.timestamp.minute.toString().padLeft(2, '0')}',
                        style: const TextStyle(fontSize: 10),
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: true),
          lineBarsData: [
            LineChartBarData(
              spots: _spots,
              isCurved: true,
              curveSmoothness: 0.3,
              color: Theme.of(context).primaryColor,
              barWidth: 2,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: Theme.of(context).primaryColor.withOpacity(0.1),
              ),
            ),
          ],
          minX: 0,
          maxX: _spots.length.toDouble(),
          minY: minY,
          maxY: maxY,
          lineTouchData: LineTouchData(
            enabled: true,
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (List<LineBarSpot> touchedSpots) {
                return touchedSpots.map((spot) {
                  final tick = widget.ticks[spot.x.toInt()];
                  return LineTooltipItem(
                    '${NumberFormatter.formatCurrency(spot.y)}\n${DateFormatter.formatTime(tick.timestamp)}',
                    const TextStyle(color: Colors.white, fontSize: 12),
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }
}
