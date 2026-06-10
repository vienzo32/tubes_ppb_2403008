import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/portfolio_model.dart';
import '../services/api_service.dart';

final portfolioListProvider = StateNotifierProvider<PortfolioNotifier, AsyncValue<List<PortfolioModel>>>((ref) {
  return PortfolioNotifier();
});

class PortfolioNotifier extends StateNotifier<AsyncValue<List<PortfolioModel>>> {
  PortfolioNotifier() : super(const AsyncValue.loading()) {
    loadPortfolios();
  }

  Future<void> loadPortfolios() async {
    state = const AsyncValue.loading();
    try {
      final portfolios = await ApiService.getPortfolios();
      state = AsyncValue.data(portfolios);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addPortfolio(PortfolioModel portfolio, int userId) async {
    final success = await ApiService.createPortfolio(portfolio, userId);
    if (success) {
      await loadPortfolios();
    }
  }

  Future<void> updatePortfolio(PortfolioModel portfolio) async {
    final success = await ApiService.editPortfolio(portfolio);
    if (success) {
      await loadPortfolios();
    }
  }

  Future<void> deletePortfolio(String id) async {
    final success = await ApiService.deletePortfolio(id);
    if (success) {
      await loadPortfolios();
    }
  }

  Future<Map<String, dynamic>> toggleLike(String id, int userId) async {
    try {
      final result = await ApiService.toggleLike(id, userId);
      await loadPortfolios();
      return result;
    } catch (e) {
      return {'success': false, 'action': 'error', 'message': e.toString()};
    }
  }

  Future<void> refreshAfterComment() async {
    await loadPortfolios();
  }
}