import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/macro_targets.dart';
import '../../core/models/user_profile.dart';
import '../../core/providers/user_profile_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/macro_calculator.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/neon_button.dart';

/// Multi-step Cupertino page-style onboarding questionnaire.
class OnboardingFlow extends ConsumerStatefulWidget {
  const OnboardingFlow({super.key});

  @override
  ConsumerState<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends ConsumerState<OnboardingFlow> {
  final _nameCtrl = TextEditingController();
  int _age = 28;
  Gender _gender = Gender.other;
  double _height = 172;
  double _currentWeight = 78;
  double _targetWeight = 70;
  ActivityLevel _activity = ActivityLevel.moderate;
  DietaryPreference _preference = DietaryPreference.balanced;
  int _step = 0;

  late final _pageCtrl = PageController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _pageCtrl.dispose();
    super.dispose();
  }

  void _next() {
    HapticFeedback.lightImpact();
    if (_step < 6) {
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 360),
        curve: Curves.easeOutCubic,
      );
      setState(() => _step++);
    } else {
      _finish();
    }
  }

  void _back() {
    HapticFeedback.lightImpact();
    if (_step > 0) {
      _pageCtrl.previousPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
      setState(() => _step--);
    }
  }

  Future<void> _finish() async {
    final profile = UserProfile(
      name: _nameCtrl.text.trim().isEmpty ? 'Friend' : _nameCtrl.text.trim(),
      age: _age,
      gender: _gender,
      heightCm: _height,
      currentWeightKg: _currentWeight,
      targetWeightKg: _targetWeight,
      activity: _activity,
      preference: _preference,
    );
    await ref.read(userProfileProvider.notifier).completeOnboarding(profile);
  }

  @override
  Widget build(BuildContext context) {
    return LocalScaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Progress bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: [
                  _BackButton(onTap: _step == 0 ? null : _back),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Stack(
                        children: [
                          Container(height: 6, color: AppColors.glassDark),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 360),
                            curve: Curves.easeOutCubic,
                            height: 6,
                            width: MediaQuery.of(context).size.width *
                                ((_step + 1) / 7),
                            decoration: const BoxDecoration(
                              gradient: AppColors.neonSweep,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${_step + 1}/7',
                    style: AppText.label,
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageCtrl,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _StepName(controller: _nameCtrl),
                  _StepAge(
                    age: _age,
                    onChanged: (v) => setState(() => _age = v),
                  ),
                  _StepGender(
                    gender: _gender,
                    onChanged: (g) => setState(() => _gender = g),
                  ),
                  _StepBody(
                    height: _height,
                    current: _currentWeight,
                    target: _targetWeight,
                    onHeight: (v) => setState(() => _height = v),
                    onCurrent: (v) => setState(() => _currentWeight = v),
                    onTarget: (v) => setState(() => _targetWeight = v),
                  ),
                  _StepActivity(
                    activity: _activity,
                    onChanged: (a) => setState(() => _activity = a),
                  ),
                  _StepPreference(
                    preference: _preference,
                    onChanged: (p) => setState(() => _preference = p),
                  ),
                  _StepReveal(
                    name: _nameCtrl.text.trim().isEmpty ? 'Friend' : _nameCtrl.text.trim(),
                    profile: UserProfile(
                      name: _nameCtrl.text.trim().isEmpty ? 'Friend' : _nameCtrl.text.trim(),
                      age: _age,
                      gender: _gender,
                      heightCm: _height,
                      currentWeightKg: _currentWeight,
                      targetWeightKg: _targetWeight,
                      activity: _activity,
                      preference: _preference,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Row(
                children: [
                  if (_step == 6)
                    Expanded(child: NeonButton(label: 'Generate plan', icon: CupertinoIcons.sparkles, onPressed: _finish, fullWidth: true))
                  else
                    Expanded(
                      child: NeonButton(
                        label: 'Continue',
                        icon: CupertinoIcons.arrow_right,
                        onPressed: _next,
                        fullWidth: true,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget LocalScaffold({required Color backgroundColor, required Widget body}) {
    return Container(
      color: backgroundColor,
      child: body,
    );
  }
}

class _BackButton extends StatelessWidget {
  final VoidCallback? onTap;
  const _BackButton({required this.onTap});
  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 36, height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.glassDark,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          CupertinoIcons.chevron_back,
          color: enabled ? AppColors.textPrimary : AppColors.textTertiary,
          size: 18,
        ),
      ),
    );
  }
}

// ---------------------- STEPS ----------------------

class _StepName extends StatelessWidget {
  final TextEditingController controller;
  const _StepName({required this.controller});
  @override
  Widget build(BuildContext context) {
    return _StepShell(
      title: 'Hey there',
      subtitle: 'What should we call you?',
      illustration: '👋',
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        radius: 16,
        child: CupertinoTextField(
          controller: controller,
          placeholder: 'Your name',
          placeholderStyle: AppText.body.copyWith(color: AppColors.textTertiary),
          style: AppText.h2.copyWith(color: AppColors.textPrimary),
          decoration: const BoxDecoration(),
          cursorColor: AppColors.neonLime,
          onChanged: (_) {},
        ),
      ),
    );
  }
}

class _StepAge extends StatelessWidget {
  final int age;
  final ValueChanged<int> onChanged;
  const _StepAge({required this.age, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    return _StepShell(
      title: 'How old are you?',
      subtitle: 'Age helps us dial in your metabolism.',
      illustration: '🎂',
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        radius: 22,
        child: Row(
          children: [
            Text('$age', style: AppText.metric.copyWith(color: AppColors.neonLime)),
            const SizedBox(width: 8),
            Text('years', style: AppText.body),
            const Spacer(),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () {
                HapticFeedback.selectionClick();
                onChanged((age - 1).clamp(14, 100));
              },
              child: const Icon(CupertinoIcons.minus_circle_fill, color: AppColors.textSecondary, size: 32),
            ),
            const SizedBox(width: 8),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () {
                HapticFeedback.selectionClick();
                onChanged((age + 1).clamp(14, 100));
              },
              child: const Icon(CupertinoIcons.plus_circle_fill, color: AppColors.neonLime, size: 32),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepGender extends StatelessWidget {
  final Gender gender;
  final ValueChanged<Gender> onChanged;
  const _StepGender({required this.gender, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    return _StepShell(
      title: 'How do you identify?',
      subtitle: 'Used only for energy calculations.',
      illustration: '⚧️',
      child: Column(
        children: Gender.values.map((g) {
          final selected = g == gender;
          final label = switch (g) {
            Gender.female => 'Female',
            Gender.male   => 'Male',
            Gender.other  => 'Prefer not to say',
          };
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                onChanged(g);
              },
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                decoration: BoxDecoration(
                  gradient: selected ? AppColors.neonSweep : null,
                  color: selected ? null : AppColors.glassOverlaySoft,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: selected ? Color(0x00000000) : AppColors.borderSubtle,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      selected ? CupertinoIcons.check_mark_circled_solid : CupertinoIcons.circle,
                      color: selected ? AppColors.textOnAccent : AppColors.textSecondary,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Text(label, style: AppText.h4.copyWith(
                      color: selected ? AppColors.textOnAccent : AppColors.textPrimary,
                    )),
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

class _StepBody extends StatelessWidget {
  final double height;
  final double current;
  final double target;
  final ValueChanged<double> onHeight;
  final ValueChanged<double> onCurrent;
  final ValueChanged<double> onTarget;
  const _StepBody({
    required this.height,
    required this.current,
    required this.target,
    required this.onHeight,
    required this.onCurrent,
    required this.onTarget,
  });
  @override
  Widget build(BuildContext context) {
    return _StepShell(
      title: 'Your stats',
      subtitle: 'Set realistic starting & target weights.',
      illustration: '⚖️',
      child: Column(
        children: [
          _StatTile(label: 'Height', value: height, unit: 'cm', min: 130, max: 220, step: 1, onChanged: onHeight, color: AppColors.macroProtein),
          const SizedBox(height: 12),
          _StatTile(label: 'Current weight', value: current, unit: 'kg', min: 35, max: 200, step: 0.5, onChanged: onCurrent, color: AppColors.macroCalories),
          const SizedBox(height: 12),
          _StatTile(label: 'Target weight', value: target, unit: 'kg', min: 35, max: 200, step: 0.5, onChanged: onTarget, color: AppColors.neonCyan),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final double value;
  final String unit;
  final double min, max, step;
  final ValueChanged<double> onChanged;
  final Color color;
  const _StatTile({
    required this.label,
    required this.value,
    required this.unit,
    required this.min,
    required this.max,
    required this.step,
    required this.onChanged,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final ticks = ((max - min) / step).round();
    return GlassCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      radius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label, style: AppText.label),
              const Spacer(),
              Text(
                '${value.toStringAsFixed(unit == 'cm' ? 0 : 1)} $unit',
                style: AppText.metricSmall.copyWith(color: color),
              ),
            ],
          ),
          CupertinoSlider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: ticks,
            activeColor: color,
            thumbColor: Color(0xFFFFFFFF),
            onChanged: (v) {
              HapticFeedback.selectionClick();
              onChanged(v);
            },
          ),
        ],
      ),
    );
  }
}

class _StepActivity extends StatelessWidget {
  final ActivityLevel activity;
  final ValueChanged<ActivityLevel> onChanged;
  const _StepActivity({required this.activity, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    return _StepShell(
      title: 'How active are you?',
      subtitle: 'Pick the option that matches your week.',
      illustration: '🏃',
      child: Column(
        children: ActivityLevel.values.map((a) {
          final selected = a == activity;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                onChanged(a);
              },
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: selected ? AppColors.glassOverlay : AppColors.glassOverlaySoft,
                  border: Border.all(
                    color: selected ? AppColors.neonLime.withValues(alpha: 0.6) : AppColors.borderSubtle,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(
                      selected ? CupertinoIcons.check_mark_circled_solid : CupertinoIcons.circle,
                      color: selected ? AppColors.neonLime : AppColors.textSecondary,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(a.label, style: AppText.h4),
                          const SizedBox(height: 2),
                          Text(a.description, style: AppText.caption),
                        ],
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

class _StepPreference extends StatelessWidget {
  final DietaryPreference preference;
  final ValueChanged<DietaryPreference> onChanged;
  const _StepPreference({required this.preference, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    return _StepShell(
      title: 'What\'s your style?',
      subtitle: 'We\'ll generate a plan that fits.',
      illustration: '🥗',
      child: Column(
        children: DietaryPreference.values.map((p) {
          final selected = p == preference;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                onChanged(p);
              },
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: selected ? AppColors.glassOverlay : AppColors.glassOverlaySoft,
                  border: Border.all(
                    color: selected ? AppColors.neonLime.withValues(alpha: 0.6) : AppColors.borderSubtle,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Text(p.emoji, style: const TextStyle(fontSize: 22)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(p.label, style: AppText.h4),
                    ),
                    Icon(
                      selected ? CupertinoIcons.check_mark_circled_solid : CupertinoIcons.circle,
                      color: selected ? AppColors.neonLime : AppColors.textSecondary,
                      size: 22,
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

class _StepReveal extends StatelessWidget {
  final String name;
  final UserProfile profile;
  const _StepReveal({required this.name, required this.profile});
  @override
  Widget build(BuildContext context) {
    final MacroTargets t = MacroCalculator.build(profile: profile);
    final deficit = (MacroCalculator.tdee(
      weightKg: profile.currentWeightKg,
      heightCm: profile.heightCm,
      age: profile.age,
      gender: profile.gender,
      activity: profile.activity,
    ) - t.calories).round();

    return _StepShell(
      title: 'You\'re all set, $name',
      subtitle: 'Here\'s your personalized plan.',
      illustration: '✨',
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: Column(
        children: [
          GlassCard(
            padding: const EdgeInsets.all(20),
            radius: 24,
            gradient: AppColors.macroSweep,
            child: Column(
              children: [
                Text('Daily Calories', style: AppText.label.copyWith(color: Color(0xFFFFFFFF).withValues(alpha: 0.7))),
                const SizedBox(height: 6),
                Text(
                  '${t.calories.round()}',
                  style: AppText.display.copyWith(color: Color(0xFFFFFFFF)),
                ),
                const SizedBox(height: 8),
                Text(
                  '−$deficit kcal deficit/day',
                  style: AppText.body.copyWith(color: Color(0xFFFFFFFF).withValues(alpha: 0.85)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _MacroReveal(label: 'Protein',  value: t.proteinG, color: AppColors.macroProtein,  emoji: '💪')),
              const SizedBox(width: 10),
              Expanded(child: _MacroReveal(label: 'Carbs',    value: t.carbsG,   color: AppColors.macroCarbs,    emoji: '🌾')),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _MacroReveal(label: 'Fat',      value: t.fatG,     color: AppColors.macroFat,      emoji: '🥑')),
              const SizedBox(width: 10),
              Expanded(child: _MacroReveal(label: 'Fiber',    value: t.fiberG,   color: AppColors.macroFiber,    emoji: '🌿')),
            ],
          ),
        ],
      ),
    );
  }
}

class _MacroReveal extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final String emoji;
  const _MacroReveal({required this.label, required this.value, required this.color, required this.emoji});
  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      radius: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 6),
              Text(label, style: AppText.label),
            ],
          ),
          const SizedBox(height: 6),
          Text('${value.round()} g', style: AppText.metricSmall.copyWith(color: color)),
        ],
      ),
    );
  }
}

class _StepShell extends StatelessWidget {
  final String title;
  final String subtitle;
  final String illustration;
  final Widget child;
  final EdgeInsets padding;
  const _StepShell({
    required this.title,
    required this.subtitle,
    required this.illustration,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(24, 20, 24, 24),
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 76,
              height: 76,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: AppColors.macroSweep,
                borderRadius: BorderRadius.circular(26),
                boxShadow: GlassDecoration.glowShadow,
              ),
              child: Text(illustration, style: const TextStyle(fontSize: 36)),
            ),
          ),
          const SizedBox(height: 18),
          Text(title, style: AppText.h1),
          const SizedBox(height: 4),
          Text(subtitle, style: AppText.bodySmall.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 22),
          child,
        ],
      ),
    );
  }
}
// (No further top-level helpers required.)
