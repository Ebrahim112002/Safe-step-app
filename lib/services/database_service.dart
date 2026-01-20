import 'package:supabase_flutter/supabase_flutter.dart';

class DatabaseService {
  final supabase = Supabase.instance.client;

  // ১. Admin-er jonno shob user-er list fetch kora
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final response = await supabase
          .from('profiles')
          .select()
          .order('email', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching users: $e');
      return [];
    }
  }

  // ২. Email ba Phone diye user search kora (Admin-er jonno)
  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    try {
      final response = await supabase.from('profiles').select().or(
          'email.ilike.%$query%,phone.ilike.%$query%'); // Email ba Phone search
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error searching users: $e');
      return [];
    }
  }

  // ৩. User-er nijer post save kora (Unique ID shoho)
  Future<void> createPost(String content) async {
    final user = supabase.auth.currentUser;
    if (user != null) {
      await supabase.from('posts').insert({
        'user_id': user.id, // Supabase UUID
        'email': user.email,
        'content': content,
        'created_at': DateTime.now().toIso8601String(),
      });
    }
  }

  // ৪. User-er role check kora (Admin naki User)
  Future<String> getUserRole() async {
    final user = supabase.auth.currentUser;
    if (user != null) {
      final data = await supabase
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .single();
      return data['role'] ?? 'user';
    }
    return 'user';
  }
}
