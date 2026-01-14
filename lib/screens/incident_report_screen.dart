import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/app_theme.dart';

class IncidentReportScreen extends StatefulWidget {
  const IncidentReportScreen({super.key});

  @override
  State<IncidentReportScreen> createState() => _IncidentReportScreenState();
}

class _IncidentReportScreenState extends State<IncidentReportScreen> {
  final _descriptionController = TextEditingController();
  String _selectedType = 'Harassment';
  File? _selectedImage;
  bool _isUploading = false;

  final List<String> _incidentTypes = [
    'Harassment',
    'Physical Threat',
    'Theft',
    'Suspicious Activity',
    'Other'
  ];

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _submitReport() async {
    if (_descriptionController.text.isEmpty) {
      _showSnackBar("Please write a description", Colors.orange);
      return;
    }

    setState(() => _isUploading = true);
    final user = FirebaseAuth.instance.currentUser;

    try {
      await FirebaseFirestore.instance.collection('reports').add({
        'userId': user?.uid,
        'userName': user?.displayName ?? "Anonymous",
        'type': _selectedType,
        'description': _descriptionController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
        'hasImage': _selectedImage != null,
      });

      _descriptionController.clear();
      setState(() => _selectedImage = null);
      _showSnackBar("Report Submitted Successfully!", Colors.green);
    } catch (e) {
      _showSnackBar("Error: ${e.toString()}", Colors.red);
    } finally {
      setState(() => _isUploading = false);
    }
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg, // ডার্ক ব্যাকগ্রাউন্ড
      appBar: AppBar(
        title: const Text("Report Incident", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Report an Incident",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            Text(
              "Your safety is our priority. Please provide details.", 
              style: TextStyle(color: Colors.white.withOpacity(0.5))
            ),
            const SizedBox(height: 30),

            // Incident Type Dropdown
            _buildLabel("Select Incident Type"),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.circular(15),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedType,
                  isExpanded: true,
                  dropdownColor: AppTheme.cardColor, // ড্রপডাউন মেনু ডার্ক করা
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  items: _incidentTypes.map((type) => DropdownMenuItem(
                    value: type, 
                    child: Text(type)
                  )).toList(),
                  onChanged: (val) => setState(() => _selectedType = val!),
                ),
              ),
            ),

            const SizedBox(height: 25),

            // Description Box
            _buildLabel("Description"),
            TextField(
              controller: _descriptionController,
              maxLines: 5,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "What happened? (Location, time, details...)",
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                fillColor: AppTheme.cardColor,
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
              ),
            ),

            const SizedBox(height: 25),

            // Image Picker Section
            _buildLabel("Evidence (Photo)"),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: double.infinity,
                height: 180,
                decoration: BoxDecoration(
                  color: AppTheme.cardColor,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.white10, width: 1),
                ),
                child: _selectedImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Image.file(_selectedImage!, fit: BoxFit.cover),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo_rounded, size: 50, color: AppTheme.primaryBlue.withOpacity(0.8)),
                          const SizedBox(height: 10),
                          const Text("Tap to upload evidence", style: TextStyle(color: Colors.white54)),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 40),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 5,
                  shadowColor: AppTheme.primaryBlue.withOpacity(0.3),
                ),
                onPressed: _isUploading ? null : _submitReport,
                child: _isUploading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("SUBMIT REPORT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1)),
              ),
            ),
            const SizedBox(height: 100), // Navbar space
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.primaryBlue)),
    );
  }
}