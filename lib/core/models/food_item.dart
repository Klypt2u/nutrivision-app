/// Provenance of a [FoodItem] — drives iconography and confidence chips.
enum FoodSource {
  local,
  openFoodFacts,
  aiVision,
  userCreated,
  planner;

  String get badge {
    switch (this) {
      case FoodSource.local:          return 'Local';
      case FoodSource.openFoodFacts:  return 'OFF';
      case FoodSource.aiVision:       return 'AI';
      case FoodSource.userCreated:    return 'Custom';
      case FoodSource.planner:        return 'Plan';
    }
  }
}

/// Canonical food definition shared by AI scanner, barcode, search, and
/// manual log entries. All values are stored per 100 g for clean math.
class FoodItem {
  final String id;
  final String name;
  final String? brand;
  final String? imageUrl;
  final String? barcode;
  final double servingSize;
  final String servingUnit; // 'g', 'ml', 'serving'
  final double caloriesPer100g;
  final double proteinPer100g;
  final double carbsPer100g;
  final double fatPer100g;
  final double fiberPer100g;
  final FoodSource source;
  final double? confidence; // 0..1 (AI only)

  const FoodItem({
    required this.id,
    required this.name,
    this.brand,
    this.imageUrl,
    this.barcode,
    this.servingSize = 100.0,
    this.servingUnit = 'g',
    required this.caloriesPer100g,
    required this.proteinPer100g,
    required this.carbsPer100g,
    required this.fatPer100g,
    this.fiberPer100g = 0.0,
    this.source = FoodSource.local,
    this.confidence,
  });

  /// Compute macronutrients for [grams] of food consumed.
  ({double kcal, double protein, double carbs, double fat, double fiber}) macrosFor(double grams) {
    final factor = grams / 100.0;
    return (
      kcal: caloriesPer100g * factor,
      protein: proteinPer100g * factor,
      carbs: carbsPer100g * factor,
      fat: fatPer100g * factor,
      fiber: fiberPer100g * factor,
    );
  }

  factory FoodItem.fromMap(Map<String, dynamic> m,
      {FoodSource source = FoodSource.local, String? idOverride}) {
    return FoodItem(
      id: idOverride ?? (m['id'] ?? DateTime.now().microsecondsSinceEpoch.toString()).toString(),
      name: (m['name'] ?? m['product_name'] ?? 'Unknown') as String,
      brand: (m['brand'] ?? m['brands']) as String?,
      imageUrl: (m['image_url'] ?? m['imageUrl']) as String?,
      barcode: (m['barcode'] ?? m['code']) as String?,
      servingSize: ((m['serving_size'] ?? m['servingSize'] ?? 100) as num).toDouble(),
      servingUnit: (m['serving_unit'] ?? m['servingUnit'] ?? 'g') as String,
      caloriesPer100g: ((m['kcal_100g'] ?? m['energy-kcal_100g'] ?? m['caloriesPer100g'] ?? 0) as num).toDouble(),
      proteinPer100g: ((m['protein_100g'] ?? m['proteins_100g'] ?? m['proteinPer100g'] ?? 0) as num).toDouble(),
      carbsPer100g: ((m['carbs_100g'] ?? m['carbohydrates_100g'] ?? m['carbsPer100g'] ?? 0) as num).toDouble(),
      fatPer100g: ((m['fat_100g'] ?? m['fatPer100g'] ?? 0) as num).toDouble(),
      fiberPer100g: ((m['fiber_100g'] ?? m['fiberPer100g'] ?? 0) as num).toDouble(),
      source: source,
      confidence: (m['confidence'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'brand': brand,
        'image_url': imageUrl,
        'barcode': barcode,
        'serving_size': servingSize,
        'serving_unit': servingUnit,
        'kcal_100g': caloriesPer100g,
        'protein_100g': proteinPer100g,
        'carbs_100g': carbsPer100g,
        'fat_100g': fatPer100g,
        'fiber_100g': fiberPer100g,
        'source': source.name,
        'confidence': confidence,
      };

  /// Human-readable subtitle (brand + source).
  String? get subtitle {
    if (brand != null && brand!.isNotEmpty) return brand;
    switch (source) {
      case FoodSource.aiVision:        return 'AI Recognized';
      case FoodSource.openFoodFacts:   return 'Open Food Facts';
      case FoodSource.local:           return 'Local database';
      case FoodSource.userCreated:     return 'Custom food';
      case FoodSource.planner:         return 'Meal plan';
    }
  }

  /// Short emoji for placeholder / quick visual cue.
  String get emoji {
    final n = name.toLowerCase();
    if (n.contains('chicken'))         return '🍗';
    if (n.contains('salad'))           return '🥗';
    if (n.contains('pizza'))           return '🍕';
    if (n.contains('burger'))          return '🍔';
    if (n.contains('rice'))            return '🍚';
    if (n.contains('pasta'))           return '🍝';
    if (n.contains('bread') || n.contains('toast')) return '🍞';
    if (n.contains('yogurt') || n.contains('yoghurt')) return '🥛';
    if (n.contains('fruit') || n.contains('apple') || n.contains('berry')) return '🍎';
    if (n.contains('coffee') || n.contains('espresso')) return '☕';
    if (n.contains('tea'))             return '🍵';
    if (n.contains('egg'))             return '🥚';
    if (n.contains('fish') || n.contains('salmon') || n.contains('tuna')) return '🐟';
    if (n.contains('avocado'))         return '🥑';
    if (n.contains('cheese'))          return '🧀';
    if (n.contains('nuts') || n.contains('almond')) return '🥜';
    if (n.contains('shake') || n.contains('smoothie')) return '🥤';
    if (n.contains('water'))           return '💧';
    if (n.contains('cookie') || n.contains('cake') || n.contains('dessert')) return '🍪';
    if (n.contains('chips') || n.contains('crisps')) return '🍟';
    return '🍴';
  }
}
