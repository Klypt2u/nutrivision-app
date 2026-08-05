import '../models/macro_targets.dart';
import '../models/user_profile.dart';

/// Pure functions for BMR/TDEE/macro-split math.
///
/// Uses the **Mifflin-St Jeor** equation (more accurate than Harris-Benedict
/// for modern populations). Macro ratios per dietary preference are tuned for
/// satiety, blood-sugar control, and adherence.
class MacroCalculator {
  MacroCalculator._();

  /// Mifflin-St Jeor BMR (kcal/day).
  static double bmr({
    required double weightKg,
    required double heightCm,
    required int age,
    required Gender gender,
  }) {
    final base = 10.0 * weightKg + 6.25 * heightCm - 5.0 * age;
    switch (gender) {
      case Gender.male:   return base + 5;
      case Gender.female: return base - 161;
      case Gender.other:  return base - 78; // midpoint
    }
  }

  /// Total daily energy expenditure (BMR × activity multiplier).
  static double tdee({
    required double weightKg,
    required double heightCm,
    required int age,
    required Gender gender,
    required ActivityLevel activity,
  }) {
    return bmr(weightKg: weightKg, heightCm: heightCm, age: age, gender: gender) *
        activity.multiplier;
  }

  /// Translate weekly kg-loss goal → daily kcal deficit.
  /// 1 kg of fat ≈ 7700 kcal ⇒ weeklyDeficit = 7700 × kg.
  static double deficitForGoal(double weeklyKgLoss) => weeklyKgLoss * 7700 / 7;

  /// Build a [MacroTargets] given a user profile.
  static MacroTargets build({
    required UserProfile profile,
  }) {
    final tdeeValue = tdee(
      weightKg: profile.currentWeightKg,
      heightCm: profile.heightCm,
      age: profile.age,
      gender: profile.gender,
      activity: profile.activity,
    );

    final dailyDeficit = deficitForGoal(profile.weeklyDeficitKg);
    final calories = (tdeeValue - dailyDeficit).clamp(1200.0, 4000.0);

    // Macro splits (protein %, carbs %, fat %).
    final split = _splitFor(profile.preference);

    // Macro distribution in grams (protein/carbs 4 kcal/g, fat 9 kcal/g).
    final proteinG = (calories * split.$1 / 4.0);
    final carbsG   = (calories * split.$2 / 4.0);
    final fatG     = (calories * split.$3 / 9.0);

    // Fiber guideline: 14 g per 1000 kcal (rounded) — clamped.
    final fiberG = (calories / 1000.0 * 14.0).clamp(20.0, 50.0);

    // Water: 35 ml / kg body weight + 500 ml activity bonus (≥ athlete).
    final activityBonus = profile.activity == ActivityLevel.athlete ? 500.0 : 0.0;
    final waterMl = (profile.currentWeightKg * 35.0 + activityBonus).clamp(1500.0, 4500.0);

    return MacroTargets(
      calories: calories,
      proteinG: proteinG,
      carbsG: carbsG,
      fatG: fatG,
      fiberG: fiberG,
      waterMl: waterMl,
    );
  }

  /// (protein %, carbs %, fat %) for each dietary preference.
  static (double, double, double) _splitFor(DietaryPreference pref) {
    switch (pref) {
      case DietaryPreference.balanced:      return (0.30, 0.45, 0.25);
      case DietaryPreference.highProtein:   return (0.40, 0.35, 0.25);
      case DietaryPreference.keto:          return (0.25, 0.05, 0.70);
      case DietaryPreference.vegan:         return (0.20, 0.55, 0.25);
      case DietaryPreference.vegetarian:    return (0.25, 0.50, 0.25);
      case DietaryPreference.lowCarb:       return (0.35, 0.20, 0.45);
      case DietaryPreference.mediterranean: return (0.22, 0.48, 0.30);
    }
  }
}
