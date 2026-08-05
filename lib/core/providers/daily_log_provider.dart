import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/food_item.dart';
import '../models/meal_entry.dart';
import '../services/storage_service.dart';
import 'user_profile_provider.dart';

/// All entries for the user's currently-selected day.
///
/// Surfaced through Riverpod so any widget (dashboard, history, planner)
/// can stay in sync.
final selectedDayProvider = StateProvider<DateTime>((_) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

final dailyEntriesProvider =
    NotifierProvider<DailyLogNotifier, List<MealEntry>>(DailyLogNotifier.new);

class DailyLogNotifier extends Notifier<List<MealEntry>> {
  @override
  List<MealEntry> build() {
    final day = ref.watch(selectedDayProvider);
    return StorageService.loadEntries(day);
  }

  Future<void> add(MealEntry entry) async {
    final next = [...state, entry];
    state = next;
    await StorageService.saveEntries(entry.consumedAt, next);
  }

  Future<void> addFromFood(FoodItem food, double grams, MealType type) async {
    final now = DateTime.now();
    final entry = MealEntry.fromFood(food, grams, type);
    state = [...state, entry];
    await StorageService.saveEntries(now, state);
    _logAdded(entry);
  }

  Future<void> remove(MealEntry entry) async {
    final next = state.where((e) => e.id != entry.id).toList();
    state = next;
    await StorageService.saveEntries(entry.consumedAt, next);
  }

  Future<void> clearAll() async {
    final day = ref.read(selectedDayProvider);
    state = const [];
    await StorageService.saveEntries(day, const []);
  }
}

@visibleForTesting
void _logAdded(MealEntry e) {
  // intentionally a no-op in release — kept for debug builds
}

/// Daily water intake in milliliters, persisted per day.
final waterIntakeProvider =
    NotifierProvider<WaterIntakeNotifier, int>(WaterIntakeNotifier.new);

class WaterIntakeNotifier extends Notifier<int> {
  @override
  int build() {
    final day = ref.watch(selectedDayProvider);
    return StorageService.loadWater(day);
  }

  Future<void> add(int ml) async {
    final nxt = (state + ml).clamp(0, 6000);
    state = nxt;
    await StorageService.saveWater(ref.read(selectedDayProvider), nxt);
  }

  Future<void> set(int ml) async {
    final nxt = ml.clamp(0, 6000);
    state = nxt;
    await StorageService.saveWater(ref.read(selectedDayProvider), nxt);
  }

  Future<void> reset() => set(0);
}

/// Aggregated macro totals for the selected day. Derives from
/// [dailyEntriesProvider] so consumers don't each compute independently.
final dailyTotalsProvider = NotifierProvider<DailyTotalsNotifier, DailyTotals>(
  DailyTotalsNotifier.new,
);

class DailyTotalsNotifier extends Notifier<DailyTotals> {
  @override
  DailyTotals build() {
    final entries = ref.watch(dailyEntriesProvider);
    var kcal = 0.0, p = 0.0, c = 0.0, f = 0.0, fib = 0.0;
    for (final e in entries) {
      kcal += e.calories;
      p    += e.protein;
      c    += e.carbs;
      f    += e.fat;
      fib  += e.fiber;
    }
    return DailyTotals(
      calories: kcal,
      protein:  p,
      carbs:    c,
      fat:      f,
      fiber:    fib,
      water:    ref.watch(waterIntakeProvider).toDouble(),
    );
  }
}

class DailyTotals {
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;
  final double water;
  const DailyTotals({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
    required this.water,
  });

  static const zero = DailyTotals(
    calories: 0, protein: 0, carbs: 0, fat: 0, fiber: 0, water: 0,
  );
}

/// Entries grouped by MealType — used by the dashboard section list.
final entriesByMealTypeProvider = Provider<Map<MealType, List<MealEntry>>>((ref) {
  final entries = ref.watch(dailyEntriesProvider);
  final map = <MealType, List<MealEntry>>{
    MealType.breakfast: [],
    MealType.lunch:     [],
    MealType.dinner:    [],
    MealType.snack:     [],
  };
  for (final e in entries) {
    map[e.mealType]!.add(e);
  }
  return map;
});
