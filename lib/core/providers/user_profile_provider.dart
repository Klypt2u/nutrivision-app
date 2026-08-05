import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/macro_targets.dart';
import '../models/user_profile.dart';
import '../services/storage_service.dart';
import '../utils/macro_calculator.dart';

/// The user's profile. `null` until onboarding completes.
final userProfileProvider =
    NotifierProvider<UserProfileNotifier, UserProfile?>(UserProfileNotifier.new);

class UserProfileNotifier extends Notifier<UserProfile?> {
  @override
  UserProfile? build() {
    return StorageService.loadUser();
  }

  Future<void> completeOnboarding(UserProfile p) async {
    state = p;
    await StorageService.saveUser(p);
    final targets = MacroCalculator.build(profile: p);
    ref.read(macroTargetsProvider.notifier).set(targets);
  }

  Future<void> update(UserProfile p) async {
    state = p;
    await StorageService.saveUser(p);
    final t = MacroCalculator.build(profile: p);
    ref.read(macroTargetsProvider.notifier).set(t);
  }

  Future<void> clear() async {
    state = null;
    await StorageService.saveUser(UserProfile(
      name: '',
      age: 25,
      gender: Gender.other,
      heightCm: 170,
      currentWeightKg: 70,
      targetWeightKg: 70,
      activity: ActivityLevel.moderate,
      preference: DietaryPreference.balanced,
    ));
  }
}

/// Daily macro targets. Recomputed when the user profile changes.
final macroTargetsProvider =
    NotifierProvider<MacroTargetsNotifier, MacroTargets>(MacroTargetsNotifier.new);

class MacroTargetsNotifier extends Notifier<MacroTargets> {
  @override
  MacroTargets build() {
    final stored = StorageService.loadTargets();
    if (stored != null) {
      try {
        return MacroTargets.fromJson(stored);
      } catch (_) {}
    }
    return MacroTargets.placeholder;
  }

  Future<void> set(MacroTargets t) async {
    state = t;
    await StorageService.saveTargets(t.toJson());
  }
}

/// Whether onboarding has been completed.
final isOnboardedProvider = Provider<bool>((ref) {
  final p = ref.watch(userProfileProvider);
  return p?.isOnboarded ?? false;
});
