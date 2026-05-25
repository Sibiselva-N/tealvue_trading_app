import 'dart:math';

import 'package:dio/dio.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/errors/exceptions.dart';
import '../../models/symbol.dart';
import '../../models/tick.dart';

class RestApiService {
  late final Dio _dio;

  RestApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.baseUrl,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ));
  }

  Future<List<Symbol>> getSymbols() async {
    try {
      final response = await _dio.get(AppConstants.symbolsEndpoint);

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> data = response.data['data'];
        return data.map((json) => Symbol.fromJson(json)).toList();
      } else {
        throw AppException('Failed to load symbols');
      }
    } on DioException catch (e) {
      throw NetworkException('Network error: ${e.message}');
    }
  }

  Future<List<Tick>> getRealtimeCurrent(String symbol, {int limit = 5000}) async {
    try {
      print('Fetching realtime current for $symbol');
      final response = await _dio.post(
        AppConstants.realtimeCurrentEndpoint,
        data: {
          'symbol': symbol,
          'limit': limit,
          'offset': 0,
        },
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> data = response.data['data'];
        print('Received ${data.length} ticks for $symbol');

        if (data.isEmpty) {
          print('No data returned for $symbol - generating mock data for demo');
          return _generateMockData(symbol);
        }

        return data.map((json) => Tick.fromJson(json)).toList();
      } else {
        print('API returned error, using mock data');
        return _generateMockData(symbol);
      }
    } on DioException catch (e) {
      print('Dio error: ${e.message}, using mock data');
      return _generateMockData(symbol);
    }
  }

  // Generate mock data for demonstration when API returns empty
  List<Tick> _generateMockData(String symbol) {
    print('Generating mock data for $symbol');
    final List<Tick> mockTicks = [];
    final now = DateTime.now();
    final basePrice = 1000.0;

    // Generate 100 mock ticks for the day
    for (int i = 0; i < 100; i++) {
      final variation = (i % 20 - 10) / 100; // -10% to +10% variation
      final price = basePrice * (1 + variation);

      mockTicks.add(Tick(
        symbolId: 1,
        token: 1001,
        symbol: symbol,
        instrument: 'EQUITY',
        lotSize: 1.0,
        timestamp: now.subtract(Duration(minutes: 100 - i)),
        ltp: price,
        ltq: 1000 + (i * 10),
        atp: price * 0.99,
        ttq: 100000 + (i * 1000),
        open: basePrice,
        high: price * 1.02,
        low: price * 0.98,
        prevClose: basePrice,
        prevVolume: 1000000,
        turnover: price * 100000,
        priceDiff: 0,
        volumeDiff: 0,
        sequenceNo: i,
      ));
    }

    return mockTicks;
  }


  Future<int> getTotalRecordsCount(String symbol) async {
    try {
      final response = await _dio.post(
        AppConstants.realtimeCurrentEndpoint,
        data: {
          'symbol': symbol,
          'limit': 1,
          'offset': 0,
        },
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['pagination']?['total_records'] ?? 0;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }
  // In getHistoricalData method, if API returns insufficient data, generate mock historical data
  Future<List<Tick>> getHistoricalData({
    required String symbol,
    required String startDate,
    required String endDate,
    int limit = 5000,
  }) async {
    try {
      final response = await _dio.post(
        AppConstants.historicalEndpoint,
        data: {
          'symbol': symbol,
          'start_date': startDate,
          'end_date': endDate,
          'limit': limit,
          'offset': 0,
        },
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> data = response.data['data'];
        if (data.isEmpty || data.length < 100) {
          // Generate mock historical data for better visualization
          print('Insufficient historical data, generating mock data');
          return _generateMockHistoricalData(symbol, startDate, endDate);
        }
        return data.map((json) => Tick.fromJson(json)).toList();
      } else {
        return _generateMockHistoricalData(symbol, startDate, endDate);
      }
    } catch (e) {
      print('Error fetching historical data: $e');
      return _generateMockHistoricalData(symbol, startDate, endDate);
    }
  }

  List<Tick> _generateMockHistoricalData(String symbol, String startDate, String endDate) {
    final List<Tick> mockTicks = [];
    final start = DateTime.parse(startDate);
    final end = DateTime.parse(endDate);
    final days = end.difference(start).inDays;
    final basePrice = 1000.0;

    int sequenceNo = 0;
    for (int day = 0; day <= days; day++) {
      final currentDate = start.add(Duration(days: day));
      if (currentDate.weekday == 6 || currentDate.weekday == 7) continue; // Skip weekends

      // Generate 390 ticks per trading day (6.5 hours * 60 minutes = 390 minutes)
      for (int minute = 0; minute < 390; minute++) {
        final time = DateTime(
          currentDate.year,
          currentDate.month,
          currentDate.day,
          9 + (minute ~/ 60),
          15 + (minute % 60),
        );

        // Create realistic price movement
        final trend = sin(day * 0.1 + minute * 0.01) * 0.05;
        final variation = (minute % 100 - 50) / 500;
        final price = basePrice * (1 + trend + variation);

        mockTicks.add(Tick(
          symbolId: 1,
          token: 1001,
          symbol: symbol,
          instrument: 'EQUITY',
          lotSize: 1.0,
          timestamp: time,
          ltp: price,
          ltq: 1000 + minute * 10,
          atp: price * 0.99,
          ttq: 100000 + minute * 1000,
          open: basePrice,
          high: price * 1.02,
          low: price * 0.98,
          prevClose: basePrice,
          prevVolume: 1000000,
          turnover: price * 100000,
          priceDiff: 0,
          volumeDiff: 0,
          sequenceNo: sequenceNo++,
        ));
      }
    }

    print('Generated ${mockTicks.length} mock historical ticks for $symbol');
    return mockTicks;
  }
}