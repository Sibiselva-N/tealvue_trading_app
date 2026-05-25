import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/holding.dart';
import '../data/models/tick.dart';
import '../data/repositories/portfolio_repository.dart';
import 'ticker_provider.dart';

final portfolioProvider =
    StateNotifierProvider<PortfolioNotifier, List<Holding>>((ref) {
      return PortfolioNotifier(ref);
    });

class PortfolioNotifier extends StateNotifier<List<Holding>> {
  final Ref _ref;

  PortfolioNotifier(this._ref) : super([]) {
    _loadHoldings();
  }

  Future<void> _loadHoldings() async {
    final repository = _ref.read(portfolioRepositoryProvider);
    final holdings = await repository.getHoldings();
    state = holdings;
  }

  Future<void> addHolding(Holding holding) async {
    final repository = _ref.read(portfolioRepositoryProvider);
    await repository.addHolding(holding);
    state = [...state, holding];
  }

  Future<void> updateHolding(Holding holding) async {
    final repository = _ref.read(portfolioRepositoryProvider);
    await repository.updateHolding(holding);
    final index = state.indexWhere((h) => h.symbol == holding.symbol);
    if (index != -1) {
      state = [...state]..[index] = holding;
    }
  }

  Future<void> removeHolding(String symbol) async {
    final repository = _ref.read(portfolioRepositoryProvider);
    await repository.removeHolding(symbol);
    state = state.where((h) => h.symbol != symbol).toList();
  }

  Tick? getLatestTick(String symbol) {
    try {
      return _ref.read(tickerProvider(symbol));
    } catch (e) {
      return null;
    }
  }
  Future<void> clearAll() async {
    final repository = _ref.read(portfolioRepositoryProvider);
    await repository.clearAll();
    state = [];
  }
}

final portfolioSummaryProvider = Provider((ref) {
  final holdings = ref.watch(portfolioProvider);
  double totalInvested = 0;
  double totalCurrent = 0;

  for (final holding in holdings) {
    final tick = ref.watch(tickerProvider(holding.symbol));
    if (tick != null) {
      totalInvested += holding.investedValue;
      totalCurrent += holding.quantity * tick.ltp;
    }
  }

  final totalPnL = totalCurrent - totalInvested;
  double totalPnLPercent = totalInvested > 0
      ? (totalPnL / totalInvested) * 100
      : 0;

  return PortfolioSummary(
    totalInvested: totalInvested,
    totalCurrent: totalCurrent,
    totalPnL: totalPnL,
    totalPnLPercent: totalPnLPercent,
  );
});

class PortfolioSummary {
  final double totalInvested;
  final double totalCurrent;
  final double totalPnL;
  final double totalPnLPercent;

  PortfolioSummary({
    required this.totalInvested,
    required this.totalCurrent,
    required this.totalPnL,
    required this.totalPnLPercent,
  });
}
