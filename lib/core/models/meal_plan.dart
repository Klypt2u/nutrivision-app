/// A single planned meal in a [DayPlan].
class PlannedMeal {
  final String id;
  final String name;
  final String description;
  final String mealSlot; // 'breakfast' | 'lunch' | 'dinner' | 'snack'
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;
  final List<String> ingredients;
  final String emoji;
  final int prepMinutes;

  const PlannedMeal({
    required this.id,
    required this.name,
    required this.description,
    required this.mealSlot,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
    required this.ingredients,
    required this.emoji,
    this.prepMinutes = 20,
  });

  factory PlannedMeal.fromJson(Map<String, dynamic> j) => PlannedMeal(
        id: (j['id'] ?? DateTime.now().microsecondsSinceEpoch.toString()).toString(),
        name: j['name'] as String,
        description: j['description'] as String,
        mealSlot: j['meal_slot'] as String,
        calories: (j['calories'] as num).toDouble(),
        protein: (j['protein'] as num).toDouble(),
        carbs: (j['carbs'] as num).toDouble(),
        fat: (j['fat'] as num).toDouble(),
        fiber: ((j['fiber'] as num?) ?? 0).toDouble(),
        ingredients: ((j['ingredients'] as List?) ?? const [])
            .map((e) => e.toString())
            .toList(),
        emoji: (j['emoji'] ?? '🍴') as String,
        prepMinutes: ((j['prep_minutes'] as num?) ?? 20).toInt(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'meal_slot': mealSlot,
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
        'fiber': fiber,
        'ingredients': ingredients,
        'emoji': emoji,
        'prep_minutes': prepMinutes,
      };
}

class DayPlan {
  final String day; // 'Mon', 'Tue', ...
  final DateTime date;
  final List<PlannedMeal> meals;

  const DayPlan({required this.day, required this.date, required this.meals});

  double get totalCalories => meals.fold(0.0, (s, m) => s + m.calories);
  double get totalProtein  => meals.fold(0.0, (s, m) => s + m.protein);
  double get totalCarbs    => meals.fold(0.0, (s, m) => s + m.carbs);
  double get totalFat      => meals.fold(0.0, (s, m) => s + m.fat);

  factory DayPlan.fromJson(Map<String, dynamic> j) => DayPlan(
        day: j['day'] as String,
        date: DateTime.tryParse((j['date'] ?? '') as String) ?? DateTime.now(),
        meals: ((j['meals'] as List?) ?? const [])
            .map((m) => PlannedMeal.fromJson(m as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'day': day,
        'date': date.toIso8601String(),
        'meals': meals.map((m) => m.toJson()).toList(),
      };
}

class WeekPlan {
  final DateTime weekStart;
  final List<DayPlan> days;
  final String goalSummary;
  final double dailyCalorieTarget;

  const WeekPlan({
    required this.weekStart,
    required this.days,
    required this.goalSummary,
    required this.dailyCalorieTarget,
  });

  factory WeekPlan.fromJson(Map<String, dynamic> j) => WeekPlan(
        weekStart: DateTime.tryParse((j['weekStart'] ?? '') as String) ?? DateTime.now(),
        days: ((j['days'] as List?) ?? const [])
            .map((d) => DayPlan.fromJson(d as Map<String, dynamic>))
            .toList(),
        goalSummary: (j['goalSummary'] ?? '') as String,
        dailyCalorieTarget: ((j['dailyCalorieTarget'] as num?) ?? 2000).toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'weekStart': weekStart.toIso8601String(),
        'days': days.map((d) => d.toJson()).toList(),
        'goalSummary': goalSummary,
        'dailyCalorieTarget': dailyCalorieTarget,
      };
}
