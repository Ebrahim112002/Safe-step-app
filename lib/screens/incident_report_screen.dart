import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlng;
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/app_theme.dart';

class IncidentReportScreen extends StatefulWidget {
  final Map<String, dynamic>? incidentToEdit;
  const IncidentReportScreen({super.key, this.incidentToEdit});

  @override
  State<IncidentReportScreen> createState() => _IncidentReportScreenState();
}

class _IncidentReportScreenState extends State<IncidentReportScreen> {
  final _supabase = Supabase.instance.client;

  // Controllers
  final _descriptionController = TextEditingController();
  final _roadController = TextEditingController();
  final _fullAddressController = TextEditingController();
  final MapController _mapController = MapController();

  // States
  String _selectedType = 'Harassment';
  Uint8List? _imageBytes; // Profile screen logic: Binary data for stability
  String? _existingImageUrl;
  bool _isUploading = false;
  bool _isEditing = false;
  int? _editingId;

  latlng.LatLng _incidentLocation = const latlng.LatLng(23.8103, 90.4125);

  final List<String> _incidentTypes = [
    'Harassment',
    'Physical Threat',
    'Theft',
    'Suspicious Activity',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.incidentToEdit != null) {
      _isEditing = true;
      _loadEditData();
    } else {
      _setInitialLocation();
    }
  }

  void _loadEditData() {
    final incident = widget.incidentToEdit!;
    _editingId = incident['id'];
    _descriptionController.text = incident['description'] ?? '';
    _roadController.text = incident['road_number'] ?? '';
    _fullAddressController.text = incident['full_address'] ?? '';
    _selectedType = incident['type'] ?? 'Harassment';
    _existingImageUrl = incident['image_url'];

    if (incident['latitude'] != null && incident['longitude'] != null) {
      _incidentLocation = latlng.LatLng(incident['latitude'], incident['longitude']);
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _mapController.move(_incidentLocation, 15.0);
      });
    }
  }

  Future<void> _setInitialLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() => _incidentLocation = latlng.LatLng(position.latitude, position.longitude));
        _mapController.move(_incidentLocation, 15.0);
      }
    } catch (e) {
      debugPrint("Location Error: $e");
    }
  }

  // Profile screen logic: Pick image as bytes
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _imageBytes = bytes;
      });
    }
  }

  Future<void> _submitReport() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    if (_descriptionController.text.trim().isEmpty || _fullAddressController.text.trim().isEmpty) {
      _showSnackBar("Required fields missing", Colors.orange);
      return;
    }

    setState(() => _isUploading = true);

    try {
      String? imageUrl = _existingImageUrl;

      // Profile screen er moto upload logic
      if (_imageBytes != null) {
        final fileName = 'report_${user.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        await _supabase.storage.from('reports').uploadBinary(
          fileName,
          _imageBytes!,
          fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
        );
        imageUrl = _supabase.storage.from('reports').getPublicUrl(fileName);
      }

      // Backend Table: 'reports' table structure
      final reportData = {
        'user_id': user.id,
        'type': _selectedType,
        'description': _descriptionController.text.trim(),
        'road_number': _roadController.text.trim(),
        'full_address': _fullAddressController.text.trim(),
        'image_url': imageUrl,
        'latitude': _incidentLocation.latitude,
        'longitude': _incidentLocation.longitude,
      };

      if (_isEditing && _editingId != null) {
        await _supabase.from('reports').update(reportData).eq('id', _editingId!);
      } else {
        reportData['created_at'] = DateTime.now().toIso8601String();
        await _supabase.from('reports').insert(reportData);
      }

      if (mounted) {
        _showSnackBar("Successfully Saved!", Colors.green);
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint("DB Error: $e");
      _showSnackBar("Failed to save. Check your table columns.", Colors.red);
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
      appBar: AppBar(
        title: Text(_isEditing ? "Edit Report" : "Post Detailed Report"),
        centerTitle: true,
        backgroundColor: AppTheme.cardColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel("1. Pin Incident Location *"),
            _buildMapContainer(),
            const SizedBox(height: 20),
            _buildLabel("2. Road/Area (Optional)"),
            _buildTextField(_roadController, "e.g. Road 12", 1),
            const SizedBox(height: 15),
            _buildLabel("3. Full Address Details *"),
            _buildTextField(_fullAddressController, "Enter address...", 2),
            const SizedBox(height: 15),
            _buildLabel("4. Incident Type *"),
            _buildDropdown(),
            const SizedBox(height: 15),
            _buildLabel("5. Description *"),
            _buildTextField(_descriptionController, "What happened?", 3),
            const SizedBox(height: 15),
            _buildLabel("6. Evidence (Optional)"),
            
            // Image Preview logic fixed (using Image.memory for local bytes)
            GestureDetector(
              onTap: _isUploading ? null : _pickImage,
              child: Container(
                width: 100, height: 100,
                decoration: BoxDecoration(
                  color: AppTheme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                ),
                child: _imageBytes != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(_imageBytes!, fit: BoxFit.cover),
                      )
                    : (_existingImageUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(_existingImageUrl!, fit: BoxFit.cover),
                          )
                        : const Icon(Icons.add_a_photo, size: 25, color: Colors.white24)),
              ),
            ),
            
            const SizedBox(height: 30),
            _buildSubmitButton(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // --- UI Components ---

  Widget _buildMapContainer() {
    return Container(
      height: 200,
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
            onTap: (_, point) => setState(() => _incidentLocation = point),
          ),
          children: [
            TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),
            MarkerLayer(markers: [
              Marker(
                point: _incidentLocation,
                width: 40, height: 40,
                child: const Icon(Icons.location_on, color: Colors.red, size: 35),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity, height: 55,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryBlue,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: _isUploading ? null : _submitReport,
        child: _isUploading
            ? const SizedBox(
                height: 20, width: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : Text(
                _isEditing ? "UPDATE REPORT" : "SUBMIT REPORT",
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  Widget _buildLabel(String text) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 6),
        child: Text(text, style: const TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold, fontSize: 13)),
      );

  Widget _buildTextField(TextEditingController ctrl, String hint, int lines) => TextField(
        controller: ctrl,
        maxLines: lines,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white24),
          fillColor: AppTheme.cardColor,
          filled: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        ),
      );

  Widget _buildDropdown() => Container(
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
      );

  @override
  void dispose() {
    _descriptionController.dispose();
    _roadController.dispose();
    _fullAddressController.dispose();
    super.dispose();
  }
}