import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/food_item.dart';
import '../../core/models/meal_entry.dart';
import '../../core/providers/daily_log_provider.dart';
import '../../core/providers/food_search_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/food_option_tile.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/neon_button.dart';

/// Global food search modal — DragHandleOfSheet style.
///
/// Tapping a result opens a portion-adjust bottom sheet where the user picks
/// grams via a [CupertinoSlider], then logs the entry to today's plan.
Future<void> showFoodSearchModal(BuildContext context) async {
  await showCupertinoModalPopup<void>(
    context: context,
    barrierDismissible: true,
    barrierColor: Color(0xDD000000),
    builder: (_) => const FoodSearchSheet(),
  );
}

class FoodSearchSheet extends ConsumerStatefulWidget {
  const FoodSearchSheet({super.key});

  @override
  ConsumerState<FoodSearchSheet> createState() => _FoodSearchSheetState();
}

class _FoodSearchSheetState extends ConsumerState<FoodSearchSheet> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initial query is empty → popular suggestions.
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets;
    final mediaH = MediaQuery.of(context).size.height;
    final results = ref.watch(foodSearchProvider);

    return Container(
      height: mediaH * 0.86,
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: AppColors.textTertiary.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                Text('Search NutriVision', style: AppText.h2),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 36, height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.glassDark,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      CupertinoIcons.xmark,
                      color: AppColors.textPrimary,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: _SearchField(
              controller: _controller,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                ref.read(searchQueryProvider.notifier).state = v;
              },
            ),
          ),
          Expanded(
            child: results.isEmpty
                ? _EmptyState(query: _controller.text)
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: results.length,
                    itemBuilder: (context, i) {
                      final food = results[i];
                      return FoodOptionTile(
                        food: food,
                        onTap: () => _openPortionSheet(context, food),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _openPortionSheet(BuildContext context, FoodItem food) {
    Navigator.of(context).pop(); // close search sheet
    showCupertinoModalPopup<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Color(0xDD000000),
      builder: (_) => PortionLogSheet(food: food),
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  const _SearchField({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      radius: 16,
      child: Row(
        children: [
          const Icon(
            CupertinoIcons.search,
            color: AppColors.textTertiary,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: CupertinoTextField(
              controller: controller,
              onChanged: onChanged,
              placeholder: 'Search foods, brands, barcodes…',
              placeholderStyle: AppText.body.copyWith(
                color: AppColors.textTertiary,
                fontSize: 15,
              ),
              style: AppText.body.copyWith(color: AppColors.textPrimary, fontSize: 15),
              decoration: const BoxDecoration(),
              cursorColor: AppColors.neonLime,
              autofocus: true,
            ),
          ),
          if (controller.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                controller.clear();
                onChanged('');
              },
              child: const Icon(
                CupertinoIcons.clear_circled_solid,
                color: AppColors.textTertiary,
                size: 18,
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String query;
  const _EmptyState({required this.query});
  @override
  Widget build(BuildContext context) {
    final hasQuery = query.trim().isNotEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80, height: 80,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: AppColors.macroSweep,
              borderRadius: BorderRadius.circular(28),
              boxShadow: GlassDecoration.glowShadow,
            ),
            child: const Icon(
              CupertinoIcons.search,
              color: AppColors.background,
              size: 36,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            hasQuery ? 'No foods match' : 'Search globally',
            style: AppText.h3,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            hasQuery
                ? 'Try a different keyword or scan a barcode.'
                : 'Find any food, brand, or barcode. We\'ll pull\ncalories and macros in milliseconds.',
            style: AppText.bodySmall.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet that adjusts portion (in grams) via a CupertinoSlider and
/// pushes the entry into today's log.
class PortionLogSheet extends ConsumerStatefulWidget {
  final FoodItem food;
  const PortionLogSheet({super.key, required this.food});

  @override
  ConsumerState<PortionLogSheet> createState() => _PortionLogSheetState();
}

class _PortionLogSheetState extends ConsumerState<PortionLogSheet> {
  late double _grams;
  late MealType _type;

  @override
  void initState() {
    super.initState();
    _grams = widget.food.servingSize;
    _type = MealType.forHour(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    final macros = widget.food.macrosFor(_grams);
    final mediaH = MediaQuery.of(context).size.height;

    return Container(
      height: mediaH * 0.58,
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.textTertiary.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GlassCard(
                padding: const EdgeInsets.all(16),
                radius: 20,
                child: Row(
                  children: [
                    Container(
                      width: 60, height: 60,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: AppColors.macroSweep,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Text(
                        widget.food.emoji,
                        style: const TextStyle(fontSize: 30),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.food.name,
                              style: AppText.h3,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                          if ((widget.food.brand ?? '').isNotEmpty)
                            Text(widget.food.brand!, style: AppText.bodySmall),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _PortionStepper(
                grams: _grams,
                onChanged: (v) => setState(() => _grams = v),
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _MacroStat(label: 'Calories', value: macros.kcal, color: AppColors.macroCalories),
                  _MacroStat(label: 'Protein',  value: macros.protein, color: AppColors.macroProtein, unit: 'g'),
                  _MacroStat(label: 'Carbs',    value: macros.carbs,   color: AppColors.macroCarbs,   unit: 'g'),
                  _MacroStat(label: 'Fat',      value: macros.fat,     color: AppColors.macroFat,     unit: 'g'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _MealTypePicker(
                selected: _type,
                onChanged: (t) => setState(() => _type = t),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: NeonButton(
                label: 'Add to log',
                icon: CupertinoIcons.add,
                fullWidth: true,
                onPressed: () async {
                  HapticFeedback.mediumImpact();
                  await ref.read(dailyEntriesProvider.notifier)
                      .addFromFood(widget.food, _grams, _type);
                  if (mounted) Navigator.of(context).pop();
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _PortionStepper extends StatelessWidget {
  final double grams;
  final ValueChanged<double> onChanged;
  const _PortionStepper({required this.grams, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      radius: 20,
      child: Column(
        children: [
          Row(
            children: [
              Text('Portion', style: AppText.label),
              const Spacer(),
              Text(
                '${grams.round()} g',
                style: AppText.metricSmall.copyWith(color: AppColors.neonLime),
              ),
            ],
          ),
          CupertinoSlider(
            value: grams.clamp(20, 800).toDouble(),
            min: 20,
            max: 800,
            activeColor: AppColors.neonLime,
            thumbColor: Color(0xFFFFFFFF),
            onChanged: (v) {
              HapticFeedback.selectionClick();
              onChanged(v);
            },
          ),
          Row(
            children: [
              Text('Light', style: AppText.caption),
              const Spacer(),
              Text('Heavy', style: AppText.caption),
            ],
          ),
        ],
      ),
    );
  }
}

class _MacroStat extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final String unit;
  const _MacroStat({
    required this.label,
    required this.value,
    required this.color,
    this.unit = 'kcal',
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.glassOverlaySoft,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Column(
          children: [
            Text(
              unit == 'kcal' ? value.round().toString() : value.toStringAsFixed(0),
              style: AppText.metricSmall.copyWith(color: color),
            ),
            const SizedBox(height: 2),
            Text(
              '${label}${unit != 'kcal' ? ' ($unit)' : ''}',
              style: AppText.caption.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _MealTypePicker extends StatelessWidget {
  final MealType selected;
  final ValueChanged<MealType> onChanged;
  const _MealTypePicker({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final items = MealType.values;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.glassDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        children: items.map((t) {
          final isSel = t == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                onChanged(t);
              },
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.symmetric(horizontal: 2),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  gradient: isSel ? AppColors.neonSweep : null,
                  color: isSel ? null : Color(0x00000000),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Column(
                  children: [
                    Text(t.emoji, style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 2),
                    Text(
                      t.label,
                      style: AppText.caption.copyWith(
                        color: isSel ? AppColors.textOnAccent : AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}


