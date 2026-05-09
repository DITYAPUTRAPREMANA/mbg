import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Fungsi Register + Simpan Nama ke Tabel Profiles
  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    // 1. Daftar ke sistem Auth Supabase
    final AuthResponse res = await _supabase.auth.signUp(
      email: email,
      password: password,
    );

    final user = res.user;

    // 2. Jika berhasil, masukkan nama ke tabel 'profiles' yang kita buat di SQL tadi
    if (user != null) {
      await _supabase.from('profiles').insert({
        'id': user.id, // ID harus sama dengan ID Auth
        'full_name': fullName,
        'email': email,
      });
    }
  }

  // Fungsi Login
  Future<void> signIn(String email, String password) async {
    await _supabase.auth.signInWithPassword(email: email, password: password);
  }
}
