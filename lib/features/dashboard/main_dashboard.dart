import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/macro_targets.dart';
import '../../core/models/meal_entry.dart';
import '../../core/providers/daily_log_provider.dart';
import '../../core/providers/user_profile_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../shared/widgets/app_background.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/macro_ring.dart';
import '../../shared/widgets/meal_entry_row.dart';
import '../../shared/widgets/section_header.dart';
import '../../shared/widgets/water_intake_bar.dart';
import '../scanner/ai_scanner_view.dart';
import '../search/food_search_modal.dart';

/// The home tab surface: greeting, hero calories ring, macro rings, water,
/// search, and meal groups for the selected day.
class MainDashboard extends ConsumerWidget {
  const MainDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);
    final targets = ref.watch(macroTargetsProvider);
    final totals = ref.watch(dailyTotalsProvider);
    final entriesByType = ref.watch(entriesByMealTypeProvider);
    final water = ref.watch(waterIntakeProvider);
    final selectedDay = ref.watch(selectedDayProvider);

    return AppBackground(
      child: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _Header(name: profile?.name ?? 'Friend', day: selectedDay)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: _CaloriesHeroCard(
                    consumed: totals.calories,
                    target: targets.calories,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                  child: _MacroRingsRow(
                    consumed: totals,
                    target: targets,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                  child: GlassCard(
                    radius: 22,
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                    child: WaterIntakeBar(
                      currentMl: water,
                      goalMl: targets.waterMl.toInt(),
                      onAdd: (delta) async {
                        await ref.read(waterIntakeProvider.notifier).add(delta);
                      },
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 18, 20, 0),
                  child: _SearchBar(),
                ),
              ),
              const SliverToBoxAdapter(child: SectionHeader(title: "Today's Meals")),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final types = MealType.values;
                    final t = types[i];
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                      child: _MealGroupCard(
                        type: t,
                        entries: entriesByType[t]!,
                      ),
                    );
                  },
                  childCount: MealType.values.length,
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
          // Floating scanner button.
          Positioned(
            right: 18,
            bottom: 24,
            child: _ScanFab(
              onTap: () {
                HapticFeedback.mediumImpact();
                Navigator.of(context).push(
                  CupertinoPageRoute(
                    fullscreenDialog: true,
                    builder: (_) => const AiScannerView(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// HEADER
// ============================================================
class _Header extends StatelessWidget {
  final String name;
  final DateTime day;
  const _Header({required this.name, required this.day});

  @override
  Widget build(BuildContext context) {
    final greeting = _greetingFor(DateTime.now().hour);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 44, height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: AppColors.macroSweep,
              borderRadius: BorderRadius.circular(14),
              boxShadow: GlassDecoration.glowShadow,
            ),
            child: Text(
              _initials(name),
              style: AppText.h4.copyWith(color: Color(0xFFFFFFFF)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$greeting, $name',
                  style: AppText.h2,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  Formatters.relativeDate(day),
                  style: AppText.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {},
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 40, height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.glassDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: const Icon(
                CupertinoIcons.bell,
                color: AppColors.textSecondary,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _greetingFor(int hour) {
    if (hour < 5)  return 'Late night';
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    if (hour < 21) return 'Good evening';
    return 'Good night';
  }

  String _initials(String name) {
    if (name.isEmpty) return 'NV';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }
}

// ============================================================
// CALORIES HERO
// ============================================================
class _CaloriesHeroCard extends StatelessWidget {
  final double consumed;
  final double target;
  const _CaloriesHeroCard({required this.consumed, required this.target});

  @override
  Widget build(BuildContext context) {
    final remaining = (target - consumed).clamp(-99999.0, 99999.0);
    final progress = (consumed / target).clamp(0.0, 1.0);
    final isOver = consumed > target;

    return GlassCard(
      radius: 28,
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 22),
      glow: true,
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF1E1E24), Color(0xFF181820)],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 150, height: 150,
            child: Stack(
              alignment: Alignment.center,
              children: [
                MacroRing(
                  progress: progress,
                  size: 150,
                  strokeWidth: 14,
                  color: isOver ? AppColors.danger : AppColors.macroCalories,
                  centerText: remaining.abs().round().toString(),
                  centerLabel: isOver ? 'over goal' : 'remaining',
                  suffixText: 'kcal',
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('TARGET', style: AppText.overline),
                const SizedBox(height: 6),
                Text('${target.round()} kcal', style: AppText.metricSmall),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _legendDot(color: AppColors.macroCalories),
                    const SizedBox(width: 6),
                    Text('Consumed  ', style: AppText.caption),
                    Text('${consumed.round()}', style: AppText.body.copyWith(color: AppColors.macroCalories, fontWeight: FontWeight.w700, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _legendDot(color: AppColors.neonCyan),
                    const SizedBox(width: 6),
                    Text('Remaining ', style: AppText.caption),
                    Text(
                      isOver ? '0' : remaining.round().toString(),
                      style: AppText.body.copyWith(color: AppColors.neonCyan, fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color) => Container(
        width: 8, height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}

// ============================================================
// MACRO RINGS ROW
// ============================================================
class _MacroRingsRow extends StatelessWidget {
  final DailyTotals consumed;
  final MacroTargets target;
  const _MacroRingsRow({required this.consumed, required this.target});

  @override
  Widget build(BuildContext context) {
    final items = [
      _MacroRingItem('Protein', consumed.protein, target.proteinG, AppColors.macroProtein, '💪'),
      _MacroRingItem('Carbs',   consumed.carbs,   target.carbsG,   AppColors.macroCarbs,   '🌾'),
      _MacroRingItem('Fat',     consumed.fat,     target.fatG,     AppColors.macroFat,     '🥑'),
      _MacroRingItem('Fiber',   consumed.fiber,   target.fiberG,   AppColors.macroFiber,   '🌿'),
    ];
    return Row(
      children: items.map((it) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GlassCard(
              radius: 20,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
              child: Column(
                children: [
                  Text(it.emoji, style: const TextStyle(fontSize: 14)),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: 76, height: 76,
                    child: MacroRing(
                      progress: (it.consumed / it.target).clamp(0.0, 1.0),
                      size: 76,
                      strokeWidth: 8,
                      color: it.color,
                      centerText: it.consumed.round().toString(),
                      centerLabel: 'g',
                      suffixText: '/${it.target.round()}',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(it.label, style: AppText.label.copyWith(fontSize: 11, color: it.color)),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _MacroRingItem {
  final String label;
  final double consumed;
  final double target;
  final Color color;
  final String emoji;
  _MacroRingItem(this.label, this.consumed, this.target, this.color, this.emoji);
}

// ============================================================
// SEARCH BAR
// ============================================================
class _SearchBar extends StatelessWidget {
  const _SearchBar();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        showFoodSearchModal(context);
      },
      behavior: HitTestBehavior.opaque,
      child: GlassCard(
        radius: 18,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            const Icon(CupertinoIcons.search, color: AppColors.textTertiary, size: 18),
            const SizedBox(width: 10),
            Text('Search NutriVision', style: AppText.body.copyWith(color: AppColors.textTertiary, fontSize: 15)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.glassDark,
                borderRadius: BorderRadius.circular(7),
              ),
              child: Text('⌘ K', style: AppText.caption.copyWith(color: AppColors.textTertiary, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// MEAL GROUP CARD
// ============================================================
class _MealGroupCard extends ConsumerWidget {
  final MealType type;
  final List<MealEntry> entries;
  const _MealGroupCard({required this.type, required this.entries});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final total = entries.fold(0.0, (s, e) => s + e.calories);
    return GlassCard(
      radius: 22,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(type.emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Text(type.label, style: AppText.h4),
              const Spacer(),
              if (entries.isEmpty)
                Text('—', style: AppText.bodySmall.copyWith(color: AppColors.textTertiary))
              else
                Text('${total.round()} kcal', style: AppText.bodySmall.copyWith(color: AppColors.neonLime, fontWeight: FontWeight.w700)),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => showFoodSearchModal(context),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: 32, height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: AppColors.neonSweep,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(CupertinoIcons.plus, color: Color(0xFFFFFFFF), size: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (entries.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                children: [
                  const Icon(CupertinoIcons.add_circled, color: AppColors.textTertiary, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Tap + to log $type',
                    style: AppText.bodySmall.copyWith(color: AppColors.textTertiary),
                  ),
                ],
              ),
            )
          else
            ...entries.map(
              (e) => MealEntryRow(
                entry: e,
                onDelete: () => ref.read(dailyEntriesProvider.notifier).remove(e),
              ),
            ),
        ],
      ),
    );
  }
}

// ============================================================
// SCAN FAB
// ============================================================
class _ScanFab extends StatefulWidget {
  final VoidCallback onTap;
  const _ScanFab({required this.onTap});

  @override
  State<_ScanFab> createState() => _ScanFabState();
}

class _ScanFabState extends State<_ScanFab> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => HapticFeedback.lightImpact(),
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          return Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.neonSweep,
              boxShadow: [
                BoxShadow(
                  color: AppColors.neonLime.withValues(alpha: 0.45 + (_ctrl.value * 0.1)),
                  blurRadius: 28,
                  spreadRadius: 2,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Center(
              child: Icon(CupertinoIcons.camera_viewfinder, color: AppColors.textPrimary, size: 28),
            ),
          );
        },
      ),
    );
  }
}


