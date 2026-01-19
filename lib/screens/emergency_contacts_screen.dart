import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/app_theme.dart';

class EmergencyContactsScreen extends StatefulWidget {
  const EmergencyContactsScreen({super.key});

  @override
  State<EmergencyContactsScreen> createState() => _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen> {
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLoading = false;
  
  // Supabase Client
  final _supabase = Supabase.instance.client;

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  // Contact Save Function
  Future<void> _saveContact() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    if (_nameController.text.isEmpty || _phoneController.text.isEmpty) {
      _showSnackBar("Please fill all fields", Colors.orange);
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _supabase.from('emergency_contacts').insert({
        'user_id': user.id,
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
      });
      
      _nameController.clear();
      _phoneController.clear();
      if (mounted) Navigator.pop(context); 
      _showSnackBar("Contact Saved!", Colors.green);
    } catch (e) {
      debugPrint("Error: $e");
      _showSnackBar("Error saving contact", Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color, behavior: SnackBarBehavior.floating),
    );
  }

  // Add Contact Modal
  void _showAddContactModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.darkBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 25, right: 25, top: 30,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Add Emergency Contact", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 25),
            _buildInput(_nameController, "Full Name", Icons.person_outline),
            const SizedBox(height: 15),
            _buildInput(_phoneController, "Phone Number", Icons.phone_outlined, isPhone: true),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                onPressed: _isLoading ? null : _saveContact,
                child: _isLoading 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text("SAVE CONTACT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildInput(TextEditingController ctrl, String label, IconData icon, {bool isPhone = false}) {
    return TextField(
      controller: ctrl,
      keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        prefixIcon: Icon(icon, color: AppTheme.primaryBlue),
        fillColor: AppTheme.cardColor,
        filled: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _supabase.auth.currentUser;

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        title: const Text("Emergency Contacts", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _supabase
            .from('emergency_contacts')
            .stream(primaryKey: ['id'])
            .eq('user_id', user?.id ?? '')
            .order('created_at'),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 999 Default Logic
          List<Map<String, dynamic>> contacts = [];
          contacts.add({
            'id': 'default',
            'name': 'National Emergency',
            'phone': '999',
            'isDefault': true,
          });

          if (snapshot.hasData && snapshot.data != null) {
            contacts.addAll(snapshot.data!);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: contacts.length,
            itemBuilder: (context, index) {
              final contact = contacts[index];
              final bool isDefault = contact['isDefault'] ?? false;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: isDefault ? AppTheme.primaryBlue.withOpacity(0.1) : AppTheme.cardColor, 
                  borderRadius: BorderRadius.circular(15),
                  border: isDefault ? Border.all(color: AppTheme.primaryBlue.withOpacity(0.3)) : null,
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isDefault ? AppTheme.emergencyRed : Colors.white10, 
                    child: Icon(isDefault ? Icons.emergency : Icons.person, color: Colors.white)
                  ),
                  title: Text(contact['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: Text(contact['phone'], style: const TextStyle(color: Colors.white60)),
                  trailing: isDefault 
                    ? const Icon(Icons.lock_outline, color: Colors.white24, size: 20)
                    : IconButton(
                        icon: const Icon(Icons.delete_outline, color: AppTheme.emergencyRed),
                        onPressed: () => _deleteContact(contact['id']),
                      ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primaryBlue,
        onPressed: _showAddContactModal,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _deleteContact(dynamic id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Delete Contact?", style: TextStyle(color: Colors.white)),
        content: const Text("Are you sure you want to remove this contact?", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () async { 
              await _supabase.from('emergency_contacts').delete().eq('id', id);
              if (mounted) Navigator.pop(context); 
            }, 
            child: const Text("Delete", style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    );
  }
}