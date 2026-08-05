import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../models/food_item.dart';
import '../models/meal_entry.dart';
import '../models/meal_plan.dart';
import '../models/user_profile.dart';

/// Centralized Hive-backed JSON storage.
///
/// Each logical namespace has its own Box. We store plain JSON Strings so we
/// avoid `build_runner` code generation — the app boots and runs immediately.
class StorageService {
  StorageService._();

  static const _boxUser       = 'nv_user_v1';
  static const _boxEntries    = 'nv_entries_v1';
  static const _boxTargets    = 'nv_targets_v1';
  static const _boxWater      = 'nv_water_v1';
  static const _boxCustomFood = 'nv_custom_food_v1';
  static const _boxWeekPlan   = 'nv_week_plan_v1';
  static const _boxWeightLog  = 'nv_weightlog_v1';

  static late Box<String> _user;
  static late Box<String> _entries;
  static late Box<String> _targets;
  static late Box<String> _water;
  static late Box<String> _customFood;
  static late Box<String> _weekPlan;
  static late Box<String> _weightLog;

  /// One-time setup, called from main().
  static Future<void> init() async {
    await Hive.initFlutter('nutrivision_ai');
    _user       = await Hive.openBox<String>(_boxUser);
    _entries    = await Hive.openBox<String>(_boxEntries);
    _targets    = await Hive.openBox<String>(_boxTargets);
    _water      = await Hive.openBox<String>(_boxWater);
    _customFood = await Hive.openBox<String>(_boxCustomFood);
    _weekPlan   = await Hive.openBox<String>(_boxWeekPlan);
    _weightLog  = await Hive.openBox<String>(_boxWeightLog);
  }

  // -------------------- Keys --------------------
  static const _kUser = 'profile';
  static const _kTargets = 'targets';
  static const _kPlan = 'plan';

  static String _dayKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  // -------------------- USER --------------------
  static Future<void> saveUser(UserProfile u) async {
    await _user.put(_kUser, jsonEncode(u.toJson()));
  }

  static UserProfile? loadUser() {
    final s = _user.get(_kUser);
    if (s == null) return null;
    try {
      return UserProfile.fromJson(jsonDecode(s) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  // -------------------- TARGETS --------------------
  static Future<void> saveTargets(Map<String, dynamic> json) async {
    await _targets.put(_kTargets, jsonEncode(json));
  }

  static Map<String, dynamic>? loadTargets() {
    final s = _targets.get(_kTargets);
    if (s == null) return null;
    try {
      return jsonDecode(s) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  // -------------------- ENTRIES --------------------
  /// Entries are keyed by date: 'YYYY-MM-DD' → array of [MealEntry].
  static Future<void> saveEntries(DateTime day, List<MealEntry> entries) async {
    final data = {'items': entries.map((e) => e.toJson()).toList()};
    await _entries.put(_dayKey(day), jsonEncode(data));
  }

  static List<MealEntry> loadEntries(DateTime day) {
    final s = _entries.get(_dayKey(day));
    if (s == null) return const [];
    try {
      final json = jsonDecode(s) as Map<String, dynamic>;
      final items = (json['items'] as List?) ?? const [];
      return items.map((e) => MealEntry.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return const [];
    }
  }

  static Future<void> deleteEntry(MealEntry entry) async {
    final list = List<MealEntry>.from(loadEntries(entry.consumedAt));
    list.removeWhere((e) => e.id == entry.id);
    await saveEntries(entry.consumedAt, list);
  }

  // -------------------- WATER --------------------
  static Future<void> saveWater(DateTime day, int ml) async {
    await _water.put(_dayKey(day), ml.toString());
  }

  static int loadWater(DateTime day) {
    final s = _water.get(_dayKey(day));
    if (s == null) return 0;
    return int.tryParse(s) ?? 0;
  }

  // -------------------- CUSTOM FOODS --------------------
  static Future<void> saveCustomFood(FoodItem food) async {
    await _customFood.put(food.id, jsonEncode(food.toMap()));
  }

  static FoodItem? loadCustomFood(String id) {
    final s = _customFood.get(id);
    if (s == null) return null;
    try {
      return FoodItem.fromMap(
        jsonDecode(s) as Map<String, dynamic>,
        source: FoodSource.userCreated,
        idOverride: id,
      );
    } catch (_) {
      return null;
    }
  }

  static List<FoodItem> loadAllCustomFoods() {
    final out = <FoodItem>[];
    for (final k in _customFood.keys) {
      final s = _customFood.get(k);
      if (s == null) continue;
      try {
        out.add(
          FoodItem.fromMap(
            jsonDecode(s) as Map<String, dynamic>,
            source: FoodSource.userCreated,
            idOverride: k.toString(),
          ),
        );
      } catch (_) {
        // silently skip corrupt entries
      }
    }
    return out;
  }

  // -------------------- WEEK PLAN --------------------
  static Future<void> saveWeekPlan(WeekPlan plan) async {
    await _weekPlan.put(_kPlan, jsonEncode(plan.toJson()));
  }

  static WeekPlan? loadWeekPlan() {
    final s = _weekPlan.get(_kPlan);
    if (s == null) return null;
    try {
      return WeekPlan.fromJson(jsonDecode(s) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  // -------------------- WEIGHT LOG --------------------
  static Future<void> saveWeight(DateTime day, double kg) async {
    await _weightLog.put(_dayKey(day), kg.toString());
  }

  static Map<DateTime, double> loadAllWeights() {
    final out = <DateTime, double>{};
    for (final k in _weightLog.keys) {
      final v = _weightLog.get(k);
      final dt = DateTime.tryParse(k.toString());
      final w = double.tryParse(v ?? '');
      if (dt != null && w != null) out[dt] = w;
    }
    return out;
  }
}
