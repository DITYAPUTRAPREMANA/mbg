import 'package:supabase_flutter/supabase_flutter.dart';
import '../scan/scan_models.dart';

class ScanHistoryRepository {
  // Singleton Pattern agar bisa dipanggil via .instance
  ScanHistoryRepository._();
  static final ScanHistoryRepository instance = ScanHistoryRepository._();

  final _supabase = Supabase.instance.client;

  /// Fungsi untuk menyimpan data hasil scan ke Supabase
  Future<void> addResult(ScanResult result) async {
    final user = _supabase.auth.currentUser;

    // Pastikan user sudah login
    if (user == null) {
      print("Error: User tidak terautentikasi");
      return;
    }

    try {
      await _supabase.from('scan_history').insert({
        'user_id': user.id,
        'food_name': result.ingredients.isNotEmpty
            ? result.ingredients[0].name
            : "Menu MBG",
        'total_calories': result.totalCalories,
        'protein': result.totalProtein,
        'carbs': result.totalCarbs,
        'fat': result.totalFat,
        'image_url': result.imagePath, // Menyimpan path gambar lokal
      });
      print("✅ History berhasil disimpan ke Cloud!");
    } catch (e) {
      print("❌ Gagal menyimpan history ke Supabase: $e");
    }
  }

  /// Fungsi utama untuk mengambil data secara Real-time (Stream)
  Stream<List<Map<String, dynamic>>> get historyStream {
    final userId = _supabase.auth.currentUser?.id;
    return _supabase
        .from('scan_history')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId ?? '')
        .order('created_at', ascending: false);
  }

  /// Alias getter untuk memperbaiki Error di HistoryScreen baris 130
  /// Ini mengarahkan 'allResults' ke 'historyStream' agar build sukses
  Stream<List<Map<String, dynamic>>> get allResults => historyStream;
}
