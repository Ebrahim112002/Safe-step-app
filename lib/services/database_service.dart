import 'package:supabase_flutter/supabase_flutter.dart';

class DatabaseService {
  final supabase = Supabase.instance.client;

  // ১. Shob user fetch kora
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

  // ২. Ban/Unban toggle kora
  Future<void> toggleUserBan(String userId, bool currentStatus) async {
    try {
      await supabase
          .from('profiles')
          .update({'is_banned': !currentStatus})
          .eq('id', userId);
    } catch (e) {
      print('Error toggling ban status: $e');
    }
  }

  // ৩. Role Change (Admin <-> User) toggle kora
  Future<void> toggleUserRole(String userId, String currentRole) async {
    try {
      String newRole = (currentRole == 'admin') ? 'user' : 'admin';
      await supabase
          .from('profiles')
          .update({'role': newRole})
          .eq('id', userId);
    } catch (e) {
      print('Error toggling role: $e');
    }
  }

  // ৪. Current User Profile fetch
  Future<Map<String, dynamic>> getUserProfile() async {
    final user = supabase.auth.currentUser;
    if (user != null) {
      return await supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();
    }
    return {};
  }
}