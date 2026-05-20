import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/datasources/remote/socket_service.dart';
import '../data/models/tick.dart';
import '../data/repositories/market_data_repository.dart';
import 'watchlist_provider.dart';

class TickerNotifier extends StateNotifier<Tick?> {
  final String symbol;
  final Ref ref;
  bool _isSubscribed = false;
  bool _isLoading = true;
  String? _error;

  TickerNotifier(this.symbol, this.ref) : super(null) {
    _subscribe();
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    try {
      print('Fetching initial data for $symbol');
      final repository = ref.read(marketDataRepositoryProvider);
      final ticks = await repository.getRealtimeCurrent(symbol, limit: 1);
      if (ticks.isNotEmpty) {
        print('✅ Setting initial tick for $symbol: ${ticks.first.ltp}');
        state = ticks.first;

        // Set base price in socket service for mock data fallback
        final socketService = ref.read(socketServiceProvider);
        socketService.setBasePrice(symbol, ticks.first.prevClose);
      } else {
        print('⚠️ No initial data for $symbol');
      }
    } catch (e, stackTrace) {
      print('❌ Error fetching initial data for $symbol: $e');
      _error = e.toString();
    } finally {
      _isLoading = false;
    }
  }

  void _subscribe() {
    if (_isSubscribed) return;

    print('TickerNotifier subscribing to: $symbol');
    final repository = ref.read(marketDataRepositoryProvider);
    repository.subscribeToTicker(symbol, _onTick);
    _isSubscribed = true;
  }

  void _onTick(Tick tick) {
    if (tick.symbol == symbol) {
      print('🔄 Updating tick for $symbol: LTP=${tick.ltp}, Change=${tick.change}');
      state = tick;
    }
  }

  bool get isLoading => _isLoading;
  String? get error => _error;

  @override
  void dispose() {
    if (_isSubscribed) {
      print('TickerNotifier disposing for: $symbol');
      final repository = ref.read(marketDataRepositoryProvider);
      repository.unsubscribeFromTicker(symbol, _onTick);
    }
    super.dispose();
  }
}

final tickerProvider = StateNotifierProvider.family<TickerNotifier, Tick?, String>((ref, symbol) {
  return TickerNotifier(symbol, ref);
});