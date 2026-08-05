# NutriVision AI

> Intelligent AI calorie & macro tracking assistant — dark glassmorphism, iOS-first Flutter.

NutriVision AI combines computer-vision food recognition, real-time barcode lookup for global branded products, and an AI-driven weight-loss meal planner into a single, ultra-sleek mobile experience.

## Features

- **AI Food Scanner** — point your camera, get instant calorie + macro estimates via GPT-4o / Gemini Vision.
- **Barcode Lookup** — scan any packaged product and pull nutrition data from the Open Food Facts database.
- **Macro Dashboard** — dynamic progress rings for calories, protein, carbs, fat, fiber, and water.
- **AI Weight-Loss Planner** — BMR/TDEE-based daily targets with a fully generated weekly meal plan.
- **Global Search + Manual Log** — search thousands of generic / branded foods with quick slider-adjust portions.
- **Offline-first** — Hive-backed local logging, custom meals, and user profiles.

## Quick start

```bash
flutter pub get
cp .env.example .env       # then paste your OpenAI key
flutter run -d ios
```

Without an `.env` the app boots straight into the simulator with rich
deterministic mocks — every AI scan, barcode lookup, and weekly plan is
generated locally so you can demo the full flow offline.

## Secrets / local config

The app reads every secret from a **single `.env`** file at the project
root. `flutter_dotenv` is loaded in `main.dart` before any provider
builds, so the values are visible to `api_config.dart` from the first
frame.

| Source                                | Use case                          |
| ------------------------------------- | --------------------------------- |
| `.env` at project root                | Local dev (committed `.env` is gitignored) |
| `--dart-define=KEY=value`             | CI / production builds            |
| Empty / missing                       | Triggers deterministic mocks      |

Read order in [`lib/core/services/api_config.dart`](lib/core/services/api_config.dart):

```dart
geminiKey = DotEnv.env['GEMINI_API_KEY']
            ?? String.fromEnvironment('GEMINI_API_KEY');
```

`bool` and `String` overrides work the same way, so a single `flutter run`
in a CI runner can ship a reproducible snapshot:

```bash
flutter build ios \
  --dart-define=GEMINI_API_KEY=AIza-prod-... \
  --dart-define=USE_MOCK_AI=false
```

### Available variables

```ini
GEMINI_API_KEY=AIza...           # https://aistudio.google.com/apikey
GEMINI_VISION_MODEL=gemini-1.5-flash   # or gemini-1.5-pro, gemini-2.0-flash-exp
USE_MOCK_AI=false                 # force mocks even if a key is present
```

## Tech stack

| Layer | Choice |
|-------|--------|
| Framework | Flutter (Cupertino widgets, iOS-first) |
| State | Riverpod |
| Local DB | Hive (`build_runner`-free JSON boxes) |
| Vision API | Google Gemini (`gemini-1.5-flash` default, with rich curated mock fallback) |
| Food DB | Open Food Facts (with curated local fallback) |
| Cam / Barcode | mobile_scanner (stub for simulator) |
| Config | flutter_dotenv + dart-define |

## Architecture

```
lib/
├── main.dart
├── app.dart              # NutriVisionApp + MainShell tab scaffold
├── core/
│   ├── theme/            # colors, typography, glassmorphism
│   ├── models/           # UserProfile, FoodItem, MealEntry, MacroTargets, MealPlan
│   ├── services/         # api_config, OpenAI vision, OpenFoodFacts, MealPlanner, Storage
│   ├── providers/        # Riverpod providers
│   └── utils/            # BMR / TDEE calculators, formatters
├── shared/
│   └── widgets/          # GlassCard, MacroRing, NeonButton, SectionHeader
└── features/
    ├── onboarding/       # 7-step Cupertino flow
    ├── dashboard/        # MainDashboard
    ├── scanner/          # AIScannerView
    ├── planner/          # MealPlannerView
    ├── search/           # FoodSearchModal
    └── settings/         # SettingsView (profile + reset)
```

## Run on iOS Simulator

```bash
flutter pub get
flutter run -d ios
```

## Build for a real device

```bash
# Dev build (uses .env if present)
flutter build ios --release --dart-define=GEMINI_API_KEY=AIza-...
flutter install
```

### ⚠️ Production-safety: never ship a real `.env`

Because the asset declaration `- .env` in `pubspec.yaml` bundles the file
into the build output, **a real `.env` containing production keys would be
shipped inside the `.ipa`**. Strip the local `.env` before promoting a
build, and pass secrets via `--dart-define` (or your CI secret store):

```bash
# Safe production build — no .env on disk, secrets via dart-define.
mv .env .env.local   # or just: rm .env
flutter build ipa --release \
  --dart-define=GEMINI_API_KEY=AIza-prod-... \
  --dart-define=USE_MOCK_AI=false
```

For multi-environment setups, prefer a build script (`scripts/release.sh`)
that asserts `.env` is absent and reads keys from `$ENV_VARS`.

## License

MIT — see `LICENSE` (add one if shipping externally).
