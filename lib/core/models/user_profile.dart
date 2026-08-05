/// Sex used for BMR calculation.
enum Gender {
  male,
  female,
  other;

  static Gender fromName(String? n) =>
      Gender.values.firstWhere((e) => e.name == n, orElse: () => Gender.other);
}

/// Activity multiplier (Mifflin-St Jeor uses these standard coefficients).
enum ActivityLevel {
  sedentary,    // little / no exercise
  light,        // 1-3 days/wk
  moderate,     // 3-5 days/wk
  active,       // 6-7 days/wk
  athlete;      // physical job + 2x training

  double get multiplier {
    switch (this) {
      case ActivityLevel.sedentary: return 1.2;
      case ActivityLevel.light:     return 1.375;
      case ActivityLevel.moderate:  return 1.55;
      case ActivityLevel.active:    return 1.725;
      case ActivityLevel.athlete:   return 1.9;
    }
  }

  String get label {
    switch (this) {
      case ActivityLevel.sedentary: return 'Sedentary';
      case ActivityLevel.light:     return 'Lightly active';
      case ActivityLevel.moderate:  return 'Moderately active';
      case ActivityLevel.active:    return 'Very active';
      case ActivityLevel.athlete:   return 'Athlete';
    }
  }

  String get description {
    switch (this) {
      case ActivityLevel.sedentary: return 'Desk job, little exercise';
      case ActivityLevel.light:     return 'Light walks, 1-3 days/wk';
      case ActivityLevel.moderate:  return 'Moderate training 3-5 days/wk';
      case ActivityLevel.active:    return 'Intense training 6-7 days/wk';
      case ActivityLevel.athlete:   return 'Physical job + 2x daily training';
    }
  }

  static ActivityLevel fromName(String? n) =>
      ActivityLevel.values.firstWhere((e) => e.name == n, orElse: () => ActivityLevel.moderate);
}

/// Dietary preference for AI meal planning.
enum DietaryPreference {
  balanced,
  highProtein,
  keto,
  vegan,
  vegetarian,
  lowCarb,
  mediterranean;

  String get label {
    switch (this) {
      case DietaryPreference.balanced:      return 'Balanced';
      case DietaryPreference.highProtein:   return 'High Protein';
      case DietaryPreference.keto:          return 'Keto';
      case DietaryPreference.vegan:         return 'Vegan';
      case DietaryPreference.vegetarian:    return 'Vegetarian';
      case DietaryPreference.lowCarb:       return 'Low Carb';
      case DietaryPreference.mediterranean: return 'Mediterranean';
    }
  }

  String get emoji {
    switch (this) {
      case DietaryPreference.balanced:      return '🥗';
      case DietaryPreference.highProtein:   return '💪';
      case DietaryPreference.keto:          return '🥑';
      case DietaryPreference.vegan:         return '🌱';
      case DietaryPreference.vegetarian:    return '🥦';
      case DietaryPreference.lowCarb:       return '🥩';
      case DietaryPreference.mediterranean: return '🫒';
    }
  }

  static DietaryPreference fromName(String? n) =>
      DietaryPreference.values.firstWhere((e) => e.name == n, orElse: () => DietaryPreference.balanced);
}

class UserProfile {
  String name;
  int age;
  Gender gender;
  double heightCm;
  double currentWeightKg;
  double targetWeightKg;
  ActivityLevel activity;
  DietaryPreference preference;
  double weeklyDeficitKg;
  DateTime createdAt;

  UserProfile({
    required this.name,
    required this.age,
    required this.gender,
    required this.heightCm,
    required this.currentWeightKg,
    required this.targetWeightKg,
    required this.activity,
    required this.preference,
    this.weeklyDeficitKg = 0.45,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'name': name,
        'age': age,
        'gender': gender.name,
        'heightCm': heightCm,
        'currentWeightKg': currentWeightKg,
        'targetWeightKg': targetWeightKg,
        'activity': activity.name,
        'preference': preference.name,
        'weeklyDeficitKg': weeklyDeficitKg,
        'createdAt': createdAt.toIso8601String(),
      };

  factory UserProfile.fromJson(Map<String, dynamic> j) => UserProfile(
        name: (j['name'] ?? '') as String,
        age: ((j['age'] ?? 25) as num).toInt(),
        gender: Gender.fromName(j['gender'] as String?),
        heightCm: ((j['heightCm'] ?? 170) as num).toDouble(),
        currentWeightKg: ((j['currentWeightKg'] ?? 75) as num).toDouble(),
        targetWeightKg: ((j['targetWeightKg'] ?? 70) as num).toDouble(),
        activity: ActivityLevel.fromName(j['activity'] as String?),
        preference: DietaryPreference.fromName(j['preference'] as String?),
        weeklyDeficitKg: ((j['weeklyDeficitKg'] ?? 0.45) as num).toDouble(),
        createdAt: DateTime.tryParse((j['createdAt'] ?? '') as String) ?? DateTime.now(),
      );

  /// Whether the user already finished onboarding.
  bool get isOnboarded => name.isNotEmpty && targetWeightKg > 0;

  UserProfile copyWith({
    String? name,
    int? age,
    Gender? gender,
    double? heightCm,
    double? currentWeightKg,
    double? targetWeightKg,
    ActivityLevel? activity,
    DietaryPreference? preference,
    double? weeklyDeficitKg,
  }) => UserProfile(
        name: name ?? this.name,
        age: age ?? this.age,
        gender: gender ?? this.gender,
        heightCm: heightCm ?? this.heightCm,
        currentWeightKg: currentWeightKg ?? this.currentWeightKg,
        targetWeightKg: targetWeightKg ?? this.targetWeightKg,
        activity: activity ?? this.activity,
        preference: preference ?? this.preference,
        weeklyDeficitKg: weeklyDeficitKg ?? this.weeklyDeficitKg,
        createdAt: createdAt,
      );
}
