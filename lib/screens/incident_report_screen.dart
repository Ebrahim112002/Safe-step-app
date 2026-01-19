import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlng;
import 'package:geolocator/geolocator.dart';
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
  
  // Controllers for new fields
  final _descriptionController = TextEditingController();
  final _roadController = TextEditingController();
  final _fullAddressController = TextEditingController();
  
  final MapController _mapController = MapController();
  
  String _selectedType = 'Harassment';
  XFile? _selectedImage;
  bool _isUploading = false;
  
  latlng.LatLng _incidentLocation = const latlng.LatLng(23.8103, 90.4125);
  bool _isLocationPinned = false; 

  final List<String> _incidentTypes = [
    'Harassment', 'Physical Threat', 'Theft', 'Suspicious Activity', 'Other'
  ];

  @override
  void initState() {
    super.initState();
    _setInitialLocation();
  }

  Future<void> _setInitialLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _incidentLocation = latlng.LatLng(position.latitude, position.longitude);
        _isLocationPinned = true;
      });
      _mapController.move(_incidentLocation, 15.0);
    } catch (e) {
      debugPrint("Location Error: $e");
    }
  }

  Future<void> _submitReport() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    // Required Field Validation
    if (_descriptionController.text.trim().isEmpty || _fullAddressController.text.trim().isEmpty) {
      _showSnackBar("Description and Full Address are required", Colors.orange);
      return;
    }

    setState(() => _isUploading = true);

    try {
      String? imageUrl;
      if (_selectedImage != null) {
        final bytes = await _selectedImage!.readAsBytes();
        final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
        await _supabase.storage.from('reports').uploadBinary(
          'incident_reports/$fileName',
          bytes,
          fileOptions: const FileOptions(contentType: 'image/jpeg'),
        );
        imageUrl = _supabase.storage.from('reports').getPublicUrl('incident_reports/$fileName');
      }

      // Insert into Supabase including new address fields
      await _supabase.from('reports').insert({
        'user_id': user.id,
        'type': _selectedType,
        'description': _descriptionController.text.trim(),
        'road_number': _roadController.text.trim(),
        'full_address': _fullAddressController.text.trim(),
        'image_url': imageUrl,
        'latitude': _incidentLocation.latitude,
        'longitude': _incidentLocation.longitude,
        'created_at': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        _showSnackBar("Incident Reported Successfully!", Colors.green);
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint("Full Error: $e");
      _showSnackBar("Submission failed. Please check database columns.", Colors.red);
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(title: const Text("Post Detailed Report"), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel("1. Pin Incident Location *"),
            Container(
              height: 200, // Reduced map height
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.3)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _incidentLocation,
                    initialZoom: 15.0,
                    onTap: (tapPos, point) => setState(() => _incidentLocation = point),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                      subdomains: const ['a', 'b', 'c'],
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _incidentLocation,
                          width: 40, height: 40,
                          child: const Icon(Icons.location_on, color: Colors.red, size: 35),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            _buildLabel("2. Road/Area Name (Optional)"),
            _buildTextField(_roadController, "e.g. Road 12, Block C", 1),
            
            const SizedBox(height: 15),
            _buildLabel("3. Full Address Details *"),
            _buildTextField(_fullAddressController, "Enter full address for clarity...", 2),
            
            const SizedBox(height: 15),
            _buildLabel("4. Incident Type *"),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(color: AppTheme.cardColor, borderRadius: BorderRadius.circular(15)),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedType,
                  isExpanded: true,
                  dropdownColor: AppTheme.cardColor,
                  style: const TextStyle(color: Colors.white),
                  items: _incidentTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                  onChanged: (v) => setState(() => _selectedType = v!),
                ),
              ),
            ),
            
            const SizedBox(height: 15),
            _buildLabel("5. Description *"),
            _buildTextField(_descriptionController, "What exactly happened?", 3),
            
            const SizedBox(height: 15),
            _buildLabel("6. Add Evidence (Optional)"),
            GestureDetector(
              onTap: () async {
                final XFile? image = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 50);
                if (image != null) setState(() => _selectedImage = image);
              },
              child: Container(
                width: 100, height: 100, // Smaller image preview
                decoration: BoxDecoration(
                  color: AppTheme.cardColor, 
                  borderRadius: BorderRadius.circular(12), 
                  border: Border.all(color: Colors.white10)
                ),
                child: _selectedImage != null
                    ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(_selectedImage!.path, fit: BoxFit.cover))
                    : const Icon(Icons.add_a_photo, size: 25, color: Colors.white24),
              ),
            ),
            
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity, height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                onPressed: _isUploading ? null : _submitReport,
                child: _isUploading 
                  ? const CircularProgressIndicator(color: Colors.white) 
                  : const Text("SUBMIT REPORT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(padding: const EdgeInsets.only(left: 4, bottom: 6), child: Text(text, style: const TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold, fontSize: 13)));
  }

  Widget _buildTextField(TextEditingController controller, String hint, int lines) {
    return TextField(
      controller: controller,
      maxLines: lines,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
        fillColor: AppTheme.cardColor,
        filled: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }
}