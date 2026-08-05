import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Read order for every secret in the app:
///
///   1. `DotEnv` (loaded from `.env` by `main.dart`)
///   2. `--dart-define` flag (used in CI / production)
///   3. empty default → mocks
///
/// This keeps local dev ergonomic (edit `.env`, no command-line noise)
/// while letting CI snapshots ship a reproducible build.
class ApiConfig {
  ApiConfig._();

  static String _getenv(String key) =>
      (DotEnv.env[key] ?? '').trim().isNotEmpty
          ? DotEnv.env[key]!.trim()
          : '';

  /// Google Gemini API key. Empty → mocked analysis.
  ///
  /// Get one at https://aistudio.google.com/apikey — tokens are free for
  /// moderate use on `gemini-1.5-flash`.
  static String get geminiKey =>
      _getenv('GEMINI_API_KEY').isNotEmpty
          ? _getenv('GEMINI_API_KEY')
          : const String.fromEnvironment('GEMINI_API_KEY');

  /// Override the vision model. Defaults to `gemini-1.5-flash`.
  ///
  /// Any model that supports image input on the `generateContent` endpoint
  /// works: `gemini-1.5-flash`, `gemini-1.5-pro`, `gemini-2.0-flash-exp`.
  static String get geminiVisionModel {
    final fromDot = _getenv('GEMINI_VISION_MODEL');
    if (fromDot.isNotEmpty) return fromDot;
    return const String.fromEnvironment(
      'GEMINI_VISION_MODEL',
      defaultValue: 'gemini-1.5-flash',
    );
  }

  /// When true, mocks are forced even if a real key is present.
  static bool get forceMockAi {
    final fromDot = _getenv('USE_MOCK_AI').toLowerCase();
    if (fromDot.isNotEmpty) return fromDot == 'true' || fromDot == '1';
    return const bool.fromEnvironment(
      'USE_MOCK_AI',
      defaultValue: true,
    );
  }

  /// Network timeout for outbound HTTP calls.
  static const Duration requestTimeout = Duration(seconds: 12);

  /// The Open Food Facts public endpoint (no auth required).
  static const String openFoodFactsBase = 'https://world.openfoodfacts.org';

  /// Whether the app should hit real Gemini Vision.
  static bool get hasGeminiCredentials =>
      geminiKey.isNotEmpty && !forceMockAi;
}
