import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/food_item.dart';
import '../../core/models/meal_entry.dart';
import '../../core/models/meal_plan.dart';
import '../../core/providers/daily_log_provider.dart';
import '../../core/providers/meal_planner_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/neon_button.dart';

class MealPlannerView extends ConsumerStatefulWidget {
  const MealPlannerView({super.key});

  @override
  ConsumerState<MealPlannerView> createState() => _MealPlannerViewState();
}

class _MealPlannerViewState extends ConsumerState<MealPlannerView> {
  int _selectedDayIndex = 0;
  bool _generating = false;

  @override
  void initState() {
    super.initState();
    // If no plan is loaded yet, kick off generation in microtask.
    Future.microtask(() async {
      if (ref.read(weeklyPlanProvider) == null) {
        await _generate();
      }
    });
  }

  Future<void> _generate() async {
    if (_generating) return;
    setState(() => _generating = true);
    HapticFeedback.lightImpact();
    await ref.read(weeklyPlanProvider.notifier).generate();
    if (!mounted) return;
    setState(() => _generating = false);
  }

  @override
  Widget build(BuildContext context) {
    final plan = ref.watch(weeklyPlanProvider);
    return Container(
      color: AppColors.background,
      child: SafeArea(
        child: Column(
          children: [
            _header(),
            if (plan == null) _placeholder(_generating)
            else ...[
              _weekStrip(plan),
              Expanded(child: _dayList(plan, _selectedDayIndex)),
            ],
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: NeonButton(
                label: _generating ? 'Generating…' : 'Generate new plan',
                icon: CupertinoIcons.sparkles,
                fullWidth: true,
                loading: _generating,
                onPressed: _generating ? null : _generate,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: AppColors.macroSweep,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(CupertinoIcons.calendar, color: Color(0xFFFFFFFF), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Meal Planner', style: AppText.h2),
                Text(
                  'Generated for your target macros',
                  style: AppText.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _weekStrip(WeekPlan plan) {
    return SizedBox(
      height: 92,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        scrollDirection: Axis.horizontal,
        itemCount: plan.days.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final d = plan.days[i];
          final isSel = i == _selectedDayIndex;
          final isToday = _isSameDay(d.date, DateTime.now());
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _selectedDayIndex = i);
            },
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 70,
              decoration: BoxDecoration(
                gradient: isSel ? AppColors.neonSweep : null,
                color: isSel ? null : AppColors.glassOverlaySoft,
                border: Border.all(
                  color: isToday && !isSel ? AppColors.neonLime.withValues(alpha: 0.5) : AppColors.borderSubtle,
                  width: isToday ? 1.2 : 1,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    d.day.toUpperCase(),
                    style: AppText.overline.copyWith(
                      color: isSel ? AppColors.textOnAccent : AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${d.date.day}',
                    style: AppText.h1.copyWith(
                      color: isSel ? AppColors.textOnAccent : Color(0xFFFFFFFF),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${d.totalCalories.round()} kcal',
                    style: AppText.caption.copyWith(
                      color: isSel
                          ? AppColors.textOnAccent.withValues(alpha: 0.7)
                          : AppColors.textTertiary,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _dayList(WeekPlan plan, int i) {
    final day = plan.days[i];
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      children: [
        Row(
          children: [
            Text(_prettyDayLabel(day.date), style: AppText.h3),
            const Spacer(),
            Row(
              children: [
                _Pill(label: '${day.totalCalories.round()} kcal', color: AppColors.macroCalories),
                const SizedBox(width: 6),
                _Pill(label: 'P ${day.totalProtein.round()}g', color: AppColors.macroProtein),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...day.meals.map((m) => _MealCard(meal: m, onAdd: () => _addToLog(m))),
      ],
    );
  }

  Future<void> _addToLog(PlannedMeal m) async {
    HapticFeedback.mediumImpact();
    // Build a MealEntry from the planned meal's totals. We pin
    // `gramsConsumed` to 1 g so the per-100g math in macrosFor() yields a
    // tiny contribution and our explicit pre-computed totals remain the
    // source of truth — this matches how AI-scan entries behave.
    final entry = MealEntry.create(
      id: null,
      name: m.name,
      brand: 'Planned',
      gramsConsumed: 350, // a typical dinner portion; macros for display

      calories: m.calories,
      protein: m.protein,
      carbs: m.carbs,
      fat: m.fat,
      fiber: m.fiber,
      mealType: _toMealType(m.mealSlot),
      consumedAt: DateTime.now(),
      source: FoodSource.planner,
    );
    await ref.read(dailyEntriesProvider.notifier).add(entry);
    if (!mounted) return;
    _toast('${m.emoji} ${m.name} added to log');
  }

  void _toast(String msg) {
    HapticFeedback.selectionClick();
    showCupertinoDialog<void>(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('Added to log'),
        content: Text(msg),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _placeholder(bool loading) {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CupertinoActivityIndicator(color: AppColors.neonLime, radius: 18),
            const SizedBox(height: 12),
            Text(
              loading ? 'Generating plan…' : 'No plan yet',
              style: AppText.h3,
            ),
            const SizedBox(height: 6),
            Text(
              loading
                  ? 'Tuning meals to your macro targets.'
                  : 'Tap "Generate new plan" to start.',
              style: AppText.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

MealType _toMealType(String slot) {
  switch (slot) {
    case 'breakfast': return MealType.breakfast;
    case 'lunch':     return MealType.lunch;
    case 'dinner':    return MealType.dinner;
    case 'snack':     return MealType.snack;
    default:          return MealType.snack;
  }
}

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String _prettyDayLabel(DateTime d) {
  if (_isSameDay(d, DateTime.now())) return 'Today';
  final delta = d.difference(DateTime.now()).inDays;
  if (delta == 1) return 'Tomorrow';
  if (delta == -1) return 'Yesterday';
  return Formatters.relativeDate(d);
}

class _Pill extends StatelessWidget {
  final String label;
  final Color color;
  const _Pill({required this.label, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: AppText.caption.copyWith(
          color: color,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MealCard extends StatelessWidget {
  final PlannedMeal meal;
  final VoidCallback onAdd;
  const _MealCard({required this.meal, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        onTap: onAdd,
        padding: const EdgeInsets.fromLTRB(14, 14, 16, 14),
        radius: 22,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 60, height: 60,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: AppColors.macroSweep,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(meal.emoji, style: const TextStyle(fontSize: 30)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meal.mealSlot.toUpperCase(),
                    style: AppText.overline,
                  ),
                  const SizedBox(height: 4),
                  Text(meal.name, style: AppText.h4),
                  const SizedBox(height: 4),
                  Text(
                    meal.description,
                    style: AppText.bodySmall.copyWith(color: AppColors.textSecondary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _macroChip('kcal', meal.calories.round(), AppColors.macroCalories),
                      _macroChip('P', meal.protein.round(), AppColors.macroProtein),
                      _macroChip('C', meal.carbs.round(), AppColors.macroCarbs),
                      _macroChip('F', meal.fat.round(), AppColors.macroFat),
                      _macroChip('🌾 ${meal.fiber.round()}', 0, AppColors.macroFiber),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _macroChip(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label ${value == 0 ? "" : value}',
        style: AppText.caption.copyWith(
          color: color,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}


