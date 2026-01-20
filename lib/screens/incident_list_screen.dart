import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'incident_report_screen.dart';
import '../core/app_theme.dart';

class IncidentListScreen extends StatefulWidget {
  const IncidentListScreen({super.key});

  @override
  State<IncidentListScreen> createState() => _IncidentListScreenState();
}

class _IncidentListScreenState extends State<IncidentListScreen> {
  final _supabase = Supabase.instance.client;

  void _showReportDetails(BuildContext context, Map<String, dynamic> report) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(color: AppTheme.darkBg, borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10)))),
              const SizedBox(height: 20),
              if (report['image_url'] != null)
                ClipRRect(borderRadius: BorderRadius.circular(15), child: Image.network(report['image_url'], width: double.infinity, height: 250, fit: BoxFit.cover)),
              const SizedBox(height: 20),
              Text(report['type'].toString().toUpperCase(), style: const TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 15),
              const Text("Description", style: TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold, fontSize: 16)),
              Text(report['description'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.5)),
              const Divider(color: Colors.white10, height: 30),
              if (report['user_email'] != null)
                Text("Reported by: ${report['user_email']}", style: const TextStyle(color: Colors.white54, fontSize: 12)),
              ListTile(leading: const Icon(Icons.location_on, color: Colors.redAccent), title: Text(report['full_address'] ?? "No address", style: const TextStyle(color: Colors.white70)), contentPadding: EdgeInsets.zero),
              const SizedBox(height: 20),
              SizedBox(width: double.infinity, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.white12), onPressed: () => Navigator.pop(context), child: const Text("Close", style: TextStyle(color: Colors.white)))),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(title: const Text("Community Reports"), centerTitle: true, backgroundColor: AppTheme.cardColor),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _supabase.from('reports').stream(primaryKey: ['id']).order('created_at', ascending: false),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final reports = snapshot.data!;
          if (reports.isEmpty) return const Center(child: Text("No reports yet.", style: TextStyle(color: Colors.white54)));

          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final report = reports[index];
              return GestureDetector(
                onTap: () => _showReportDetails(context, report),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 15),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppTheme.cardColor, borderRadius: BorderRadius.circular(18)),
                  child: Row(
                    children: [
                      if (report['image_url'] != null)
                        ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.network(report['image_url'], height: 70, width: 70, fit: BoxFit.cover))
                      else
                        Container(height: 70, width: 70, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.image_not_supported, color: Colors.white24)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(report['type'] ?? '', style: const TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold)),
                            Text(report['description'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                            const SizedBox(height: 5),
                            Text("Road: ${report['road_number'] ?? 'N/A'}", style: const TextStyle(color: Colors.white38, fontSize: 11)),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white24),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primaryBlue,
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const IncidentReportScreen())),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}