import '../models/food_item.dart';

/// Curated local "common foods" database.
///
/// Used by:
///   1. [LocalFoodRepository] as the primary search index.
///   2. The AI vision service as a deterministic fallback when offline.
///   3. The onboarding "Try NutriVision" demo on the dashboard.
///
/// Values are **per 100 g** unless noted; serving sizes are illustrative.
class LocalFoodRepository {
  LocalFoodRepository._();

  /// Master catalog indexed by canonical id.
  static final Map<String, FoodItem> _items = <String, FoodItem>{};

  /// Public read-only view (for search).
  static List<FoodItem> get all => _items.values.toList(growable: false);

  static FoodItem? byId(String id) => _items[id];

  // ---------------------------------------------------------------------------
  // Initialization — populates the catalog once at app boot.
  // ---------------------------------------------------------------------------
  static void init() {
    if (_items.isNotEmpty) return;
    for (final raw in _catalog) {
      final item = FoodItem.fromMap(raw, source: FoodSource.local, idOverride: raw['id'] as String);
      _items[item.id] = item;
    }
  }

  // ---------------------------------------------------------------------------
  // Search.
  // ---------------------------------------------------------------------------
  static List<FoodItem> search(String query, {int limit = 30}) {
    if (query.trim().isEmpty) return all.take(limit).toList();
    final q = query.toLowerCase().trim();
    final hits = <_Scored>[];
    for (final f in _items.values) {
      final score = _matchScore(f, q);
      if (score > 0) hits.add(_Scored(f, score));
    }
    hits.sort((a, b) => b.score.compareTo(a.score));
    return hits.take(limit).map((s) => s.food).toList();
  }

  static double _matchScore(FoodItem f, String q) {
    var s = 0.0;
    if (f.name.toLowerCase().startsWith(q)) s += 5;
    if (f.name.toLowerCase().contains(q)) s += 2;
    final b = (f.brand ?? '').toLowerCase();
    if (b.contains(q)) s += 1.5;
    return s;
  }

  static List<FoodItem> suggestions({int limit = 8}) {
    final popular = [..._items.values]..sort((a, b) => b.caloriesPer100g.compareTo(a.caloriesPer100g));
    return popular.take(limit).toList();
  }

  // ---------------------------------------------------------------------------
  // Curated catalog.
  // ---------------------------------------------------------------------------
  static final List<Map<String, dynamic>> _catalog = [
    // ============ FRUITS ============
    {'id': 'apple',      'name': 'Apple',                'servingSize': 182, 'kcal_100g': 52,  'protein_100g': 0.3,  'carbs_100g': 14,   'fat_100g': 0.2,  'fiber_100g': 2.4},
    {'id': 'banana',     'name': 'Banana',               'servingSize': 118, 'kcal_100g': 89,  'protein_100g': 1.1,  'carbs_100g': 23,   'fat_100g': 0.3,  'fiber_100g': 2.6},
    {'id': 'orange',     'name': 'Orange',               'servingSize': 130, 'kcal_100g': 47,  'protein_100g': 0.9,  'carbs_100g': 12,   'fat_100g': 0.1,  'fiber_100g': 2.4},
    {'id': 'strawberry', 'name': 'Strawberries',         'servingSize': 152, 'kcal_100g': 32,  'protein_100g': 0.7,  'carbs_100g': 7.7,  'fat_100g': 0.3,  'fiber_100g': 2.0},
    {'id': 'blueberry',  'name': 'Blueberries',          'servingSize': 148, 'kcal_100g': 57,  'protein_100g': 0.7,  'carbs_100g': 14,   'fat_100g': 0.3,  'fiber_100g': 2.4},
    {'id': 'grape',      'name': 'Grapes',               'servingSize': 92,  'kcal_100g': 69,  'protein_100g': 0.7,  'carbs_100g': 18,   'fat_100g': 0.2,  'fiber_100g': 0.9},
    {'id': 'avocado',    'name': 'Avocado',              'servingSize': 150, 'kcal_100g': 160, 'protein_100g': 2.0,  'carbs_100g': 9.0,  'fat_100g': 15,   'fiber_100g': 7.0},
    {'id': 'watermelon', 'name': 'Watermelon',           'servingSize': 280, 'kcal_100g': 30,  'protein_100g': 0.6,  'carbs_100g': 7.6,  'fat_100g': 0.2,  'fiber_100g': 0.4},
    {'id': 'mango',      'name': 'Mango',                'servingSize': 165, 'kcal_100g': 60,  'protein_100g': 0.8,  'carbs_100g': 15,   'fat_100g': 0.4,  'fiber_100g': 1.6},
    {'id': 'pineapple',  'name': 'Pineapple',            'servingSize': 165, 'kcal_100g': 50,  'protein_100g': 0.5,  'carbs_100g': 13,   'fat_100g': 0.1,  'fiber_100g': 1.4},
    // ============ VEGETABLES ============
    {'id': 'broccoli',      'name': 'Broccoli',         'servingSize': 91, 'kcal_100g': 34, 'protein_100g': 2.8, 'carbs_100g': 7.0, 'fat_100g': 0.4, 'fiber_100g': 2.6},
    {'id': 'spinach',       'name': 'Spinach',          'servingSize': 30, 'kcal_100g': 23, 'protein_100g': 2.9, 'carbs_100g': 3.6, 'fat_100g': 0.4, 'fiber_100g': 2.2},
    {'id': 'kale',          'name': 'Kale',             'servingSize': 67, 'kcal_100g': 49, 'protein_100g': 4.3, 'carbs_100g': 9.0, 'fat_100g': 0.9, 'fiber_100g': 3.6},
    {'id': 'carrot',        'name': 'Carrot',           'servingSize': 61, 'kcal_100g': 41, 'protein_100g': 0.9, 'carbs_100g': 9.6, 'fat_100g': 0.2, 'fiber_100g': 2.8},
    {'id': 'sweetpotato',   'name': 'Sweet Potato',     'servingSize': 130, 'kcal_100g': 86, 'protein_100g': 1.6, 'carbs_100g': 20, 'fat_100g': 0.1, 'fiber_100g': 3.0},
    {'id': 'potato',        'name': 'Potato',           'servingSize': 173, 'kcal_100g': 77, 'protein_100g': 2.0, 'carbs_100g': 17, 'fat_100g': 0.1, 'fiber_100g': 2.2},
    {'id': 'tomato',        'name': 'Tomato',           'servingSize': 123, 'kcal_100g': 18, 'protein_100g': 0.9, 'carbs_100g': 3.9, 'fat_100g': 0.2, 'fiber_100g': 1.2},
    {'id': 'cucumber',      'name': 'Cucumber',         'servingSize': 119, 'kcal_100g': 16, 'protein_100g': 0.7, 'carbs_100g': 3.6, 'fat_100g': 0.1, 'fiber_100g': 0.5},
    {'id': 'bellpepper',    'name': 'Bell Pepper',      'servingSize': 119, 'kcal_100g': 31, 'protein_100g': 1.0, 'carbs_100g': 6.0, 'fat_100g': 0.3, 'fiber_100g': 2.1},
    {'id': 'zucchini',      'name': 'Zucchini',         'servingSize': 124, 'kcal_100g': 17, 'protein_100g': 1.2, 'carbs_100g': 3.1, 'fat_100g': 0.3, 'fiber_100g': 1.0},

    // ============ PROTEINS ============
    {'id': 'chickenbreast', 'name': 'Chicken Breast',       'servingSize': 100, 'kcal_100g': 165, 'protein_100g': 31,  'carbs_100g': 0,    'fat_100g': 3.6, 'fiber_100g': 0},
    {'id': 'chickenthigh',  'name': 'Chicken Thigh',        'servingSize': 100, 'kcal_100g': 209, 'protein_100g': 26,  'carbs_100g': 0,    'fat_100g': 11,  'fiber_100g': 0},
    {'id': 'beefsteak',     'name': 'Beef Steak',           'servingSize': 100, 'kcal_100g': 271, 'protein_100g': 25,  'carbs_100g': 0,    'fat_100g': 19,  'fiber_100g': 0},
    {'id': 'groundbeef',    'name': 'Ground Beef (90/10)',  'servingSize': 100, 'kcal_100g': 176, 'protein_100g': 20,  'carbs_100g': 0,    'fat_100g': 10,  'fiber_100g': 0},
    {'id': 'salmon',        'name': 'Atlantic Salmon',      'servingSize': 100, 'kcal_100g': 208, 'protein_100g': 20,  'carbs_100g': 0,    'fat_100g': 13,  'fiber_100g': 0},
    {'id': 'tuna',          'name': 'Tuna (canned in water)', 'servingSize': 100, 'kcal_100g': 116, 'protein_100g': 26, 'carbs_100g': 0, 'fat_100g': 0.8, 'fiber_100g': 0},
    {'id': 'shrimp',        'name': 'Shrimp',               'servingSize': 100, 'kcal_100g': 99, 'protein_100g': 24,    'carbs_100g': 0.2, 'fat_100g': 0.3, 'fiber_100g': 0},
    {'id': 'egg',           'name': 'Egg',                  'servingSize': 50,  'kcal_100g': 155, 'protein_100g': 13, 'carbs_100g': 1.1,  'fat_100g': 11,  'fiber_100g': 0},
    {'id': 'eggs',          'name': 'Egg Whites',           'servingSize': 33,  'kcal_100g': 52,  'protein_100g': 11, 'carbs_100g': 0.7, 'fat_100g': 0.2, 'fiber_100g': 0},
    {'id': 'tofu',          'name': 'Firm Tofu',            'servingSize': 100, 'kcal_100g': 144, 'protein_100g': 17, 'carbs_100g': 2.8, 'fat_100g': 8.7, 'fiber_100g': 2.3},
    {'id': 'lentils',       'name': 'Lentils (cooked)',     'servingSize': 100, 'kcal_100g': 116, 'protein_100g': 9.0, 'carbs_100g': 20, 'fat_100g': 0.4, 'fiber_100g': 7.9},
    {'id': 'blackbeans',    'name': 'Black Beans (cooked)', 'servingSize': 100, 'kcal_100g': 132, 'protein_100g': 8.9, 'carbs_100g': 24, 'fat_100g': 0.5, 'fiber_100g': 8.7},
    {'id': 'chickpeas',     'name': 'Chickpeas (cooked)',   'servingSize': 100, 'kcal_100g': 164, 'protein_100g': 8.9, 'carbs_100g': 27, 'fat_100g': 2.6, 'fiber_100g': 7.6},

    // ============ GRAINS & CARBS ============
    {'id': 'whiterice',     'name': 'White Rice (cooked)',     'servingSize': 100, 'kcal_100g': 130, 'protein_100g': 2.7, 'carbs_100g': 28,  'fat_100g': 0.3, 'fiber_100g': 0.4},
    {'id': 'brownrice',     'name': 'Brown Rice (cooked)',     'servingSize': 100, 'kcal_100g': 123, 'protein_100g': 2.7, 'carbs_100g': 26,  'fat_100g': 1.0, 'fiber_100g': 1.6},
    {'id': 'quinoa',        'name': 'Quinoa (cooked)',         'servingSize': 100, 'kcal_100g': 120, 'protein_100g': 4.4, 'carbs_100g': 21,  'fat_100g': 1.9, 'fiber_100g': 2.8},
    {'id': 'oats',          'name': 'Rolled Oats (dry)',       'servingSize': 40,  'kcal_100g': 389, 'protein_100g': 17,  'carbs_100g': 66,  'fat_100g': 7.0, 'fiber_100g': 11},
    {'id': 'wholewheatbread','name': 'Whole-Wheat Bread',      'servingSize': 28,  'kcal_100g': 247, 'protein_100g': 13,  'carbs_100g': 41,  'fat_100g': 3.4, 'fiber_100g': 7.0},
    {'id': 'whitbread',     'name': 'White Bread',             'servingSize': 28,  'kcal_100g': 265, 'protein_100g': 9.0, 'carbs_100g': 49,  'fat_100g': 3.2, 'fiber_100g': 2.7},
    {'id': 'pasta',         'name': 'Pasta (cooked)',          'servingSize': 100, 'kcal_100g': 158, 'protein_100g': 5.8, 'carbs_100g': 31,  'fat_100g': 0.9, 'fiber_100g': 1.8},
    {'id': 'bagel',         'name': 'Plain Bagel',             'servingSize': 95,  'kcal_100g': 257, 'protein_100g': 10,  'carbs_100g': 51,  'fat_100g': 1.5, 'fiber_100g': 2.4},

    // ============ DAIRY ============
    {'id': 'greekyogurt',   'name': 'Greek Yogurt (non-fat)',   'servingSize': 170, 'kcal_100g': 59,  'protein_100g': 10, 'carbs_100g': 3.6, 'fat_100g': 0.4, 'fiber_100g': 0},
    {'id': 'wholemilk',     'name': 'Whole Milk',               'servingSize': 244, 'kcal_100g': 61,  'protein_100g': 3.2, 'carbs_100g': 4.8, 'fat_100g': 3.3, 'fiber_100g': 0},
    {'id': 'almondmilk',    'name': 'Almond Milk (unsweetened)','servingSize': 240, 'kcal_100g': 17,  'protein_100g': 0.6, 'carbs_100g': 0.6, 'fat_100g': 1.5, 'fiber_100g': 0.4},
    {'id': 'cheddar',       'name': 'Cheddar Cheese',           'servingSize': 28,  'kcal_100g': 403, 'protein_100g': 25,  'carbs_100g': 1.3, 'fat_100g': 33,  'fiber_100g': 0},
    {'id': 'mozzarella',    'name': 'Mozzarella Cheese',        'servingSize': 28,  'kcal_100g': 280, 'protein_100g': 28,  'carbs_100g': 3.1, 'fat_100g': 17,  'fiber_100g': 0},
    {'id': 'cottagecheese', 'name': 'Cottage Cheese (low-fat)', 'servingSize': 113, 'kcal_100g': 81,  'protein_100g': 11,  'carbs_100g': 4.3, 'fat_100g': 2.3, 'fiber_100g': 0},

    // ============ NUTS / FATS ============
    {'id': 'almonds',       'name': 'Almonds',                  'servingSize': 28,  'kcal_100g': 579, 'protein_100g': 21,  'carbs_100g': 22, 'fat_100g': 50,  'fiber_100g': 13},
    {'id': 'walnuts',       'name': 'Walnuts',                  'servingSize': 28,  'kcal_100g': 654, 'protein_100g': 15,  'carbs_100g': 14, 'fat_100g': 65,  'fiber_100g': 6.7},
    {'id': 'peanutbutter',  'name': 'Peanut Butter',            'servingSize': 32,  'kcal_100g': 588, 'protein_100g': 25,  'carbs_100g': 20, 'fat_100g': 50,  'fiber_100g': 6.0},
    {'id': 'oliveoil',      'name': 'Olive Oil',                'servingSize': 14,  'kcal_100g': 884, 'protein_100g': 0,   'carbs_100g': 0,  'fat_100g': 100, 'fiber_100g': 0},
    {'id': 'butter',        'name': 'Butter',                   'servingSize': 14,  'kcal_100g': 717, 'protein_100g': 0.9, 'carbs_100g': 0.1, 'fat_100g': 81, 'fiber_100g': 0},

    // ============ SWEETS / SNACKS ============
    {'id': 'darkchocolate', 'name': 'Dark Chocolate (85%)',     'servingSize': 28,  'kcal_100g': 600, 'protein_100g': 13,  'carbs_100g': 23, 'fat_100g': 53,  'fiber_100g': 11},
    {'id': 'icecream',      'name': 'Vanilla Ice Cream',        'servingSize': 66,  'kcal_100g': 207, 'protein_100g': 3.5, 'carbs_100g': 24, 'fat_100g': 11,  'fiber_100g': 0.7},
    {'id': 'potatochips',   'name': 'Potato Chips',             'servingSize': 28,  'kcal_100g': 536, 'protein_100g': 7.0, 'carbs_100g': 53, 'fat_100g': 35,  'fiber_100g': 4.4},
    {'id': 'cookie',        'name': 'Chocolate Chip Cookie',    'servingSize': 16,  'kcal_100g': 488, 'protein_100g': 5.4, 'carbs_100g': 64, 'fat_100g': 23,  'fiber_100g': 2.4},

    // ============ BEVERAGES ============
    {'id': 'blackcoffee',   'name': 'Black Coffee',             'servingSize': 240, 'kcal_100g': 1,  'protein_100g': 0.1, 'carbs_100g': 0,    'fat_100g': 0,    'fiber_100g': 0},
    {'id': 'greentea',      'name': 'Green Tea (unsweetened)',  'servingSize': 240, 'kcal_100g': 1,  'protein_100g': 0,   'carbs_100g': 0,    'fat_100g': 0,    'fiber_100g': 0},
    {'id': 'orangejuice',   'name': 'Orange Juice',             'servingSize': 248, 'kcal_100g': 45, 'protein_100g': 0.7, 'carbs_100g': 10,   'fat_100g': 0.2,  'fiber_100g': 0.2},
    {'id': 'cola',          'name': 'Coca-Cola',       'brand': 'Coca-Cola',  'servingSize': 355, 'kcal_100g': 42, 'protein_100g': 0, 'carbs_100g': 11, 'fat_100g': 0, 'fiber_100g': 0, 'barcode': '5449000000996'},
    {'id': 'cocacola',      'name': 'Coca-Cola Original',  'brand': 'Coca-Cola',  'servingSize': 250, 'kcal_100g': 42, 'protein_100g': 0, 'carbs_100g': 11, 'fat_100g': 0, 'fiber_100g': 0, 'barcode': '5490000000996'},
    {'id': 'pepsi',         'name': 'Pepsi',              'brand': 'Pepsi',      'servingSize': 355, 'kcal_100g': 41, 'protein_100g': 0, 'carbs_100g': 11, 'fat_100g': 0, 'fiber_100g': 0, 'barcode': '012000001017'},
    {'id': 'sprite',        'name': 'Sprite',             'brand': 'Coca-Cola',  'servingSize': 355, 'kcal_100g': 39, 'protein_100g': 0, 'carbs_100g': 10, 'fat_100g': 0, 'fiber_100g': 0, 'barcode': '5490000003656'},
    {'id': 'redbull',       'name': 'Red Bull Energy Drink','brand': 'Red Bull', 'servingSize': 250, 'kcal_100g': 45, 'protein_100g': 0, 'carbs_100g': 11, 'fat_100g': 0, 'fiber_100g': 0, 'barcode': '9002490100070'},

    // ============ BRANDED SNACKS ============
    {'id': 'cheerios',      'name': 'Cheerios',         'brand': 'General Mills', 'servingSize': 28, 'kcal_100g': 367, 'protein_100g': 12,  'carbs_100g': 67, 'fat_100g': 7,  'fiber_100g': 10, 'barcode': '016000275287'},
    {'id': 'rxbar',         'name': 'RXBAR Chocolate Sea Salt', 'brand': 'RXBAR', 'servingSize': 52, 'kcal_100g': 423, 'protein_100g': 25, 'carbs_100g': 42, 'fat_100g': 19, 'fiber_100g': 10, 'barcode': '858041004018'},
    {'id': 'questbar',      'name': 'Quest Protein Bar - Cookies & Cream', 'brand': 'Quest Nutrition', 'servingSize': 60, 'kcal_100g': 333, 'protein_100g': 33, 'carbs_100g': 33, 'fat_100g': 12, 'fiber_100g': 17, 'barcode': '888849000018'},
    {'id': 'kindbar',       'name': 'KIND Bar - Dark Chocolate Nuts & Sea Salt', 'brand': 'KIND', 'servingSize': 40, 'kcal_100g': 510, 'protein_100g': 13, 'carbs_100g': 38, 'fat_100g': 33, 'fiber_100g': 15, 'barcode': '602652171000'},
    {'id': 'clifbar',       'name': 'CLIF Bar - Chocolate Chip', 'brand': 'CLIF', 'servingSize': 68, 'kcal_100g': 412, 'protein_100g': 13, 'carbs_100g': 65, 'fat_100g': 11, 'fiber_100g': 6.6, 'barcode': '722252100900'},
    {'id': 'layclassic',    'name': "Lay's Classic Potato Chips", 'brand': "Lay's", 'servingSize': 28, 'kcal_100g': 536, 'protein_100g': 7,  'carbs_100g': 53, 'fat_100g': 35, 'fiber_100g': 4.4, 'barcode': '028400064057'},
    {'id': 'doritos',       'name': 'Doritos Nacho Cheese', 'brand': 'Doritos', 'servingSize': 28, 'kcal_100g': 500, 'protein_100g': 7,  'carbs_100g': 64, 'fat_100g': 25, 'fiber_100g': 3.6, 'barcode': '028400064507'},
    {'id': 'kitkat',        'name': 'Kit Kat',         'brand': 'Nestle',     'servingSize': 42, 'kcal_100g': 519, 'protein_100g': 7, 'carbs_100g': 60, 'fat_100g': 28, 'fiber_100g': 1.4, 'barcode': '7613034626844'},
    {'id': 'snickers',      'name': 'Snickers',        'brand': 'Mars',       'servingSize': 52, 'kcal_100g': 488, 'protein_100g': 9, 'carbs_100g': 56, 'fat_100g': 23, 'fiber_100g': 2.4, 'barcode': '040000485101'},
    {'id': 'cheezit',       'name': 'Cheez-It Original', 'brand': 'Sunshine',  'servingSize': 30, 'kcal_100g': 533, 'protein_100g': 13, 'carbs_100g': 60, 'fat_100g': 27, 'fiber_100g': 3.3, 'barcode': '024100442027'},

    // ============ FAST FOOD ============
    {'id': 'bigmac',        'name': 'Big Mac',          'brand': "McDonald's", 'servingSize': 219, 'kcal_100g': 257, 'protein_100g': 13, 'carbs_100g': 21, 'fat_100g': 14, 'fiber_100g': 1.4, 'barcode': '000000000001'},
    {'id': 'mcnuggets',     'name': 'Chicken McNuggets (6 pc)','brand': "McDonald's",'servingSize': 96, 'kcal_100g': 296, 'protein_100g': 16, 'carbs_100g': 16, 'fat_100g': 19, 'fiber_100g': 0.6, 'barcode': '000000000002'},
    {'id': 'whopper',       'name': 'Whopper',          'brand': 'Burger King', 'servingSize': 270, 'kcal_100g': 250, 'protein_100g': 12, 'carbs_100g': 23, 'fat_100g': 12, 'fiber_100g': 1.4, 'barcode': '000000000003'},
    {'id': 'pizzabslice',   'name': 'Cheese Pizza Slice','brand': 'Generic',   'servingSize': 107, 'kcal_100g': 266, 'protein_100g': 11, 'carbs_100g': 33, 'fat_100g': 10, 'fiber_100g': 2.3, 'barcode': '000000000004'},
    {'id': 'subwayturkey',  'name': 'Turkey Breast 6" Sub','brand': 'Subway',  'servingSize': 230, 'kcal_100g': 200, 'protein_100g': 19, 'carbs_100g': 38, 'fat_100g': 3.3, 'fiber_100g': 4.4, 'barcode': '000000000005'},
  ];
}

class _Scored {
  final FoodItem food;
  final double score;
  const _Scored(this.food, this.score);
}
