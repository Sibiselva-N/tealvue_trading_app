import 'package:riverpod/riverpod.dart';
import '../datasources/remote/rest_api_service.dart';
import '../models/symbol.dart';

class SymbolRepository {
  final RestApiService _apiService;

  SymbolRepository(this._apiService);

  Future<List<Symbol>> getSymbols() async {
    return await _apiService.getSymbols();
  }
}

final symbolRepositoryProvider = Provider<SymbolRepository>((ref) {
  final apiService = RestApiService();
  return SymbolRepository(apiService);
});
