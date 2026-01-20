import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/app_theme.dart';

class EmergencyEmailsScreen extends StatefulWidget {
  const EmergencyEmailsScreen({super.key});

  @override
  State<EmergencyEmailsScreen> createState() => _EmergencyEmailsScreenState();
}

class _EmergencyEmailsScreenState extends State<EmergencyEmailsScreen> {
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController(); // ইমেইল কন্ট্রোলার
  bool _isLoading = false;
  final _supabase = Supabase.instance.client;

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _saveContact() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    if (_nameController.text.isEmpty || _phoneController.text.isEmpty) {
      _showSnackBar("Please fill Name and Phone", Colors.orange);
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _supabase.from('emergency_contacts').insert({
        'user_id': user.id,
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
      });

      _nameController.clear();
      _phoneController.clear();
      _emailController.clear();
      if (mounted) Navigator.pop(context);
      _showSnackBar("Contact Saved Successfully!", Colors.green);
    } catch (e) {
      _showSnackBar("Error: $e", Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(msg),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating),
    );
  }

  void _showAddContactModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.darkBg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 25,
            right: 25,
            top: 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Add Emergency Contact",
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            const SizedBox(height: 25),
            _buildInput(_nameController, "Full Name", Icons.person_outline),
            const SizedBox(height: 15),
            _buildInput(_phoneController, "Phone Number", Icons.phone_outlined,
                isPhone: true),
            const SizedBox(height: 15),
            _buildInput(
                _emailController, "Email (Optional)", Icons.email_outlined),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15))),
                onPressed: _isLoading ? null : _saveContact,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("SAVE CONTACT",
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildInput(TextEditingController ctrl, String label, IconData icon,
      {bool isPhone = false}) {
    return TextField(
      controller: ctrl,
      keyboardType: isPhone ? TextInputType.phone : TextInputType.emailAddress,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        prefixIcon: Icon(icon, color: AppTheme.primaryBlue),
        fillColor: AppTheme.cardColor,
        filled: true,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _supabase.auth.currentUser;
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
          title: const Text("Emergency Contacts"),
          centerTitle: true,
          backgroundColor: Colors.transparent),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _supabase
            .from('emergency_contacts')
            .stream(primaryKey: ['id'])
            .eq('user_id', user?.id ?? '')
            .order('created_at'),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          List<Map<String, dynamic>> contacts = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: contacts.length,
            itemBuilder: (context, index) {
              final contact = contacts[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                    color: AppTheme.cardColor,
                    borderRadius: BorderRadius.circular(15)),
                child: ListTile(
                  leading: const CircleAvatar(
                      backgroundColor: Colors.white10,
                      child: Icon(Icons.person, color: Colors.white)),
                  title: Text(contact['name'],
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: Text(
                      "${contact['phone']}\n${contact['email'] ?? ''}",
                      style:
                          const TextStyle(color: Colors.white60, fontSize: 12)),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline,
                        color: AppTheme.emergencyRed),
                    onPressed: () async => await _supabase
                        .from('emergency_contacts')
                        .delete()
                        .eq('id', contact['id']),
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
          child: const Icon(Icons.add, color: Colors.white)),
    );
  }
}
