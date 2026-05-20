import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../data/models/tick.dart';
import '../core/utils/number_formatter.dart';
import '../core/utils/date_formatter.dart';

class CustomChart extends StatefulWidget {
  final List<Tick> ticks;
  final String symbol;
  final bool isFullScreen;
  final bool isHistorical;
  final String selectedRange;

  const CustomChart({
    super.key,
    required this.ticks,
    required this.symbol,
    this.isFullScreen = false,
    this.isHistorical = false,
    this.selectedRange = '1D',
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

  String _getXAxisLabel(int index) {
    if (index >= widget.ticks.length) return '';

    final tick = widget.ticks[index];

    if (widget.isHistorical) {
      // For historical data, show dates
      switch (widget.selectedRange) {
        case '1W':
        case '1M':
        case '3M':
        // Show date for longer ranges
          return '${tick.timestamp.day}/${tick.timestamp.month}';
        default:
        // Show time for 1D view
          return '${tick.timestamp.hour}:${tick.timestamp.minute.toString().padLeft(2, '0')}';
      }
    } else {
      // For intraday, show time
      return '${tick.timestamp.hour}:${tick.timestamp.minute.toString().padLeft(2, '0')}';
    }
  }

  int _getLabelInterval() {
    if (_spots.isEmpty) return 1;

    if (widget.isHistorical) {
      switch (widget.selectedRange) {
        case '1W':
          return (_spots.length / 7).ceil(); // Show ~7 labels
        case '1M':
          return (_spots.length / 10).ceil(); // Show ~10 labels
        case '3M':
          return (_spots.length / 12).ceil(); // Show ~12 labels
        default:
          return (_spots.length / 6).ceil(); // Show ~6 labels for 1D
      }
    } else {
      // For intraday, show ~6 labels
      return (_spots.length / 6).ceil();
    }
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
    final labelInterval = _getLabelInterval();

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
                reservedSize: 40,
                interval: labelInterval.toDouble(),
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < widget.ticks.length && index % labelInterval == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        _getXAxisLabel(index),
                        style: const TextStyle(fontSize: 10),
                        textAlign: TextAlign.center,
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
                  final index = spot.x.toInt();
                  if (index >= 0 && index < widget.ticks.length) {
                    final tick = widget.ticks[index];
                    final dateTime = widget.isHistorical && widget.selectedRange != '1D'
                        ? '${tick.timestamp.day}/${tick.timestamp.month} ${tick.timestamp.hour}:${tick.timestamp.minute}'
                        : '${tick.timestamp.hour}:${tick.timestamp.minute}';

                    return LineTooltipItem(
                      '${NumberFormatter.formatCurrency(spot.y)}\n$dateTime',
                      const TextStyle(color: Colors.white, fontSize: 12),
                    );
                  }
                  return LineTooltipItem(
                    NumberFormatter.formatCurrency(spot.y),
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