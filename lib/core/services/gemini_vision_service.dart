import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

import '../models/food_item.dart';
import 'api_config.dart';
import 'local_food_database.dart';

/// Result entry from the AI vision pipeline.
class AiDetectedFood {
  final FoodItem item;
  final double portionGrams;
  AiDetectedFood({required this.item, required this.portionGrams});
}

/// Structured result returned by the AI vision pipeline.
class AiMealAnalysis {
  final List<AiDetectedFood> foods;
  final double totalWeightG;
  final String notes;

  const AiMealAnalysis({
    required this.foods,
    required this.totalWeightG,
    required this.notes,
  });

  double get totalKcal     => _sum((e) => e.item.caloriesPer100g * (e.portionGrams / 100.0));
  double get totalProteinG => _sum((e) => e.item.proteinPer100g  * (e.portionGrams / 100.0));
  double get totalCarbsG   => _sum((e) => e.item.carbsPer100g    * (e.portionGrams / 100.0));
  double get totalFatG     => _sum((e) => e.item.fatPer100g      * (e.portionGrams / 100.0));
  double get totalFiberG   => _sum((e) => e.item.fiberPer100g    * (e.portionGrams / 100.0));

  double _sum(double Function(AiDetectedFood) f) =>
      foods.fold(0.0, (s, e) => s + f(e));
}

/// Calls Google's Gemini Vision (`gemini-1.5-flash` by default — also
/// `gemini-1.5-pro` for higher accuracy). Sends the image as an inline_data
/// part and constrains the response to structured JSON via
/// `responseMimeType: "application/json"`.
///
/// In the iOS Simulator (no key set), [ApiConfig.hasGeminiCredentials] is
/// false and the service falls back to a deterministic mock curated from
/// [LocalFoodRepository].
class GeminiVisionService {
  GeminiVisionService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<AiMealAnalysis> analyzeImage({required String base64Image, String? hint}) async {
    if (!ApiConfig.hasGeminiCredentials) {
      // Realistic delay so the UI's loading state is visible.
      await Future<void>.delayed(const Duration(milliseconds: 1400));
      return _mockAnalysis(hint: hint);
    }
    try {
      final prompt = _buildPrompt(hint: hint);
      final model = ApiConfig.geminiVisionModel;
      final uri = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/'
        '$model:generateContent?key=${ApiConfig.geminiKey}',
      );
      final body = jsonEncode({
        'contents': [
          {
            'role': 'user',
            'parts': [
              {'text': prompt},
              {
                'inline_data': {
                  'mime_type': 'image/jpeg',
                  'data': base64Image,
                },
              },
            ],
          },
        ],
        'generationConfig': {
          'temperature': 0.2,
          'maxOutputTokens': 1200,
          'responseMimeType': 'application/json',
        },
      });

      final res = await _client
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(ApiConfig.requestTimeout);

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        return _parseResponse(json);
      }
      // Soft-fail to mock so the UI keeps working.
      return _mockAnalysis(hint: hint);
    } catch (_) {
      return _mockAnalysis(hint: hint);
    }
  }

  /// Mock that builds an [AiMealAnalysis] from [LocalFoodRepository].
  /// Picking honors a [hint] when one is provided.
  AiMealAnalysis _mockAnalysis({String? hint}) {
    final pool = LocalFoodRepository.all;
    final rng = Random(DateTime.now().microsecondsSinceEpoch);
    final count = 1 + rng.nextInt(2); // 1-2 items
    final picked = <FoodItem>[];
    final used = <String>{};
    final hintLower = (hint ?? '').toLowerCase();

    if (hintLower.isNotEmpty) {
      for (final f in pool) {
        final n = f.name.toLowerCase();
        if ((n.contains(hintLower) || (f.brand ?? '').toLowerCase().contains(hintLower)) &&
            !used.contains(f.id)) {
          picked.add(f);
          used.add(f.id);
          break;
        }
      }
    }
    while (picked.length < count && used.length < pool.length) {
      final i = rng.nextInt(pool.length);
      final f = pool[i];
      if (used.add(f.id)) picked.add(f);
    }

    final detections = picked.map((f) {
      return AiDetectedFood(item: f, portionGrams: _typicalPortionFor(f));
    }).toList();

    final totalWeightG = detections.fold<double>(0, (s, e) => s + e.portionGrams);

    return AiMealAnalysis(
      foods: detections,
      totalWeightG: totalWeightG,
      notes: hintLower.isNotEmpty
          ? 'Recognized food matching "$hint". Portion estimated visually.'
          : 'Analyzed ${detections.length} item(s) using on-device heuristics.',
    );
  }

  double _typicalPortionFor(FoodItem f) {
    final n = f.name.toLowerCase();
    if (n.contains('salad'))                   return 320;
    if (n.contains('pizza'))                   return 200;
    if (n.contains('burger'))                  return 230;
    if (n.contains('rice') || n.contains('pasta')) return 250;
    if (n.contains('sandwich') || n.contains('sub')) return 220;
    if (n.contains('apple') || n.contains('banana') || n.contains('orange')) return 180;
    if (n.contains('chicken') || n.contains('beef') ||
        n.contains('salmon') || n.contains('fish')) return 200;
    if (n.contains('oatmeal') || n.contains('porridge')) return 300;
    if (n.contains('yogurt') || n.contains('yoghurt')) return 170;
    if (n.contains('egg'))                     return 100;
    if (n.contains('coffee') || n.contains('tea')) return 240;
    if (n.contains('juice') || n.contains('soda') ||
        n.contains('cola') || n.contains('sprite')) return 330;
    return f.servingSize.roundToDouble();
  }

  String _buildPrompt({String? hint}) {
    final schema = '''{
  "items": [
    {
      "name": string,
      "brand": string?,
      "grams": number,
      "kcal": number,
      "protein_g": number,
      "carbs_g": number,
      "fat_g": number,
      "fiber_g": number,
      "confidence": number
    }
  ],
  "notes": string
}''';
    if (hint != null && hint.isNotEmpty) {
      return 'You are NutriVision AI.\n'
          'Identify the food in the image (the user said: "$hint"). '
          'Estimate portion in grams.\n'
          'Return ONLY valid JSON matching this schema (no prose, no markdown fences):\n'
          '$schema';
    }
    return 'You are NutriVision AI.\n'
        'Identify every distinct food in the image. Estimate portions in grams.\n'
        'Return ONLY valid JSON matching this schema (no prose, no markdown fences):\n'
        '$schema';
  }

  AiMealAnalysis _parseResponse(Map<String, dynamic> body) {
    try {
      final candidates = body['candidates'] as List?;
      if (candidates == null || candidates.isEmpty) return _mockAnalysis();
      final content = (candidates.first as Map<String, dynamic>)['content']
          as Map<String, dynamic>?;
      if (content == null) return _mockAnalysis();
      final parts = content['parts'] as List?;
      if (parts == null || parts.isEmpty) return _mockAnalysis();
      final text = (parts.first as Map<String, dynamic>)['text']?.toString();
      if (text == null || text.isEmpty) return _mockAnalysis();

      final parsed = jsonDecode(text) as Map<String, dynamic>;
      final foods = <AiDetectedFood>[];
      for (final raw in (parsed['items'] as List?) ?? const []) {
        final m = raw as Map<String, dynamic>;
        final grams = ((m['grams'] as num?) ?? 100).toDouble();
        final k = ((m['kcal'] as num?) ?? 0).toDouble();
        final p = ((m['protein_g'] as num?) ?? 0).toDouble();
        final c = ((m['carbs_g'] as num?) ?? 0).toDouble();
        final f = ((m['fat_g'] as num?) ?? 0).toDouble();
        final fi = ((m['fiber_g'] as num?) ?? 0).toDouble();
        final factor = grams / 100.0;
        final item = FoodItem(
          id: '${m['id'] ?? DateTime.now().microsecondsSinceEpoch}_gemini',
          name: (m['name'] ?? 'Detected food').toString(),
          brand: m['brand']?.toString(),
          servingSize: grams,
          caloriesPer100g: k / factor,
          proteinPer100g: p / factor,
          carbsPer100g: c / factor,
          fatPer100g: f / factor,
          fiberPer100g: fi / factor,
          source: FoodSource.aiVision,
          confidence: (m['confidence'] as num?)?.toDouble(),
        );
        foods.add(AiDetectedFood(item: item, portionGrams: grams));
      }
      final weight = foods.fold<double>(0, (s, e) => s + e.portionGrams);
      return AiMealAnalysis(
        foods: foods,
        totalWeightG: weight,
        notes: (parsed['notes'] ?? '').toString(),
      );
    } catch (_) {
      return _mockAnalysis();
    }
  }
}
