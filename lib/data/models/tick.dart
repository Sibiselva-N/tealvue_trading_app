import 'package:equatable/equatable.dart';
import '../../core/utils/date_formatter.dart';

class Tick extends Equatable {
  final int symbolId;
  final int token;
  final String symbol;
  final String instrument;
  final double lotSize;
  final DateTime timestamp;
  final double ltp; // Last Traded Price
  final int ltq; // Last Traded Quantity
  final double atp; // Average Traded Price
  final int ttq; // Total Traded Quantity
  final double open;
  final double high;
  final double low;
  final double prevClose;
  final int prevVolume;
  final double turnover;
  final int priceDiff;
  final int volumeDiff;
  final int sequenceNo;

  const Tick({
    required this.symbolId,
    required this.token,
    required this.symbol,
    required this.instrument,
    required this.lotSize,
    required this.timestamp,
    required this.ltp,
    required this.ltq,
    required this.atp,
    required this.ttq,
    required this.open,
    required this.high,
    required this.low,
    required this.prevClose,
    required this.prevVolume,
    required this.turnover,
    required this.priceDiff,
    required this.volumeDiff,
    required this.sequenceNo,
  });

  factory Tick.fromJson(Map<String, dynamic> json) {
    // Helper function to safely convert to int
    int _toInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    // Helper function to safely convert to double
    double _toDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return Tick(
      symbolId: _toInt(json['SYMBOLID']),
      token: _toInt(json['TOKEN']),
      symbol: json['SYMBOL']?.toString() ?? '',
      instrument: json['INSTRUMENT']?.toString() ?? '',
      lotSize: _toDouble(json['LOTSIZE']),
      timestamp: _parseTimestamp(json['TS']),
      ltp: _toDouble(json['LTP']),
      ltq: _toInt(json['LTQ']),
      atp: _toDouble(json['ATP']),
      ttq: _toInt(json['TTQ']),
      open: _toDouble(json['OPEN']),
      high: _toDouble(json['HIGH']),
      low: _toDouble(json['LOW']),
      prevClose: _toDouble(json['PREV_CLOSE']),
      prevVolume: _toInt(json['PREV_VOLUME']),
      turnover: _toDouble(json['TURNOVER']),
      priceDiff: _toInt(json['PRICE_DIFF']),
      volumeDiff: _toInt(json['VOLUME_DIFF']),
      sequenceNo: _toInt(json['SEQUENCE_NO']),
    );
  }

  static DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return DateTime.now();
    try {
      // Handle different timestamp formats
      String tsStr = timestamp.toString();
      // Format: "2026-05-04 09:15:01+05:30"
      return DateFormatter.parseApiDate(tsStr);
    } catch (e) {
      print('Error parsing timestamp: $timestamp');
      return DateTime.now();
    }
  }

  double get change => ltp - prevClose;
  double get changePercent => prevClose != 0 ? (change / prevClose) * 100 : 0;
  double get vwap => ttq > 0 ? turnover / ttq : ltp;

  @override
  List<Object?> get props => [symbol, sequenceNo, timestamp];
}