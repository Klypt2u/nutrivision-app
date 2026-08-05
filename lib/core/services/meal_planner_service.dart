import 'dart:math';

import '../models/macro_targets.dart';
import '../models/meal_plan.dart';
import '../models/user_profile.dart';

/// Generates a one-week meal plan that fits a user's [MacroTargets] and
/// [DietaryPreference]. The generator is **deterministic + offline** so the
/// planner produces a complete plan instantly without network access.
class MealPlannerService {
  MealPlannerService();

  WeekPlan generate({required UserProfile profile, required MacroTargets targets, DateTime? from}) {
    final weekStart = _weekStart(from ?? DateTime.now());
    final days = List.generate(
      7,
      (i) => _generateDay(
        profile: profile,
        targets: targets,
        date: weekStart.add(Duration(days: i)),
      ),
    );
    return WeekPlan(
      weekStart: weekStart,
      days: days,
      goalSummary: _goalSummary(profile, targets),
      dailyCalorieTarget: targets.calories,
    );
  }

  DayPlan _generateDay({
    required UserProfile profile,
    required MacroTargets targets,
    required DateTime date,
  }) {
    // Per-slot calorie split: 25 / 35 / 30 / 10.
    final breakfastKcal = targets.calories * 0.25;
    final lunchKcal     = targets.calories * 0.35;
    final dinnerKcal    = targets.calories * 0.30;
    final snackKcal     = targets.calories * 0.10;

    final meals = <PlannedMeal>[
      _pickMeal(profile.preference, 'breakfast', breakfastKcal, seed: date.day + 1),
      _pickMeal(profile.preference, 'lunch',     lunchKcal,     seed: date.day + 5),
      _pickMeal(profile.preference, 'dinner',    dinnerKcal,    seed: date.day + 9),
      _pickMeal(profile.preference, 'snack',     snackKcal,     seed: date.day + 13),
    ];

    return DayPlan(day: _dayShort(date.weekday), date: date, meals: meals);
  }

  PlannedMeal _pickMeal(DietaryPreference pref, String slot, double kcal, {required int seed}) {
    final pool = _poolFor(pref, slot);
    final rng = Random(seed * 31 + slot.hashCode);
    final template = pool[rng.nextInt(pool.length)];
    return PlannedMeal.fromJson({
      ...template,
      'meal_slot': slot,
      'calories': kcal,
      'protein':  kcal * template['protein_share'] as double,
      'carbs':    kcal * template['carb_share']    as double,
      'fat':      kcal * template['fat_share']     as double,
      'fiber':    kcal * 0.04,
      'id': '${pref.name}_${slot}_$seed',
    });
  }

  String _goalSummary(UserProfile p, MacroTargets t) =>
      'Lose ${(p.targetWeightKg - p.currentWeightKg).abs().toStringAsFixed(0)} kg '
      '· ${p.preference.label} · ${t.calories.toStringAsFixed(0)} kcal/day';

  String _dayShort(int weekday) {
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return labels[(weekday - 1).clamp(0, 6)];
  }

  DateTime _weekStart(DateTime d) {
    final monday = d.subtract(Duration(days: d.weekday - 1));
    return DateTime(monday.year, monday.month, monday.day);
  }

  // -------------------------------------------------------------------------
  // Pool lookup (string-keyed for simple Dart 3 compatibility).
  // -------------------------------------------------------------------------
  List<Map<String, dynamic>> _poolFor(DietaryPreference pref, String slot) {
    final pool = _pools['${pref.name}:$slot'];
    if (pool != null) return pool;
    // Fallback to balanced.
    return _pools['balanced:$slot']!;
  }

  static final Map<String, List<Map<String, dynamic>>> _pools = _buildPools();

  static Map<String, List<Map<String, dynamic>>> _buildPools() {
    final m = <String, List<Map<String, dynamic>>>{};
    void addAll(DietaryPreference p, _MealPool pool) {
      m['${p.name}:breakfast'] = pool.breakfast;
      m['${p.name}:lunch']     = pool.lunch;
      m['${p.name}:dinner']    = pool.dinner;
      m['${p.name}:snack']     = pool.snack;
    }
    addAll(DietaryPreference.balanced,      _balanced);
    addAll(DietaryPreference.highProtein,   _hp);
    addAll(DietaryPreference.keto,          _keto);
    addAll(DietaryPreference.vegan,         _vegan);
    addAll(DietaryPreference.vegetarian,    _veg);
    addAll(DietaryPreference.lowCarb,       _lc);
    addAll(DietaryPreference.mediterranean, _med);
    return m;
  }

  // ---- POOL DEFINITIONS ----
  static final _MealPool _balanced = _MealPool(
    breakfast: [
      _t('Greek Yogurt Parfait',    'Layered with berries and honey.',        '🥣', ['Greek yogurt', 'Mixed berries', 'Honey', 'Granola'],      protein_share: 0.30, carb_share: 0.50, fat_share: 0.20),
      _t('Avocado Toast & Eggs',    'Whole-grain toast with smashed avocado and 2 eggs.', '🥑', ['Whole-grain bread', 'Avocado', 'Eggs'],                protein_share: 0.25, carb_share: 0.40, fat_share: 0.35),
      _t('Oatmeal with Banana',     'Steel-cut oats, banana slices, almond butter.',    '🥣', ['Oats', 'Banana', 'Almond butter'],                       protein_share: 0.20, carb_share: 0.55, fat_share: 0.25),
    ],
    lunch: [
      _t('Quinoa Power Bowl',       'Quinoa, grilled chicken, roasted veggies, tahini.',    '🥗', ['Quinoa', 'Chicken breast', 'Bell peppers', 'Tahini'], protein_share: 0.35, carb_share: 0.40, fat_share: 0.25),
      _t('Turkey Avocado Wrap',     'Whole-wheat wrap, turkey, avocado, spinach.',          '🌯', ['Whole-wheat tortilla', 'Turkey', 'Avocado', 'Spinach'], protein_share: 0.30, carb_share: 0.40, fat_share: 0.30),
      _t('Salmon Poke Bowl',        'Brown rice, raw salmon, edamame, sesame dressing.',    '🍣', ['Brown rice', 'Salmon', 'Edamame'],                       protein_share: 0.30, carb_share: 0.45, fat_share: 0.25),
    ],
    dinner: [
      _t('Sheet-Pan Salmon & Veggies','Salmon, asparagus, cherry tomatoes, olive oil.',    '🐟', ['Salmon', 'Asparagus', 'Cherry tomatoes'],                protein_share: 0.35, carb_share: 0.25, fat_share: 0.40),
      _t('Chicken Stir-Fry',           'Chicken, mixed veggies, ginger-soy sauce.',         '🍗', ['Chicken breast', 'Broccoli', 'Bell peppers'],            protein_share: 0.40, carb_share: 0.30, fat_share: 0.30),
      _t('Lean Beef Tacos',            'Ground beef, corn tortillas, salsa, lime.',         '🌮', ['Ground beef', 'Corn tortillas', 'Salsa'],                protein_share: 0.35, carb_share: 0.35, fat_share: 0.30),
    ],
    snack: [
      _t('Apple + Almond Butter',   'Crisp apple with a tablespoon of almond butter.',      '🍎', ['Apple', 'Almond butter'],                                protein_share: 0.15, carb_share: 0.55, fat_share: 0.30),
      _t('Cottage Cheese & Berries','Low-fat cottage cheese with strawberries.',           '🫐', ['Cottage cheese', 'Strawberries'],                        protein_share: 0.40, carb_share: 0.40, fat_share: 0.20),
    ],
  );

  static final _MealPool _hp = _MealPool(
    breakfast: [t_p1, t_p2],
    lunch:     [t_p3, t_p4],
    dinner:    [t_p5, t_p6],
    snack:     [t_p7, t_p8],
  );

  static final _MealPool _keto = _MealPool(
    breakfast: [t_k1, t_k2],
    lunch:     [t_k3, t_k4],
    dinner:    [t_k5, t_k6],
    snack:     [t_k7, t_k8],
  );

  static final _MealPool _vegan = _MealPool(
    breakfast: [t_v1, t_v2],
    lunch:     [t_v3, t_v4],
    dinner:    [t_v5, t_v6],
    snack:     [t_v7, t_v8],
  );

  static final _MealPool _veg = _MealPool(
    breakfast: [t_veg1, t_veg2],
    lunch:     [t_veg3, t_veg4],
    dinner:    [t_veg5, t_veg6],
    snack:     [t_veg7, t_veg8],
  );

  static final _MealPool _lc = _MealPool(
    breakfast: [t_lc1, t_lc2],
    lunch:     [t_lc3, t_lc4],
    dinner:    [t_lc5, t_lc6],
    snack:     [t_lc7, t_lc8],
  );

  static final _MealPool _med = _MealPool(
    breakfast: [t_med1, t_med2],
    lunch:     [t_med3, t_med4],
    dinner:    [t_med5, t_med6],
    snack:     [t_med7, t_med8],
  );

  // ---- Macro share aliases (kept terse; full readability above) ----
  static final t_p1  = _t('Protein Smoothie Bowl',    'Whey protein, banana, oats, peanut butter.',     '🥤', ['Whey protein', 'Banana', 'Oats', 'Peanut butter'],  protein_share: 0.50, carb_share: 0.30, fat_share: 0.20);
  static final t_p2  = _t('Egg & Turkey Scramble',    '3 eggs, turkey bacon, spinach.',                 '🍳', ['Eggs', 'Turkey bacon', 'Spinach'],                 protein_share: 0.55, carb_share: 0.10, fat_share: 0.35);
  static final t_p3  = _t('Grilled Chicken & Rice',   'Chicken breast, jasmine rice, broccoli.',       '🍗', ['Chicken', 'Rice', 'Broccoli'],                     protein_share: 0.45, carb_share: 0.35, fat_share: 0.20);
  static final t_p4  = _t('Tuna Quinoa Bowl',         'Tuna, quinoa, edamame, lemon.',                 '🥗', ['Tuna', 'Quinoa', 'Edamame'],                      protein_share: 0.45, carb_share: 0.35, fat_share: 0.20);
  static final t_p5  = _t('Steak & Sweet Potato',     'Lean steak, baked sweet potato, asparagus.',     '🥩', ['Steak', 'Sweet potato', 'Asparagus'],             protein_share: 0.45, carb_share: 0.30, fat_share: 0.25);
  static final t_p6  = _t('Cod & Lentil Pilaf',       'Baked cod, lentil pilaf, kale.',                '🐟', ['Cod', 'Lentils', 'Kale'],                         protein_share: 0.45, carb_share: 0.30, fat_share: 0.25);
  static final t_p7  = _t('Greek Yogurt + Whey',      'High-protein yogurt with extra whey.',          '🥛', ['Greek yogurt', 'Whey'],                           protein_share: 0.65, carb_share: 0.25, fat_share: 0.10);
  static final t_p8  = _t('Cottage Cheese + Almonds', 'Cottage cheese with a handful of almonds.',     '🧀', ['Cottage cheese', 'Almonds'],                      protein_share: 0.50, carb_share: 0.20, fat_share: 0.30);

  static final t_k1  = _t('Avocado & Bacon Plate',    'Avocado, bacon, 2 boiled eggs.',                '🥑', ['Avocado', 'Bacon', 'Eggs'],                       protein_share: 0.25, carb_share: 0.05, fat_share: 0.70);
  static final t_k2  = _t('Keto Cheesecake Bowl',     'Cream cheese, berries, walnuts.',               '🍰', ['Cream cheese', 'Berries', 'Walnuts'],             protein_share: 0.20, carb_share: 0.10, fat_share: 0.70);
  static final t_k3  = _t('Chicken Cobb Salad',       'Chicken, bacon, blue cheese, avocado, egg.',    '🥗', ['Chicken', 'Bacon', 'Blue cheese', 'Avocado'],      protein_share: 0.35, carb_share: 0.05, fat_share: 0.60);
  static final t_k4  = _t('Salmon Avocado Plate',     'Smoked salmon, avocado, capers.',               '🐟', ['Salmon', 'Avocado', 'Capers'],                    protein_share: 0.30, carb_share: 0.05, fat_share: 0.65);
  static final t_k5  = _t('Ribeye & Asparagus',       'Pan-seared ribeye with garlic asparagus.',      '🥩', ['Ribeye', 'Asparagus', 'Butter'],                  protein_share: 0.30, carb_share: 0.05, fat_share: 0.65);
  static final t_k6  = _t('Bunless Cheeseburger',     'Beef patty, cheese, mushrooms, no bun.',        '🍔', ['Ground beef', 'Cheddar', 'Mushrooms'],            protein_share: 0.30, carb_share: 0.05, fat_share: 0.65);
  static final t_k7  = _t('Cheese & Olives',          'Cheddar cubes with kalamata olives.',           '🧀', ['Cheddar', 'Olives'],                              protein_share: 0.20, carb_share: 0.05, fat_share: 0.75);
  static final t_k8  = _t('Macadamia Nuts',           'Handful of macadamia nuts.',                    '🥜', ['Macadamia nuts'],                                 protein_share: 0.05, carb_share: 0.05, fat_share: 0.90);

  static final t_v1  = _t('Chia Pudding',             'Chia seeds, almond milk, berries, maple.',      '🥣', ['Chia seeds', 'Almond milk', 'Berries'],           protein_share: 0.20, carb_share: 0.55, fat_share: 0.25);
  static final t_v2  = _t('Tofu Scramble',            'Tofu scramble with peppers and spinach.',       '🍳', ['Tofu', 'Bell pepper', 'Spinach'],                 protein_share: 0.30, carb_share: 0.25, fat_share: 0.45);
  static final t_v3  = _t('Buddha Bowl',              'Quinoa, chickpeas, roasted veggies, hummus.',   '🥗', ['Quinoa', 'Chickpeas', 'Squash', 'Hummus'],        protein_share: 0.25, carb_share: 0.55, fat_share: 0.20);
  static final t_v4  = _t('Lentil Curry & Rice',      'Red lentil curry, brown rice, cilantro.',       '🍛', ['Lentils', 'Brown rice', 'Cilantro'],             protein_share: 0.25, carb_share: 0.60, fat_share: 0.15);
  static final t_v5  = _t('Stuffed Portobello',       'Quinoa-stuffed portobello mushrooms.',          '🍄', ['Portobello', 'Quinoa', 'Spinach'],                protein_share: 0.25, carb_share: 0.55, fat_share: 0.20);
  static final t_v6  = _t('Black Bean Chili',         'Black bean chili with avocado.',                '🌶', ['Black beans', 'Tomato', 'Avocado'],               protein_share: 0.25, carb_share: 0.55, fat_share: 0.20);
  static final t_v7  = _t('Edamame & Sea Salt',       'Steamed edamame with sea salt.',                '🟢', ['Edamame'],                                        protein_share: 0.35, carb_share: 0.40, fat_share: 0.25);
  static final t_v8  = _t('Apple & Almond Butter',    'Apple slices with almond butter.',              '🍎', ['Apple', 'Almond butter'],                         protein_share: 0.15, carb_share: 0.55, fat_share: 0.30);

  static final t_veg1= _t('Veggie Omelet',            '3-egg omelet with mushrooms, peppers, cheese.', '🍳', ['Eggs', 'Mushrooms', 'Bell pepper'],               protein_share: 0.35, carb_share: 0.20, fat_share: 0.45);
  static final t_veg2= _t('Yogurt & Granola Bowl',    'Greek yogurt, granola, blueberries.',           '🥣', ['Greek yogurt', 'Granola', 'Blueberries'],         protein_share: 0.30, carb_share: 0.50, fat_share: 0.20);
  static final t_veg3= _t('Caprese Pasta',            'Whole-wheat pasta, mozzarella, tomato, basil.', '🍝', ['Whole-wheat pasta', 'Mozzarella', 'Tomato'],      protein_share: 0.20, carb_share: 0.55, fat_share: 0.25);
  static final t_veg4= _t('Paneer Tikka Bowl',        'Grilled paneer, brown rice, raita.',            '🍚', ['Paneer', 'Brown rice', 'Yogurt'],                 protein_share: 0.25, carb_share: 0.45, fat_share: 0.30);
  static final t_veg5= _t('Mushroom Risotto',         'Creamy arborio rice with mixed mushrooms.',     '🍄', ['Arborio rice', 'Mushrooms', 'Parmesan'],          protein_share: 0.20, carb_share: 0.55, fat_share: 0.25);
  static final t_veg6= _t('Eggplant Parmesan',        'Baked eggplant parm with marinara.',            '🍆', ['Eggplant', 'Marinara', 'Mozzarella'],             protein_share: 0.20, carb_share: 0.45, fat_share: 0.35);
  static final t_veg7= _t('Cottage Cheese with Peach','Cottage cheese with sliced peach.',             '🍑', ['Cottage cheese', 'Peach'],                        protein_share: 0.40, carb_share: 0.40, fat_share: 0.20);
  static final t_veg8= _t('Trail Mix',                'Mixed nuts, dried fruit, dark chocolate.',      '🥜', ['Mixed nuts', 'Dried fruit', 'Dark chocolate'],    protein_share: 0.10, carb_share: 0.40, fat_share: 0.50);

  static final t_lc1 = _t('Veggie & Feta Skillet',    'Zucchini, feta, eggs.',                         '🍳', ['Zucchini', 'Feta', 'Eggs'],                       protein_share: 0.35, carb_share: 0.15, fat_share: 0.50);
  static final t_lc2 = _t('Smoked Salmon Plate',      'Smoked salmon, cream cheese, cucumber.',        '🐟', ['Smoked salmon', 'Cream cheese', 'Cucumber'],      protein_share: 0.40, carb_share: 0.10, fat_share: 0.50);
  static final t_lc3 = _t('Burrito Bowl (no rice)',   'Chicken, beans, cheese, salsa, avocado.',       '🥗', ['Chicken', 'Beans', 'Cheese', 'Avocado'],          protein_share: 0.40, carb_share: 0.20, fat_share: 0.40);
  static final t_lc4 = _t('Tuna Salad Plate',         'Tuna salad over greens, olive oil dressing.',    '🐟', ['Tuna', 'Mixed greens'],                           protein_share: 0.45, carb_share: 0.15, fat_share: 0.40);
  static final t_lc5 = _t('Pork Tenderloin & Greens', 'Roasted pork tenderloin, sautéed greens.',      '🥩', ['Pork tenderloin', 'Spinach'],                     protein_share: 0.40, carb_share: 0.15, fat_share: 0.45);
  static final t_lc6 = _t('Chicken Thigh & Asparagus','Pan-roasted chicken thigh with asparagus.',     '🍗', ['Chicken thigh', 'Asparagus'],                     protein_share: 0.40, carb_share: 0.10, fat_share: 0.50);
  static final t_lc7 = _t('Cheese & Walnuts',         'Cheddar with a few walnuts.',                   '🧀', ['Cheddar', 'Walnuts'],                             protein_share: 0.25, carb_share: 0.05, fat_share: 0.70);
  static final t_lc8 = _t('Beef Jerky',               'A small portion of beef jerky.',                '🥩', ['Beef jerky'],                                     protein_share: 0.65, carb_share: 0.10, fat_share: 0.25);

  static final t_med1= _t('Greek Yogurt with Honey',  'Greek yogurt, walnuts, a drizzle of honey.',    '🥣', ['Greek yogurt', 'Walnuts', 'Honey'],               protein_share: 0.30, carb_share: 0.45, fat_share: 0.25);
  static final t_med2= _t('Mediterranean Egg Plate',  'Soft-boiled eggs, olives, tomatoes, feta.',     '🍳', ['Eggs', 'Olives', 'Tomato', 'Feta'],               protein_share: 0.30, carb_share: 0.20, fat_share: 0.50);
  static final t_med3= _t('Greek Salad with Chicken', 'Romaine, chicken, feta, olives, olive oil.',    '🥗', ['Romaine', 'Chicken', 'Feta', 'Olives'],           protein_share: 0.30, carb_share: 0.20, fat_share: 0.50);
  static final t_med4= _t('Falafel Pita',             'Falafel, hummus, veggies in whole-wheat pita.', '🥙', ['Falafel', 'Hummus', 'Whole-wheat pita'],          protein_share: 0.20, carb_share: 0.50, fat_share: 0.30);
  static final t_med5= _t('Baked Cod with Tomatoes',  'Cod, tomato, olives, capers, olive oil.',       '🐟', ['Cod', 'Tomato', 'Olives'],                        protein_share: 0.40, carb_share: 0.20, fat_share: 0.40);
  static final t_med6= _t('Lemon Chicken with Quinoa','Lemon-herb chicken with quinoa tabbouleh.',     '🍋', ['Chicken', 'Quinoa', 'Parsley'],                   protein_share: 0.35, carb_share: 0.40, fat_share: 0.25);
  static final t_med7= _t('Hummus & Veggies',         'Hummus with carrot and cucumber sticks.',       '🥕', ['Hummus', 'Carrot', 'Cucumber'],                   protein_share: 0.20, carb_share: 0.40, fat_share: 0.40);
  static final t_med8= _t('Mixed Olives',             'Marinated mixed olives.',                      '🫒', ['Mixed olives'],                                   protein_share: 0.05, carb_share: 0.10, fat_share: 0.85);

  static Map<String, dynamic> _t(
    String name,
    String description,
    String emoji,
    List<String> ings, {
    required double protein_share,
    required double carb_share,
    required double fat_share,
  }) =>
      {
        'name': name,
        'description': description,
        'emoji': emoji,
        'ingredients': ings,
        'protein_share': protein_share,
        'carb_share': carb_share,
        'fat_share': fat_share,
        'prep_minutes': 20,
        'fiber': 0,
      };
}

class _MealPool {
  final List<Map<String, dynamic>> breakfast;
  final List<Map<String, dynamic>> lunch;
  final List<Map<String, dynamic>> dinner;
  final List<Map<String, dynamic>> snack;
  const _MealPool({
    required this.breakfast,
    required this.lunch,
    required this.dinner,
    required this.snack,
  });
}
