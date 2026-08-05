import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/food_item.dart';
import '../services/local_food_database.dart';
import '../services/open_food_facts_service.dart';
import '../services/storage_service.dart';

final openFoodFactsServiceProvider =
    Provider<OpenFoodFactsService>((_) => OpenFoodFactsService());

/// Query text for the global search.
final searchQueryProvider = StateProvider<String>((_) => '');

/// Search results. Combines local + custom foods first; optional OFF search
/// augments the second page.
final foodSearchProvider =
    NotifierProvider<FoodSearchNotifier, List<FoodItem>>(FoodSearchNotifier.new);

class FoodSearchNotifier extends Notifier<List<FoodItem>> {
  @override
  List<FoodItem> build() {
    LocalFoodRepository.init();
    final q = ref.watch(searchQueryProvider);
    final all = [
      ...LocalFoodRepository.all,
      ...StorageService.loadAllCustomFoods(),
    ];
    if (q.trim().isEmpty) return LocalFoodRepository.suggestions(limit: 24);
    final hits = <FoodItem, double>{};
    final ql = q.toLowerCase();
    for (final f in all) {
      final score = _match(f, ql);
      if (score > 0) hits[f] = score;
    }
    final list = hits.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return list.take(40).map((e) => e.key).toList();
  }

  double _match(FoodItem f, String q) {
    var s = 0.0;
    if (f.name.toLowerCase().startsWith(q)) s += 5;
    if (f.name.toLowerCase().contains(q))   s += 2;
    final b = (f.brand ?? '').toLowerCase();
    if (b.contains(q))                     s += 1.5;
    if ((f.barcode ?? '').contains(q))      s += 1.0;
    return s;
  }
}
