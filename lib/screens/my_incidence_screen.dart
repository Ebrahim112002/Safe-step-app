import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../core/app_theme.dart';

class MyIncidenceScreen extends StatefulWidget {
  const MyIncidenceScreen({super.key});

  @override
  State<MyIncidenceScreen> createState() => _MyIncidenceScreenState();
}

class _MyIncidenceScreenState extends State<MyIncidenceScreen> {
  final supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<dynamic> _myReports = [];

  @override
  void initState() {
    super.initState();
    _fetchMyReports();
  }

  Future<void> _fetchMyReports() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final data = await supabase
          .from('reports')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _myReports = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateImage(String reportId) async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    try {
      setState(() => _isLoading = true);
      final file = File(image.path);
      final fileName = 'upd_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path = 'reports/$fileName';

      await supabase.storage.from('report_images').upload(path, file);
      final imageUrl = supabase.storage.from('report_images').getPublicUrl(path);

      await supabase.from('reports').update({'image_url': imageUrl}).eq('id', reportId);
      _fetchMyReports();
    } catch (e) {
      debugPrint("Image Update Error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteReport(String id) async {
    try {
      await supabase.from('reports').delete().eq('id', id);
      setState(() {
        _myReports.removeWhere((item) => item['id'].toString() == id);
      });
    } catch (e) {
      debugPrint("Delete Error: $e");
    }
  }

  void _showEditDialog(Map<String, dynamic> report) {
    final titleController = TextEditingController(text: report['type']);
    final descController = TextEditingController(text: report['description']);
    final roadController = TextEditingController(text: report['road_number']?.toString() ?? "");

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Edit Report", style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildField(titleController, "Type"),
              const SizedBox(height: 15),
              _buildField(descController, "Description", maxLines: 3),
              const SizedBox(height: 15),
              _buildField(roadController, "Road Number"),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue),
            onPressed: () async {
              await supabase.from('reports').update({
                'type': titleController.text,
                'description': descController.text,
                'road_number': roadController.text,
              }).eq('id', report['id']);
              Navigator.pop(context);
              _fetchMyReports();
            },
            child: const Text("Update", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String label, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white38),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(title: const Text("MY REPORTS"), centerTitle: true, elevation: 0, backgroundColor: Colors.transparent),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue))
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _myReports.length,
              itemBuilder: (context, index) => _buildReportCard(_myReports[index]),
            ),
    );
  }

  Widget _buildReportCard(Map<String, dynamic> report) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: AppTheme.cardColor, borderRadius: BorderRadius.circular(25)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              if (report['image_url'] != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.network(report['image_url'], height: 160, width: double.infinity, fit: BoxFit.cover),
                ),
              Positioned(
                right: 8, bottom: 8,
                child: FloatingActionButton.small(
                  backgroundColor: AppTheme.primaryBlue,
                  onPressed: () => _updateImage(report['id'].toString()),
                  child: const Icon(Icons.edit_outlined, color: Colors.white),
                ),
              )
            ],
          ),
          const SizedBox(height: 15),
          Text(report['type'] ?? '', style: const TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 5),
          Text(report['description'] ?? '', style: const TextStyle(color: Colors.white70)),
          const Divider(color: Colors.white10, height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(onPressed: () => _showEditDialog(report), icon: const Icon(Icons.edit, size: 18), label: const Text("Edit")),
              const SizedBox(width: 15),
              TextButton.icon(onPressed: () => _deleteReport(report['id'].toString()), icon: const Icon(Icons.delete, color: Colors.redAccent, size: 18), label: const Text("Delete", style: TextStyle(color: Colors.redAccent))),
            ],
          )
        ],
      ),
    );
  }
}