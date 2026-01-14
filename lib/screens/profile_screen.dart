import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../core/app_theme.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final user = FirebaseAuth.instance.currentUser;

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _bloodController = TextEditingController();
  final _dobController = TextEditingController();
  final _genderController = TextEditingController();

  bool _alertSound = true;
  bool _autoShareLocation = false;
  File? _pickedImage;
  bool _isUploadingImage = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
      setState(() => _pickedImage = File(pickedFile.path));
      _uploadProfileImage();
    }
  }

  Future<void> _uploadProfileImage() async {
    if (_pickedImage == null || user == null) return;
    setState(() => _isUploadingImage = true);
    try {
      final storageRef = FirebaseStorage.instance.ref().child('user_profile_images').child('${user!.uid}.jpg');
      await storageRef.putFile(_pickedImage!);
      final imageUrl = await storageRef.getDownloadURL();
      await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({'profileImageUrl': imageUrl});
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile image updated!")));
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to upload image"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  Future<void> _updateProfile() async {
    await FirebaseFirestore.instance.collection('users').doc(user?.uid).update({
      'name': _nameController.text.trim(),
      'phone': _phoneController.text.trim(),
      'address': _addressController.text.trim(),
      'bloodGroup': _bloodController.text.trim(),
      'dob': _dobController.text.trim(),
      'gender': _genderController.text.trim(),
      'alertSound': _alertSound,
      'autoShareLocation': _autoShareLocation,
    });
    if (mounted) Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile Updated!")));
  }

  void _showEditModal(Map<String, dynamic> data) {
    _nameController.text = data['name'] ?? '';
    _phoneController.text = data['phone'] ?? '';
    _addressController.text = data['address'] ?? '';
    _bloodController.text = data['bloodGroup'] ?? '';
    _dobController.text = data['dob'] ?? '';
    _genderController.text = data['gender'] ?? '';
    _alertSound = data['alertSound'] ?? true;
    _autoShareLocation = data['autoShareLocation'] ?? false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: const BoxDecoration(color: AppTheme.cardColor, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10))),
                const SizedBox(height: 20),
                const Text("Edit Profile", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 20),
                _buildEditField(_nameController, "Full Name", Icons.person),
                _buildEditField(_phoneController, "Mobile", Icons.phone, type: TextInputType.phone),
                _buildEditField(_dobController, "DOB", Icons.cake),
                _buildEditField(_genderController, "Gender", Icons.face),
                _buildEditField(_addressController, "Address", Icons.home),
                _buildEditField(_bloodController, "Blood Group", Icons.bloodtype),
                SwitchListTile(
                  title: const Text("Alert Sound", style: TextStyle(color: Colors.white)),
                  value: _alertSound,
                  activeColor: AppTheme.primaryBlue,
                  onChanged: (val) => setModalState(() => _alertSound = val),
                ),
                SwitchListTile(
                  title: const Text("Auto Location Share", style: TextStyle(color: Colors.white)),
                  value: _autoShareLocation,
                  activeColor: AppTheme.primaryBlue,
                  onChanged: (val) => setModalState(() => _autoShareLocation = val),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity, height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                    onPressed: _updateProfile,
                    child: const Text("SAVE CHANGES", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        title: const Text("My Safety Profile", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (c) => const LoginScreen()), (r) => false);
            },
            icon: const Icon(Icons.logout, color: AppTheme.emergencyRed),
          )
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          var data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
          String? profileImageUrl = data['profileImageUrl'];

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              children: [
                Center(
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _pickImage,
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(color: AppTheme.primaryBlue, shape: BoxShape.circle),
                              child: CircleAvatar(
                                radius: 55,
                                backgroundColor: AppTheme.cardColor,
                                backgroundImage: profileImageUrl != null ? NetworkImage(profileImageUrl) : null,
                                child: profileImageUrl == null && !_isUploadingImage ? const Icon(Icons.person, size: 60, color: Colors.white24) : null,
                              ),
                            ),
                            if (_isUploadingImage) const Positioned.fill(child: CircularProgressIndicator(strokeWidth: 3)),
                            if (!_isUploadingImage)
                              CircleAvatar(radius: 18, backgroundColor: AppTheme.primaryBlue, child: const Icon(Icons.camera_alt, size: 18, color: Colors.white)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 15),
                      Text(data['name'] ?? "User", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      Text(data['email'] ?? "", style: TextStyle(color: Colors.white.withOpacity(0.5))),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: () => _showEditModal(data),
                        icon: const Icon(Icons.edit_note, size: 20),
                        label: const Text("EDIT PROFILE"),
                        style: OutlinedButton.styleFrom(foregroundColor: AppTheme.primaryBlue, side: const BorderSide(color: AppTheme.primaryBlue), shape: StadiumBorder()),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                _infoCard([
                  _infoTile(Icons.phone, "Mobile", data['phone'] ?? "Not set"),
                  _infoTile(Icons.cake, "Date of Birth", data['dob'] ?? "Not set"),
                  _infoTile(Icons.face, "Gender", data['gender'] ?? "Not set"),
                ]),
                const SizedBox(height: 20),
                _infoCard([
                  _infoTile(Icons.home, "Home Address", data['address'] ?? "Not set"),
                  _infoTile(Icons.bloodtype, "Blood Group", data['bloodGroup'] ?? "Unknown", color: AppTheme.emergencyRed),
                ]),
                const SizedBox(height: 20),
                _infoCard([
                  _infoTile(Icons.volume_up, "Alert Sound", (data['alertSound'] ?? true) ? "On" : "Off"),
                  _infoTile(Icons.share_location, "Auto Location Share", (data['autoShareLocation'] ?? false) ? "Enabled" : "Disabled"),
                ]),
                const SizedBox(height: 100), // Space for floating navbar
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _infoCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(color: AppTheme.cardColor, borderRadius: BorderRadius.circular(20)),
      child: Column(children: children),
    );
  }

  Widget _infoTile(IconData icon, String title, String value, {Color? color}) {
    return ListTile(
      leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: (color ?? AppTheme.primaryBlue).withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color ?? AppTheme.primaryBlue, size: 20)),
      title: Text(title, style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.5))),
      subtitle: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
    );
  }

  Widget _buildEditField(TextEditingController ctrl, String label, IconData icon, {TextInputType type = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: ctrl,
        keyboardType: type,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label, labelStyle: const TextStyle(color: Colors.white60),
          prefixIcon: Icon(icon, color: AppTheme.primaryBlue),
          filled: true, fillColor: Colors.white10,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
        ),
      ),
    );
  }
}