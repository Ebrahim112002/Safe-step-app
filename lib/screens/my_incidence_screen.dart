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
      debugPrint("Fetch Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- FIXED IMAGE UPDATE (Binary Logic) ---
  Future<void> _updateImage(dynamic reportId) async {
    final picker = ImagePicker();
    final XFile? image =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);

    if (image == null) return;

    try {
      setState(() => _isLoading = true);

      final imageBytes = await image.readAsBytes();
      final fileName = 'upd_${DateTime.now().millisecondsSinceEpoch}.jpg';

      // 1. Storage এ আপলোড
      await supabase.storage.from('reports').uploadBinary(
            fileName,
            imageBytes,
            fileOptions:
                const FileOptions(contentType: 'image/jpeg', upsert: true),
          );

      final imageUrl = supabase.storage.from('reports').getPublicUrl(fileName);

      // 2. Database আপডেট (ID টাইপ ফিক্স করা হয়েছে)
      await supabase
          .from('reports')
          .update({'image_url': imageUrl}).eq('id', reportId);

      _fetchMyReports();
      _showSnackBar("Image updated!", Colors.green);
    } catch (e) {
      debugPrint("Image Update Error: $e");
      _showSnackBar("Update failed: $e", Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- FIXED DELETE LOGIC ---
  Future<void> _deleteReport(dynamic id) async {
    try {
      // সরাসরি ডিলিট কুয়েরি
      await supabase.from('reports').delete().eq('id', id);

      if (mounted) {
        _showSnackBar("Report deleted", Colors.blueGrey);
        _fetchMyReports(); // লিস্ট রিফ্রেশ
      }
    } catch (e) {
      debugPrint("Delete Error: $e");
      _showSnackBar("Delete failed: $e", Colors.red);
    }
  }

  // --- FIXED TEXT UPDATE LOGIC ---
  void _showEditDialog(Map<String, dynamic> report) {
    final typeController = TextEditingController(text: report['type']);
    final descController = TextEditingController(text: report['description']);
    final roadController =
        TextEditingController(text: report['road_number']?.toString() ?? "");

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
              _buildField(typeController, "Type"),
              const SizedBox(height: 15),
              _buildField(descController, "Description", maxLines: 3),
              const SizedBox(height: 15),
              _buildField(roadController, "Road Number"),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text("Cancel", style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue),
            onPressed: () async {
              try {
                await supabase.from('reports').update({
                  'type': typeController.text.trim(),
                  'description': descController.text.trim(),
                  'road_number': roadController.text.trim(),
                }).eq('id', report['id']);

                if (mounted) Navigator.pop(context);
                _fetchMyReports();
                _showSnackBar("Updated successfully!", Colors.green);
              } catch (e) {
                _showSnackBar("Update failed", Colors.red);
              }
            },
            child: const Text("Update", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --- UI Helpers ---

  void _showSnackBar(String msg, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
    }
  }

  Widget _buildField(TextEditingController controller, String label,
      {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white38),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
          title: const Text("MY REPORTS"),
          centerTitle: true,
          backgroundColor: Colors.transparent),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryBlue))
          : _myReports.isEmpty
              ? const Center(
                  child: Text("No reports found",
                      style: TextStyle(color: Colors.white54)))
              : RefreshIndicator(
                  onRefresh: _fetchMyReports,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _myReports.length,
                    itemBuilder: (context, index) =>
                        _buildReportCard(_myReports[index]),
                  ),
                ),
    );
  }

  Widget _buildReportCard(Map<String, dynamic> report) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              if (report['image_url'] != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.network(
                    report['image_url'],
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                        height: 180,
                        color: Colors.white10,
                        child: const Icon(Icons.broken_image,
                            color: Colors.white24)),
                  ),
                ),
              Positioned(
                right: 10,
                bottom: 10,
                child: FloatingActionButton.small(
                  heroTag: "btn_${report['id']}",
                  backgroundColor: AppTheme.primaryBlue,
                  onPressed: () => _updateImage(report['id']),
                  child: const Icon(Icons.camera_alt_outlined,
                      color: Colors.white, size: 20),
                ),
              )
            ],
          ),
          const SizedBox(height: 15),
          Text(report['type'] ?? 'Unknown',
              style: const TextStyle(
                  color: AppTheme.primaryBlue,
                  fontWeight: FontWeight.bold,
                  fontSize: 18)),
          const SizedBox(height: 8),
          Text(report['description'] ?? '',
              style: const TextStyle(color: Colors.white70, fontSize: 14)),
          const Divider(color: Colors.white10, height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () => _showEditDialog(report),
                icon: const Icon(Icons.edit_note),
                label: const Text("Edit"),
              ),
              const SizedBox(width: 10),
              TextButton.icon(
                onPressed: () => _deleteReport(report['id']),
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                label: const Text("Delete",
                    style: TextStyle(color: Colors.redAccent)),
              ),
            ],
          )
        ],
      ),
    );
  }
}
