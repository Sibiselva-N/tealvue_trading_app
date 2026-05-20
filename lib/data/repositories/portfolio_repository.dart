import 'package:riverpod/riverpod.dart';
import '../datasources/local/portfolio_storage.dart';
import '../models/holding.dart';

class PortfolioRepository {
  final PortfolioStorage _storage;

  PortfolioRepository(this._storage);

  Future<List<Holding>> getHoldings() async {
    return await _storage.getHoldings();
  }

  Future<void> addHolding(Holding holding) async {
    await _storage.addHolding(holding);
  }

  Future<void> updateHolding(Holding holding) async {
    await _storage.updateHolding(holding);
  }

  Future<void> removeHolding(String symbol) async {
    await _storage.removeHolding(symbol);
  }

  Future<void> clearAll() async {
    await _storage.clearAll();
  }
}

final portfolioRepositoryProvider = Provider<PortfolioRepository>((ref) {
  final storage = PortfolioStorage();
  return PortfolioRepository(storage);
});
