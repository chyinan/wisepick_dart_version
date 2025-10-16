import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

// This provider will manage the state of JD prices,
// caching them in memory and persisting them to Hive.
final jdPriceCacheProvider = StateNotifierProvider<JdPriceCacheNotifier, Map<String, double>>((ref) {
  return JdPriceCacheNotifier();
});

class JdPriceCacheNotifier extends StateNotifier<Map<String, double>> {
  JdPriceCacheNotifier() : super({}) {
    _loadInitialPrices();
  }

  static const _boxName = 'jdPriceCache';

  // Load prices from Hive on startup
  Future<void> _loadInitialPrices() async {
    final box = await Hive.openBox<double>(_boxName);
    state = Map.from(box.toMap().cast<String, double>());
  }

  // Get a price for a specific SKU
  double? getPrice(String sku) {
    return state[sku];
  }

  // Update a price in both state and Hive
  Future<void> updatePrice(String sku, double price) async {
    final box = await Hive.openBox<double>(_boxName);
    await box.put(sku, price);
    state = {...state, sku: price};
  }
}
