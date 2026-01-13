import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart'; // Image Picker
import 'package:firebase_storage/firebase_storage.dart'; // Firebase Storage
import '../core/app_theme.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final user = FirebaseAuth.instance.currentUser;

  // Controllers for Editing
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _bloodController = TextEditingController();
  final _dobController = TextEditingController();
  final _genderController = TextEditingController();

  // Safety Preferences (Local State for UI toggle)
  bool _alertSound = true;
  bool _autoShareLocation = false;
  
  File? _pickedImage; // প্রোফাইল ইমেজ ফাইল
  bool _isUploadingImage = false; // ইমেজ আপলোড স্টেট

  // Image Pick করার ফাংশন
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);

    if (pickedFile != null) {
      setState(() {
        _pickedImage = File(pickedFile.path);
      });
      _uploadProfileImage(); // ইমেজ পিক হওয়ার সাথে সাথে আপলোড
    }
  }

  // প্রোফাইল ইমেজ আপলোড করার ফাংশন
  Future<void> _uploadProfileImage() async {
    if (_pickedImage == null || user == null) return;

    setState(() => _isUploadingImage = true);
    try {
      final storageRef = FirebaseStorage.instance.ref().child('user_profile_images').child('${user!.uid}.jpg');
      await storageRef.putFile(_pickedImage!);
      final imageUrl = await storageRef.getDownloadURL();

      // Firestore-এ ইমেজ URL সেভ করা
      await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({
        'profileImageUrl': imageUrl,
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile image updated!")));
    } catch (e) {
      debugPrint("Error uploading image: $e");
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to upload image"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  // ডাটা আপডেট করার ফাংশন
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
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Safety Profile Updated!")));
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
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Edit Safety Profile", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                _buildEditField(_nameController, "Full Name", Icons.person),
                _buildEditField(_phoneController, "Mobile Number", Icons.phone, type: TextInputType.phone),
                _buildEditField(_dobController, "Date of Birth (DD/MM/YYYY)", Icons.cake),
                _buildEditField(_genderController, "Gender", Icons.face),
                _buildEditField(_addressController, "Home Address", Icons.home),
                _buildEditField(_bloodController, "Blood Group", Icons.bloodtype),
                const Divider(),
                SwitchListTile(
                  title: const Text("Alert Sound"),
                  value: _alertSound,
                  onChanged: (val) => setModalState(() => _alertSound = val),
                ),
                SwitchListTile(
                  title: const Text("Auto Location Share"),
                  value: _autoShareLocation,
                  onChanged: (val) => setModalState(() => _autoShareLocation = val),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue),
                    onPressed: _updateProfile,
                    child: const Text("Save All Details", style: TextStyle(color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 20),
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
      backgroundColor: const Color(0xFFF4F7FA),
      appBar: AppBar(
        title: const Text("My Safety Profile", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (c) => const LoginScreen()), (r) => false);
            },
            icon: const Icon(Icons.logout, color: Colors.red),
          )
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          var data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
          String? profileImageUrl = data['profileImageUrl']; // ইমেজ URL

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User Header
                Center(
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _pickImage, // ক্লিক করলে ইমেজ পিক হবে
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
                              backgroundImage: profileImageUrl != null ? NetworkImage(profileImageUrl) : null,
                              child: profileImageUrl == null && !_isUploadingImage
                                  ? const Icon(Icons.person, size: 50, color: AppTheme.primaryBlue)
                                  : null,
                            ),
                            if (_isUploadingImage)
                              const Positioned.fill(
                                child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue)),
                              ),
                            if (!_isUploadingImage) // আপলোডিং না থাকলে এডিট আইকন দেখাবে
                              Positioned(
                                right: 0, bottom: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(color: AppTheme.primaryBlue, shape: BoxShape.circle),
                                  child: const Icon(Icons.edit, size: 16, color: Colors.white),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(data['name'] ?? "User Name", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      Text(data['email'] ?? "", style: const TextStyle(color: Colors.grey)),
                      TextButton.icon(onPressed: () => _showEditModal(data), icon: const Icon(Icons.edit), label: const Text("Update Details")),
                    ],
                  ),
                ),
                const SizedBox(height: 25),

                _sectionHeader("PERSONAL & CONTACT"),
                _infoCard([
                  _infoTile(Icons.phone, "Mobile", data['phone'] ?? "Not set"),
                  _infoTile(Icons.cake, "Date of Birth", data['dob'] ?? "Not set"),
                  _infoTile(Icons.face, "Gender", data['gender'] ?? "Not set"),
                ]),

                _sectionHeader("LOCATION INFO"),
                _infoCard([
                  _infoTile(Icons.home, "Home Address", data['address'] ?? "Not set"),
                  _infoTile(Icons.map, "Frequent Routes", "Not set (Auto-Detect)", color: Colors.blueGrey),
                ]),

                _sectionHeader("MEDICAL / HEALTH INFO"),
                _infoCard([
                  _infoTile(Icons.bloodtype, "Blood Group", data['bloodGroup'] ?? "Unknown", color: Colors.red),
                ]),

                _sectionHeader("SAFETY PREFERENCES"),
                _infoCard([
                  _infoTile(Icons.volume_up, "Alert Sound", (data['alertSound'] ?? true) ? "On" : "Off"),
                  _infoTile(Icons.share_location, "Auto Location Share", (data['autoShareLocation'] ?? false) ? "Enabled" : "Disabled"),
                  _infoTile(Icons.timer, "Check-in Timer", "30 Minutes (Not Implemented)", color: Colors.amber),
                ]),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      child: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.blueGrey, letterSpacing: 1)),
    );
  }

  Widget _infoCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)]),
      child: Column(children: children),
    );
  }

  Widget _infoTile(IconData icon, String title, String value, {Color? color}) {
    return ListTile(
      leading: Icon(icon, color: color ?? AppTheme.primaryBlue),
      title: Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      subtitle: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
    );
  }

  Widget _buildEditField(TextEditingController ctrl, String label, IconData icon, {TextInputType type = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(controller: ctrl, keyboardType: type, decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
    );
  }
}