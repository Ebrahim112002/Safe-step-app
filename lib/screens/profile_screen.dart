import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/app_theme.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _supabase = Supabase.instance.client;
  bool _isEditing = false;
  bool _isUploading = false;

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _bloodController = TextEditingController();
  String? _selectedGender;
  String? _imageUrl;

  final List<String> _genders = ['Male', 'Female', 'Other'];

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _bloodController.dispose();
    super.dispose();
  }

  // --- FIXED IMAGE PICK & UPLOAD ---
  Future<void> _pickAndUploadImage() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
    );

    if (image == null) return;

    setState(() => _isUploading = true);

    try {
      final imageBytes = await image.readAsBytes();
      // Web-e path logic problematic, tai direct unique name create korchi
      final fileName = '${user.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      // 1. Supabase Storage-e upload (ContentType fix kora hoyeche)
      await _supabase.storage.from('avatars').uploadBinary(
            fileName,
            imageBytes,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg', // Manual set korle ar media error ashbe na
              upsert: true,
            ),
          );

      // 2. Public URL ber kora
      final String publicUrl = _supabase.storage.from('avatars').getPublicUrl(fileName);

      // 3. Profiles table e image URL update kora
      await _supabase.from('profiles').update({
        'profile_image_url': publicUrl,
      }).eq('id', user.id);

      setState(() {
        _imageUrl = publicUrl;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile picture updated!")),
        );
      }
    } catch (e) {
      debugPrint("Upload Error Detail: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Upload failed: $e")),
        );
      }
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _updateProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      await _supabase.from('profiles').upsert({
        'id': user.id,
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'blood_group': _bloodController.text.trim(),
        'gender': _selectedGender,
        'updated_at': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        setState(() => _isEditing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile Updated Successfully!")),
        );
      }
    } catch (e) {
      debugPrint("Update Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _supabase.auth.currentUser;

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        title: const Text("My Profile", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.save : Icons.edit, color: AppTheme.primaryBlue),
            onPressed: () {
              if (_isEditing) {
                _updateProfile();
              } else {
                setState(() => _isEditing = true);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: () async {
              await _supabase.auth.signOut();
              if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => const LoginScreen()));
            },
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _supabase.from('profiles').stream(primaryKey: ['id']).eq('id', user?.id ?? ''),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !_isEditing) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text("No Profile Found"));

          final userData = snapshot.data!.first;

          // Editing thakle controller data overwrite korbo na
          if (!_isEditing) {
            _nameController.text = userData['name'] ?? '';
            _phoneController.text = userData['phone'] ?? '';
            _addressController.text = userData['address'] ?? '';
            _bloodController.text = userData['blood_group'] ?? '';
            _selectedGender = userData['gender'];
            _imageUrl = userData['profile_image_url'];
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // --- IMAGE SECTION WITH CACHE BREAKER ---
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: AppTheme.cardColor,
                        // Timestamp add kora hoyeche jate image sathe sathe refresh hoy
                        backgroundImage: (_imageUrl != null && _imageUrl!.isNotEmpty)
                            ? NetworkImage('$_imageUrl?t=${DateTime.now().millisecondsSinceEpoch}')
                            : null,
                        child: (_imageUrl == null || _imageUrl!.isEmpty)
                            ? const Icon(Icons.person, size: 70, color: Colors.white24)
                            : null,
                      ),
                      if (_isEditing)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _isUploading ? null : _pickAndUploadImage,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(color: AppTheme.primaryBlue, shape: BoxShape.circle),
                              child: _isUploading
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : const Icon(Icons.camera_alt, size: 20, color: Colors.white),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(userData['email'] ?? '', style: const TextStyle(color: Colors.white54)),
                const SizedBox(height: 30),
                
                _buildInfoField("Full Name", _nameController, Icons.person_outline),
                _buildInfoField("Phone Number", _phoneController, Icons.phone_outlined),
                _buildGenderDropdown(),
                _buildInfoField("Address", _addressController, Icons.location_on_outlined),
                _buildInfoField("Blood Group", _bloodController, Icons.bloodtype_outlined),
                
                const SizedBox(height: 40),
                if (_isEditing)
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      onPressed: _updateProfile,
                      child: const Text("Save Changes", style: TextStyle(color: Colors.white, fontSize: 16)),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildGenderDropdown() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      decoration: BoxDecoration(color: AppTheme.cardColor, borderRadius: BorderRadius.circular(15)),
      child: Row(
        children: [
          const Icon(Icons.wc_outlined, color: AppTheme.primaryBlue),
          const SizedBox(width: 15),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedGender,
                hint: const Text("Select Gender", style: TextStyle(color: Colors.white54, fontSize: 14)),
                dropdownColor: AppTheme.cardColor,
                items: _genders.map((String v) => DropdownMenuItem(value: v, child: Text(v, style: const TextStyle(color: Colors.white)))).toList(),
                onChanged: _isEditing ? (v) => setState(() => _selectedGender = v) : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoField(String label, TextEditingController controller, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: AppTheme.cardColor, borderRadius: BorderRadius.circular(15)),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryBlue),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                TextField(
                  controller: controller,
                  enabled: _isEditing,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.only(top: 5)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}