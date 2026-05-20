import 'package:riverpod/riverpod.dart';
import '../datasources/remote/rest_api_service.dart';
import '../datasources/remote/socket_service.dart';
import '../models/tick.dart';

class MarketDataRepository {
  final RestApiService _apiService;
  final SocketService _socketService;

  MarketDataRepository(this._apiService, this._socketService);

  Future<List<Tick>> getRealtimeCurrent(String symbol, {int limit = 5000}) async {
    print('Fetching realtime current for: $symbol');
    return await _apiService.getRealtimeCurrent(symbol,limit: limit);
  }

  Future<List<Tick>> getHistoricalData({
    required String symbol,
    required String startDate,
    required String endDate,
  }) async {
    print('Fetching historical data for: $symbol from $startDate to $endDate');
    return await _apiService.getHistoricalData(
      symbol: symbol,
      startDate: startDate,
      endDate: endDate,
    );
  }

  void subscribeToTicker(String symbol, void Function(Tick) onTick) {
    print('Repository subscribing to ticker: $symbol');
    _socketService.addListener(symbol, onTick);
  }

  void unsubscribeFromTicker(String symbol, void Function(Tick) onTick) {
    print('Repository unsubscribing from ticker: $symbol');
    _socketService.removeListener(symbol, onTick);
  }

  void subscribeSymbols(List<String> symbols) {
    print('Repository subscribing to symbols: $symbols');
    _socketService.subscribe(symbols);
  }

  void unsubscribeSymbols(List<String> symbols) {
    print('Repository unsubscribing from symbols: $symbols');
    _socketService.unsubscribe(symbols);
  }

  Future<int> getTotalRecordsCount(String symbol) async {
    return await _apiService.getTotalRecordsCount(symbol);
  }

  bool get isSocketConnected => _socketService.isConnected;
  bool get isUsingMockData => _socketService.isUsingMockData;

  // Add stream for real-time connection status
  Stream<bool> get connectionStatusStream => _socketService.connectionStatusStream;
}

final marketDataRepositoryProvider = Provider<MarketDataRepository>((ref) {
  final apiService = RestApiService();
  final socketService = ref.watch(socketServiceProvider);
  return MarketDataRepository(apiService, socketService);
});

// Simple provider for socket connection status (auto-updating)
final socketConnectionStatusProvider = StreamProvider<bool>((ref) {
  final repository = ref.watch(marketDataRepositoryProvider);
  return repository.connectionStatusStream;
});

// Simple provider for mock data status (auto-updating)
final mockDataStatusProvider = StreamProvider<bool>((ref) {
  final repository = ref.watch(marketDataRepositoryProvider);
  return repository.connectionStatusStream.map((connected) => !connected);
});