import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/app_theme.dart';

class IncidentReportScreen extends StatefulWidget {
  const IncidentReportScreen({super.key});

  @override
  State<IncidentReportScreen> createState() => _IncidentReportScreenState();
}

class _IncidentReportScreenState extends State<IncidentReportScreen> {
  final _supabase = Supabase.instance.client;
  final _descriptionController = TextEditingController();
  String _selectedType = 'Harassment';
  XFile? _selectedImage;
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
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (image != null) setState(() => _selectedImage = image);
  }

  Future<void> _submitReport() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    if (_descriptionController.text.isEmpty) {
      _showSnackBar("Please write a description", Colors.orange);
      return;
    }

    setState(() => _isUploading = true);

    try {
      String? imageUrl;

      // 1. Image thakle Supabase Storage-e upload kora
      if (_selectedImage != null) {
        final bytes = await _selectedImage!.readAsBytes();
        final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
        final path = 'incident_reports/$fileName';

        await _supabase.storage.from('reports').uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(contentType: 'image/jpeg'),
        );
        imageUrl = _supabase.storage.from('reports').getPublicUrl(path);
      }

      // 2. Database-e data insert kora
      await _supabase.from('reports').insert({
        'user_id': user.id,
        'type': _selectedType,
        'description': _descriptionController.text.trim(),
        'image_url': imageUrl,
        'created_at': DateTime.now().toIso8601String(),
      });

      _descriptionController.clear();
      setState(() => _selectedImage = null);
      _showSnackBar("Report Submitted Successfully!", Colors.green);
      
    } catch (e) {
      debugPrint("Error: $e");
      _showSnackBar("Error: Submission failed", Colors.red);
    } finally {
      setState(() => _isUploading = false);
    }
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(title: const Text("Report Incident"), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Report an Incident", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 30),
            _buildLabel("Select Incident Type"),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(color: AppTheme.cardColor, borderRadius: BorderRadius.circular(15)),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedType,
                  isExpanded: true,
                  dropdownColor: AppTheme.cardColor,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  items: _incidentTypes.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
                  onChanged: (val) => setState(() => _selectedType = val!),
                ),
              ),
            ),
            const SizedBox(height: 25),
            _buildLabel("Description"),
            TextField(
              controller: _descriptionController,
              maxLines: 4,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "What happened?",
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                fillColor: AppTheme.cardColor,
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 25),
            _buildLabel("Evidence (Photo)"),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: double.infinity, height: 180,
                decoration: BoxDecoration(color: AppTheme.cardColor, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.white10)),
                child: _selectedImage != null
                    ? ClipRRect(borderRadius: BorderRadius.circular(15), child: Image.network(_selectedImage!.path, fit: BoxFit.cover))
                    : const Icon(Icons.add_a_photo_rounded, size: 50, color: AppTheme.primaryBlue),
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity, height: 60,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                onPressed: _isUploading ? null : _submitReport,
                child: _isUploading ? const CircularProgressIndicator(color: Colors.white) : const Text("SUBMIT REPORT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(padding: const EdgeInsets.only(left: 4, bottom: 10), child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)));
  }
}