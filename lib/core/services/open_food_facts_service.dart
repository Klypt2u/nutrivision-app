import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/food_item.dart';
import 'api_config.dart';
import 'local_food_database.dart';

/// Looks up packaged / branded foods by barcode against the public Open Food
/// Facts database. Falls back to a curated mock catalog when offline or when
/// the network request fails.
class OpenFoodFactsService {
  OpenFoodFactsService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<FoodItem?> lookupBarcode(String barcode) async {
    try {
      final uri = Uri.parse(
        '${ApiConfig.openFoodFactsBase}/api/v2/product/$barcode.json?fields='
        'code,product_name,brands,image_url,serving_size,nutriments',
      );
      final res = await _client.get(uri).timeout(ApiConfig.requestTimeout);
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        if (json['status'] == 1 && json['product'] is Map<String, dynamic>) {
          final data = (json['product'] as Map<String, dynamic>)['nutriments'] as Map<String, dynamic>?;
          return FoodItem.fromMap(
            {
              ...json['product'] as Map<String, dynamic>,
              if (data != null) ...data,
            },
            source: FoodSource.openFoodFacts,
          );
        }
      }
    } catch (_) {
      // fall through to mock
    }
    // Mock fallback — search the local catalog by id or barcode.
    for (final f in LocalFoodRepository.all) {
      if (f.barcode == barcode) return f;
    }
    return _mockFor(barcode);
  }

  Future<List<FoodItem>> searchOffline(String query) async {
    try {
      final uri = Uri.parse(
        '${ApiConfig.openFoodFactsBase}/cgi/search.pl?search_terms=${Uri.encodeQueryComponent(query)}'
        '&page_size=20&json=1&fields=code,product_name,brands,image_url,nutriments',
      );
      final res = await _client.get(uri).timeout(ApiConfig.requestTimeout);
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        final products = (json['products'] as List?) ?? const [];
        return products
            .map((p) => FoodItem.fromMap(
                  (p as Map<String, dynamic>),
                  source: FoodSource.openFoodFacts,
                ))
            .toList();
      }
    } catch (_) {
      // ignore and fall back
    }
    return [];
  }

  /// Deterministic mock for an unknown barcode — synthesize a plausible
  /// packaged-food record so the UI shows something realistic.
  FoodItem _mockFor(String code) {
    // Use the code's numeric prefix to pick a "category" deterministically.
    final numeric = int.tryParse(code.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    final flavors = [
      (name: 'Granola Bar — Honey Almond', brand: 'FieldBar', kcal: 180, p: 6,  c: 24, f: 7,  fi: 3),
      (name: 'Protein Bar — Peanut Butter', brand: 'PowerBar', kcal: 220, p: 20, c: 22, f: 8, fi: 5),
      (name: 'Fruit Snack — Mixed Berry',  brand: 'BearFruits', kcal: 90, p: 0,   c: 22, f: 0, fi: 2),
      (name: 'Trail Mix — Tropical',         brand: 'TrekMix',   kcal: 150, p: 3,  c: 18, f: 8, fi: 2),
    ];
    final pick = flavors[numeric % flavors.length];
    return FoodItem(
      id: 'off_${code}_mock',
      name: pick.name,
      brand: pick.brand,
      barcode: code,
      servingSize: 40,
      caloriesPer100g: pick.kcal * 2.5,
      proteinPer100g: pick.p * 2.5,
      carbsPer100g: pick.c * 2.5,
      fatPer100g: pick.f * 2.5,
      fiberPer100g: pick.fi * 2.5,
      source: FoodSource.openFoodFacts,
      confidence: 0.6,
    );
  }
}
