/// Computed daily macro targets derived from a [UserProfile].
class MacroTargets {
  final double calories;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final double fiberG;
  final double waterMl;

  const MacroTargets({
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.fiberG,
    required this.waterMl,
  });

  factory MacroTargets.fromJson(Map<String, dynamic> json) => MacroTargets(
        calories: (json['calories'] as num).toDouble(),
        proteinG: (json['protein_g'] as num).toDouble(),
        carbsG: (json['carbs_g'] as num).toDouble(),
        fatG: (json['fat_g'] as num).toDouble(),
        fiberG: (json['fiber_g'] as num).toDouble(),
        waterMl: (json['water_ml'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'calories': calories,
        'protein_g': proteinG,
        'carbs_g': carbsG,
        'fat_g': fatG,
        'fiber_g': fiberG,
        'water_ml': waterMl,
      };

  static const placeholder = MacroTargets(
    calories: 2000,
    proteinG: 150,
    carbsG: 220,
    fatG: 65,
    fiberG: 28,
    waterMl: 2500,
  );
}
