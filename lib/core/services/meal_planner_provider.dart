import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/meal_plan.dart';
import '../services/meal_planner_service.dart';
import '../services/storage_service.dart';
import 'user_profile_provider.dart';

/// Service provider — singleton MealPlannerService.
final mealPlannerServiceProvider = Provider<MealPlannerService>((_) => MealPlannerService());

/// The cached weekly plan. Auto-loaded on app start; regenerated on profile
/// change or explicit user action.
final weeklyPlanProvider =
    NotifierProvider<WeeklyPlanNotifier, WeekPlan?>(WeeklyPlanNotifier.new);

class WeeklyPlanNotifier extends Notifier<WeekPlan?> {
  @override
  WeekPlan? build() {
    return StorageService.loadWeekPlan();
  }

  /// Generate (or regenerate) the weekly plan given the current profile.
  Future<void> generate() async {
    final profile = ref.read(userProfileProvider);
    if (profile == null) return;
    final targets = ref.read(macroTargetsProvider);
    final plan = ref.read(mealPlannerServiceProvider).generate(
          profile: profile,
          targets: targets,
        );
    state = plan;
    await StorageService.saveWeekPlan(plan);
  }

  Future<void> clear() async {
    state = null;
  }
}
