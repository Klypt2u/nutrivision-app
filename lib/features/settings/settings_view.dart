import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/user_profile.dart';
import '../../core/providers/user_profile_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/neon_button.dart';
import '../onboarding/onboarding_flow.dart';

class SettingsView extends ConsumerWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);
    final targets = ref.watch(macroTargetsProvider);
    return Container(
      color: AppColors.background,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          children: [
            Text('Settings', style: AppText.h1),
            const SizedBox(height: 16),
            if (profile != null) ...[
              GlassCard(
                padding: const EdgeInsets.all(16),
                radius: 22,
                child: Row(
                  children: [
                    Container(
                      width: 56, height: 56,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: AppColors.macroSweep,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child:                        Text(
                          profile.name.isEmpty
                              ? 'NV'
                              : profile.name.substring(0, 1).toUpperCase(),
                          style: AppText.h2.copyWith(color: AppColors.textPrimary),
                        ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(profile.name, style: AppText.h4),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              _stat(profile.currentWeightKg.toStringAsFixed(0), 'kg', 'Now'),
                              const SizedBox(width: 14),
                              _stat(profile.targetWeightKg.toStringAsFixed(0), 'kg', 'Goal'),
                              const SizedBox(width: 14),
                              _stat(profile.age.toString(), 'yo', 'Age'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              GlassCard(
                padding: const EdgeInsets.all(16),
                radius: 22,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Text('Daily targets', style: AppText.label),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.neonLime.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text('user-tuned', style: AppText.caption.copyWith(color: AppColors.neonLime, fontSize: 9, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10, runSpacing: 10,
                      children: [
                        _target('Calories', '${targets.calories.round()} kcal', AppColors.macroCalories),
                        _target('Protein',  '${targets.proteinG.round()} g',    AppColors.macroProtein),
                        _target('Carbs',    '${targets.carbsG.round()} g',      AppColors.macroCarbs),
                        _target('Fat',      '${targets.fatG.round()} g',        AppColors.macroFat),
                        _target('Fiber',    '${targets.fiberG.round()} g',      AppColors.macroFiber),
                        _target('Water',    Formatters.ml(targets.waterMl),     AppColors.macroWater),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              GlassCard(
                padding: EdgeInsets.zero,
                radius: 22,
                child: _SettingTile(
                  leadingEmoji: '🔁',
                  title: 'Edit profile',
                  subtitle: 'Re-run onboarding with updated stats',
                  onTap: () {
                    Navigator.of(context, rootNavigator: true).push(
                      CupertinoPageRoute(
                        fullscreenDialog: true,
                        builder: (_) => const OnboardingFlow(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              GlassCard(
                padding: EdgeInsets.zero,
                radius: 22,
                child: _SettingTile(
                  leadingEmoji: '♻️',
                  title: 'Reset app data',
                  subtitle: 'Wipe local profile, logs and plans',
                  onTap: () async {
                    HapticFeedback.heavyImpact();
                    final ok = await showCupertinoDialog<bool>(
                      context: context,
                      builder: (_) => CupertinoAlertDialog(
                        title: const Text('Reset app data?'),
                        content: const Text('This clears your profile, daily logs, and plans. Cannot be undone.'),
                        actions: [
                          CupertinoDialogAction(
                            child: const Text('Cancel'),
                            onPressed: () => Navigator.of(context).pop(false),
                          ),
                          CupertinoDialogAction(
                            isDestructiveAction: true,
                            child: const Text('Reset'),
                            onPressed: () => Navigator.of(context).pop(true),
                          ),
                        ],
                      ),
                    );
                    if (ok == true) {
                      await ref.read(userProfileProvider.notifier).clear();
                    }
                  },
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'NutriVision AI · v1.0.0',
                  style: AppText.caption.copyWith(color: AppColors.textTertiary),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _stat(String value, String unit, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [          Text(value, style: AppText.metricSmall.copyWith(color: AppColors.textPrimary, fontSize: 18)),
            const SizedBox(width: 2),
            Text(unit, style: AppText.caption),
          ],
        ),
        Text(label, style: AppText.caption.copyWith(color: AppColors.textTertiary)),
      ],
    );
  }

  Widget _target(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppText.caption.copyWith(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(value, style: AppText.body.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 14)),
        ],
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  final String leadingEmoji;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _SettingTile({
    required this.leadingEmoji,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      onPressed: onTap,
      child: Row(
        children: [
          Text(leadingEmoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.h4),
                const SizedBox(height: 2),
                Text(subtitle, style: AppText.caption.copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
          const Icon(CupertinoIcons.chevron_right, color: AppColors.textTertiary, size: 16),
        ],
      ),
    );
  }
}


