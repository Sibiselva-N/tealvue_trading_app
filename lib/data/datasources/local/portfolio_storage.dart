import 'package:hive_flutter/hive_flutter.dart';
import '../../models/holding.dart';

class PortfolioStorage {
  static const String _boxName = 'portfolio';

  Future<Box<Holding>> get _box async => await Hive.openBox<Holding>(_boxName);

  Future<List<Holding>> getHoldings() async {
    final box = await _box;
    return box.values.toList();
  }

  Future<void> addHolding(Holding holding) async {
    final box = await _box;
    await box.put(holding.symbol, holding);
  }

  Future<void> updateHolding(Holding holding) async {
    final box = await _box;
    await box.put(holding.symbol, holding);
  }

  Future<void> removeHolding(String symbol) async {
    final box = await _box;
    await box.delete(symbol);
  }

  Future<void> clearAll() async {
    final box = await _box;
    await box.clear();
  }
}
