import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/providers/user_profile_provider.dart';
import 'core/services/local_food_database.dart';
import 'core/services/storage_service.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'features/dashboard/main_dashboard.dart';
import 'features/onboarding/onboarding_flow.dart';
import 'features/planner/meal_planner_view.dart';
import 'features/settings/settings_view.dart';
import 'shared/widgets/app_background.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Load `.env` before any provider is built so api_config.dart sees
  // live secrets on first read. A missing `.env` (fresh clone without
  // `cp .env.example .env`, or a CI machine that only uses --dart-define)
  // is graceful: api_config.dart falls back to compile-time defaults,
  // which in turn triggers the rich mock pipeline.
  try {
    await DotEnv.load(fileName: '.env');
  } catch (_) {
    // No .env present. Continue with --dart-define fallbacks and mocks.
  }
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light.copyWith(
    statusBarColor: Color(0x00000000),
    systemNavigationBarColor: AppColors.background,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  await StorageService.init();
  LocalFoodRepository.init();
  runApp(const ProviderScope(child: NutriVisionApp()));
}

/// Root widget.
///
/// Watches [isOnboardedProvider] to decide between the onboarding flow and
/// the main app shell. Uses [CupertinoTabScaffold] with three tabs:
/// Home / Plan / Settings.
class NutriVisionApp extends ConsumerWidget {
  const NutriVisionApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnboarded = ref.watch(isOnboardedProvider);

    return CupertinoApp(
      title: 'NutriVision AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.cupertino,
      builder: (context, child) {
        return MediaQuery(
          // Lock text scale so the layout's macro rings never overflow.
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
          child: child!,
        );
      },
      home: isOnboarded ? const MainShell() : const OnboardingFlow(),
    );
  }
}

/// Three-tab Cupertino shell.
class MainShell extends StatelessWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        backgroundColor: AppColors.backgroundAlt,
        activeColor: AppColors.neonLime,
        inactiveColor: AppColors.textTertiary,
        border: const Border(
          top: BorderSide(color: AppColors.borderSubtle, width: 0.5),
        ),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.house_fill),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.calendar_today),
            label: 'Plan',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.settings),
            label: 'Settings',
          ),
        ],
      ),
      tabBuilder: (context, index) {
        switch (index) {
          case 0:
            return CupertinoTabView(builder: (_) => const MainDashboard());
          case 1:
            return CupertinoTabView(builder: (_) => const MealPlannerView());
          case 2:
            return CupertinoTabView(builder: (_) => const SettingsView());
        }
        return const SizedBox.shrink();
      },
    );
  }
}
