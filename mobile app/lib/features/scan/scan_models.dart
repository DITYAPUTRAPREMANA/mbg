class ScanResult {
  final String imagePath;
  final double totalCalories;
  final double totalProtein;
  final double totalFat;
  final double totalCarbs;
  final double totalFiber;
  final List<ScanIngredient> ingredients;

  ScanResult({
    required this.imagePath,
    required this.totalCalories,
    required this.totalProtein,
    required this.totalFat,
    required this.totalCarbs,
    required this.totalFiber,
    required this.ingredients,
  });

  factory ScanResult.fromJson(Map<String, dynamic> json, String imagePath) {
    // 1. Ambil list dari key 'items'
    var itemsList = json['items'] as List? ?? [];

    // 2. Map ke list ScanIngredient
    List<ScanIngredient> ingredients = itemsList
        .map((i) => ScanIngredient.fromJson(i))
        .toList();

    // 3. Hitung total secara manual karena di JSON backend-mu
    // sepertinya tidak ada field 'total_calories' di root level.
    double cal = 0, prot = 0, fat = 0, carb = 0, fib = 0;

    for (var item in ingredients) {
      cal += item.calories;
      prot += item.protein;
      fat += item.fat;
      carb += item.carbs;
    }

    return ScanResult(
      imagePath: imagePath,
      totalCalories: cal,
      totalProtein: prot,
      totalFat: fat,
      totalCarbs: carb,
      totalFiber: fib,
      ingredients: ingredients,
    );
  }
}

class ScanIngredient {
  final String name;
  final double calories;
  final double protein;
  final double fat;
  final double carbs;
  final int matchPercentage;

  ScanIngredient({
    required this.name,
    required this.calories,
    required this.protein,
    required this.fat,
    required this.carbs,
    required this.matchPercentage,
  });

  factory ScanIngredient.fromJson(Map<String, dynamic> json) {
    // 1. Ambil sub-objek 'nutrition' dari JSON backend
    final nut = json['nutrition'] as Map<String, dynamic>? ?? {};

    return ScanIngredient(
      // Backend pakai key 'label', bukan 'name'
      name: json['label'] ?? 'Unknown',
      // Ambil dari dalam objek nutrition, perhatikan nama key-nya (calories, protein_g, dll)
      calories: (nut['calories'] as num? ?? 0.0).toDouble(),
      protein: (nut['protein_g'] as num? ?? 0.0).toDouble(),
      fat: (nut['fat_g'] as num? ?? 0.0).toDouble(),
      carbs: (nut['carbohydrate_g'] as num? ?? 0.0).toDouble(),
      // Backend pakai key 'confidence' (0.0 - 1.0), kita kali 100 untuk persentase
      matchPercentage: ((json['confidence'] as num? ?? 0.0) * 100).toInt(),
    );
  }
}
