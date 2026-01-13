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

  // Image Pick korar function
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  // Report Submit korar function
  Future<void> _submitReport() async {
    if (_descriptionController.text.isEmpty) {
      _showSnackBar("Please write a description", Colors.orange);
      return;
    }

    setState(() => _isUploading = true);
    final user = FirebaseAuth.instance.currentUser;

    try {
      // Note: Image Firebase Storage-e upload korar jonno firebase_storage package lage. 
      // Ekhon amra sudhu database entry korchi.
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
      backgroundColor: const Color(0xFFF8F9FA),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Report an Incident",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
            ),
            const Text("Your safety is our priority. Please provide details.", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 25),

            // Incident Type Dropdown
            _buildLabel("Select Incident Type"),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedType,
                  isExpanded: true,
                  items: _incidentTypes.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
                  onChanged: (val) => setState(() => _selectedType = val!),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Description Box
            _buildLabel("Description"),
            TextField(
              controller: _descriptionController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: "What happened? (Location, time, details...)",
                fillColor: Colors.white,
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),

            const SizedBox(height: 20),

            // Image Picker Section
            _buildLabel("Evidence (Photo)"),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: double.infinity,
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!, style: BorderStyle.solid),
                ),
                child: _selectedImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(_selectedImage!, fit: BoxFit.cover),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.add_a_photo_outlined, size: 40, color: AppTheme.primaryBlue),
                          SizedBox(height: 8),
                          Text("Click to add image", style: TextStyle(color: AppTheme.primaryBlue)),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 30),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: _isUploading ? null : _submitReport,
                child: _isUploading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("SUBMIT REPORT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
    );
  }
}