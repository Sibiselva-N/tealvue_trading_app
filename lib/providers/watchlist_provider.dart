import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/symbol.dart';
import '../data/repositories/symbol_repository.dart';
import '../core/utils/storage_helper.dart';

final watchlistProvider = StateNotifierProvider<WatchlistNotifier, List<String>>((ref) {
  return WatchlistNotifier();
});

class WatchlistNotifier extends StateNotifier<List<String>> {
  bool _isInitialized = false;

  WatchlistNotifier() : super([]) {
    _loadWatchlist();
  }

  Future<void> _loadWatchlist() async {
    if (_isInitialized) return;
    _isInitialized = true;

    final saved = await StorageHelper.getWatchlist();
    state = saved;
  }

  Future<void> addSymbol(String symbol) async {
    if (!state.contains(symbol)) {
      state = [...state, symbol];
      await StorageHelper.saveWatchlist(state);
      print('Added $symbol to watchlist');
    }
  }

  Future<void> removeSymbol(String symbol) async {
    state = state.where((s) => s != symbol).toList();
    await StorageHelper.saveWatchlist(state);
    print('Removed $symbol from watchlist');
  }

  Future<void> clearAll() async {
    state = [];
    await StorageHelper.saveWatchlist(state);
    print('Cleared all watchlist');
  }

  bool isInWatchlist(String symbol) {
    return state.contains(symbol);
  }
}

final symbolsProvider = FutureProvider<List<Symbol>>((ref) async {
  final repository = ref.watch(symbolRepositoryProvider);
  return await repository.getSymbols();
});

final filteredSymbolsProvider = FutureProvider.family<List<Symbol>, String>((ref, query) async {
  final symbols = await ref.watch(symbolsProvider.future);
  if (query.isEmpty) return symbols;
  return symbols.where((symbol) =>
  symbol.symbol.toLowerCase().contains(query.toLowerCase()) ||
      symbol.name.toLowerCase().contains(query.toLowerCase())
  ).toList();
});

// Provider to get valid symbols set for validation
final validSymbolsProvider = Provider<Set<String>>((ref) {
  final symbolsAsync = ref.watch(symbolsProvider);
  return symbolsAsync.maybeWhen(
    data: (symbols) => symbols.map((s) => s.symbol).toSet(),
    orElse: () => {'RELIANCE', 'TCS', 'INFY', 'HDFCBANK', 'ICICIBANK', 'SBIN', 'ITC', 'AXISBANK'},
  );
});