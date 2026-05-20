import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/symbol.dart';
import '../data/repositories/symbol_repository.dart';
import '../core/utils/storage_helper.dart';

final watchlistProvider =
    StateNotifierProvider<WatchlistNotifier, List<String>>((ref) {
      return WatchlistNotifier();
    });

class WatchlistNotifier extends StateNotifier<List<String>> {
  WatchlistNotifier() : super([]) {
    _loadWatchlist();
  }

  void _loadWatchlist() {
    final saved = StorageHelper.getWatchlist();
    state = saved;
  }

  void addSymbol(String symbol) {
    if (!state.contains(symbol)) {
      state = [...state, symbol];
      StorageHelper.saveWatchlist(state);
    }
  }

  void removeSymbol(String symbol) {
    state = state.where((s) => s != symbol).toList();
    StorageHelper.saveWatchlist(state);
  }

  bool isInWatchlist(String symbol) {
    return state.contains(symbol);
  }
}

final symbolsProvider = FutureProvider<List<Symbol>>((ref) async {
  final repository = ref.watch(symbolRepositoryProvider);
  return await repository.getSymbols();
});

final filteredSymbolsProvider = FutureProvider.family<List<Symbol>, String>((
  ref,
  query,
) async {
  final symbols = await ref.watch(symbolsProvider.future);
  if (query.isEmpty) return symbols;
  return symbols
      .where(
        (symbol) =>
            symbol.symbol.toLowerCase().contains(query.toLowerCase()) ||
            symbol.name.toLowerCase().contains(query.toLowerCase()),
      )
      .toList();
});
