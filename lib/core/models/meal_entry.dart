import 'package:uuid/uuid.dart';

import 'food_item.dart';

/// Classification of meals. Drives grouping on the dashboard.
enum MealType {
  breakfast,
  lunch,
  dinner,
  snack;

  String get label {
    switch (this) {
      case MealType.breakfast: return 'Breakfast';
      case MealType.lunch:     return 'Lunch';
      case MealType.dinner:    return 'Dinner';
      case MealType.snack:     return 'Snacks';
    }
  }

  String get emoji {
    switch (this) {
      case MealType.breakfast: return '🌅';
      case MealType.lunch:     return '🥗';
      case MealType.dinner:    return '🍽';
      case MealType.snack:     return '🍎';
    }
  }

  /// Hour-of-day heuristic for "now" routing.
  static MealType forHour(DateTime dt) {
    final h = dt.hour;
    if (h < 10) return MealType.breakfast;
    if (h < 15) return MealType.lunch;
    if (h < 21) return MealType.dinner;
    return MealType.snack;
  }
}

/// A logged meal — a [FoodItem] with an explicit portion size, eaten at a
/// specific meal-type window.
class MealEntry {
  final String id;
  final String name;
  final String? brand;
  final double gramsConsumed;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;
  final MealType mealType;
  final DateTime consumedAt;
  final FoodSource source;
  final double? confidence;

  const MealEntry({
    required this.id,
    required this.name,
    this.brand,
    required this.gramsConsumed,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.fiber = 0.0,
    required this.mealType,
    required this.consumedAt,
    this.source = FoodSource.userCreated,
    this.confidence,
  });

  MealEntry.create({
    required String? id,
    required this.name,
    this.brand,
    required this.gramsConsumed,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
    required this.mealType,
    required this.consumedAt,
    required this.source,
    this.confidence,
  }) : id = id ?? const Uuid().v4();

  factory MealEntry.fromFood(FoodItem food, double grams, MealType type) {
    final m = food.macrosFor(grams);
    return MealEntry.create(
      id: null,
      name: food.name,
      brand: food.brand,
      gramsConsumed: grams,
      calories: m.kcal,
      protein: m.protein,
      carbs: m.carbs,
      fat: m.fat,
      fiber: m.fiber,
      mealType: type,
      consumedAt: DateTime.now(),
      source: food.source,
      confidence: food.confidence,
    );
  }

  factory MealEntry.fromJson(Map<String, dynamic> j) => MealEntry.create(
        id: j['id'] as String?,
        name: j['name'] as String,
        brand: j['brand'] as String?,
        gramsConsumed: (j['grams'] as num).toDouble(),
        calories: (j['kcal'] as num).toDouble(),
        protein: (j['protein'] as num).toDouble(),
        carbs: (j['carbs'] as num).toDouble(),
        fat: (j['fat'] as num).toDouble(),
        fiber: ((j['fiber'] as num?) ?? 0).toDouble(),
        mealType: MealType.values.firstWhere(
            (e) => e.name == (j['mealType'] as String?),
            orElse: () => MealType.snack),
        consumedAt: DateTime.tryParse((j['consumedAt'] ?? '') as String) ?? DateTime.now(),
        source: FoodSource.values.firstWhere(
            (e) => e.name == (j['source'] as String?),
            orElse: () => FoodSource.userCreated),
        confidence: (j['confidence'] as num?)?.toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'brand': brand,
        'grams': gramsConsumed,
        'kcal': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
        'fiber': fiber,
        'mealType': mealType.name,
        'consumedAt': consumedAt.toIso8601String(),
        'source': source.name,
        'confidence': confidence,
      };

  String get emoji {
    final n = name.toLowerCase();
    if (n.contains('chicken'))         return '🍗';
    if (n.contains('salad'))           return '🥗';
    if (n.contains('pizza'))           return '🍕';
    if (n.contains('burger'))          return '🍔';
    if (n.contains('rice'))            return '🍚';
    if (n.contains('pasta'))           return '🍝';
    if (n.contains('yogurt') || n.contains('yoghurt')) return '🥛';
    if (n.contains('apple') || n.contains('fruit') || n.contains('berry')) return '🍎';
    if (n.contains('egg'))             return '🥚';
    if (n.contains('salmon') || n.contains('tuna')) return '🐟';
    if (n.contains('avocado'))         return '🥑';
    if (n.contains('oatmeal') || n.contains('porridge')) return '🥣';
    if (n.contains('smoothie') || n.contains('shake')) return '🥤';
    return '🍴';
  }
}
