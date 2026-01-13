import 'package:flutter/material.dart';
import '../core/app_theme.dart';

class IncidentReportScreen extends StatefulWidget {
  const IncidentReportScreen({super.key});

  @override
  State<IncidentReportScreen> createState() => _IncidentReportScreenState();
}

class _IncidentReportScreenState extends State<IncidentReportScreen> {
  String? _selectedCategory;
  final List<String> _categories = ['Accident', 'Harassment', 'Theft', 'Fire', 'Other'];
  final TextEditingController _descriptionController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Report an Incident", 
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
            const SizedBox(height: 10),
            const Text("Provide details to help authorities and others.", 
              style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 30),

            // Category Selection
            const Text("Select Category", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              children: _categories.map((cat) => ChoiceChip(
                label: Text(cat),
                selected: _selectedCategory == cat,
                selectedColor: AppTheme.primaryBlue.withOpacity(0.2),
                labelStyle: TextStyle(color: _selectedCategory == cat ? AppTheme.primaryBlue : Colors.black),
                onSelected: (selected) => setState(() => _selectedCategory = selected ? cat : null),
              )).toList(),
            ),

            const SizedBox(height: 25),

            // Evidence Upload Placeholder
            const Text("Upload Evidence (Photo/Video)", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () {
                // Image Picker Logic will go here
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Camera/Gallery opening...")));
              },
              child: Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.grey[300]!, style: BorderStyle.solid),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_a_photo_outlined, size: 40, color: AppTheme.primaryBlue),
                    Text("Tap to capture or upload", style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 25),

            // Description
            const Text("Description", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            TextField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: "Describe what happened...",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                fillColor: Color(0xFFF9F9F9),
                filled: true,
              ),
            ),

            const SizedBox(height: 40),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  // Submit Logic
                  _showSuccessDialog();
                },
                child: const Text("Submit Report", 
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Icon(Icons.check_circle, color: Colors.green, size: 60),
        content: const Text("Report submitted successfully! Authorities have been notified.", textAlign: TextAlign.center),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK")),
        ],
      ),
    );
  }
}