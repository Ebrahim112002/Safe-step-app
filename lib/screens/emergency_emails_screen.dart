import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/app_theme.dart';

class EmergencyEmailsScreen extends StatefulWidget {
  const EmergencyEmailsScreen({super.key});

  @override
  State<EmergencyEmailsScreen> createState() => _EmergencyEmailsScreenState();
}

class _EmergencyEmailsScreenState extends State<EmergencyEmailsScreen> {
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  final _supabase = Supabase.instance.client;
  bool _isLoading = false;

  Future<void> _saveEmail() async {
    final user = _supabase.auth.currentUser;
    if (_emailController.text.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      await _supabase.from('emergency_emails').insert({
        'user_id': user?.id,
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
      });
      _emailController.clear();
      _nameController.clear();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Email Saved!")));
    } catch (e) {
      debugPrint("Error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(title: const Text("Emergency Emails"), backgroundColor: Colors.transparent),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _supabase.from('emergency_emails').stream(primaryKey: ['id']).eq('user_id', _supabase.auth.currentUser?.id ?? ''),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final item = snapshot.data![index];
              return Card(
                color: AppTheme.cardColor,
                child: ListTile(
                  title: Text(item['name'] ?? 'No Name', style: const TextStyle(color: Colors.white)),
                  subtitle: Text(item['email'], style: const TextStyle(color: Colors.white70)),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                    onPressed: () async => await _supabase.from('emergency_emails').delete().eq('id', item['id']),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primaryBlue,
        onPressed: () => _showAddDialog(),
        child: const Icon(Icons.add_email_rounded, color: Colors.white),
      ),
    );
  }

  void _showAddDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.darkBg,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: "Name"), style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 10),
            TextField(controller: _emailController, decoration: const InputDecoration(labelText: "Email"), style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _saveEmail, child: const Text("SAVE")),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}