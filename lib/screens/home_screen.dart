import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/app_theme.dart';
import 'emergency_contacts_screen.dart';
import 'incident_report_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  double _buttonScale = 1.0;
  final SupabaseClient _supabase = Supabase.instance.client;

  void _triggerSOS() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("🚨 SOS ALERT ACTIVATED!"),
        backgroundColor: AppTheme.emergencyRed,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = _supabase.auth.currentUser?.id;

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _supabase.from('profiles').stream(primaryKey: ['id']).eq('id', userId ?? ''),
        builder: (context, snapshot) {
          String userName = "Ayaan";
          if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            userName = snapshot.data!.first['name'] ?? "User";
          }

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // 1. Sleek App Bar with Greetings & Fixed Spacing
              SliverAppBar(
                expandedHeight: 120,
                floating: true,
                backgroundColor: AppTheme.darkBg,
                elevation: 0,
                // Left Side Contact Access
                leading: Padding(
                  padding: const EdgeInsets.only(top: 10, left: 10),
                  child: IconButton(
                    icon: const Icon(Icons.contact_emergency_rounded, color: AppTheme.primaryBlue, size: 30),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const EmergencyContactsScreen())),
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  centerTitle: false,
                  title: Padding(
                    padding: const EdgeInsets.only(top: 20), // Left button er niche space thik korar jonno
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Hi $userName! 👋", 
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        const Text("Stay safe today", style: TextStyle(color: Colors.white38, fontSize: 10)),
                      ],
                    ),
                  ),
                ),
                actions: [
                  // Notification icon shoriye ekhane Profile/Manage icon dilam
                  Padding(
                    padding: const EdgeInsets.only(top: 10, right: 10),
                    child: IconButton(
                      icon: const Icon(Icons.account_circle_outlined, color: Colors.white70, size: 28),
                      onPressed: () {},
                    ),
                  ),
                ],
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  child: Column(
                    children: [
                      const SizedBox(height: 30), // Spacious look
                      
                      // 2. SOS Button
                      _buildSOSButton(),
                      
                      const SizedBox(height: 50),

                      // 3. Quick Actions (Bigger Buttons)
                      _buildSectionTitle("Quick Actions"),
                      const SizedBox(height: 20),
                      _buildQuickActionGrid(),

                      const SizedBox(height: 40),

                      // 4. Expert Safety Tip (Tumi cheyecho ami jeno dei)
                      _buildSafetyTipCard(),

                      const SizedBox(height: 40),

                      // 5. Live Incidents List
                      _buildSectionTitle("Nearby Live Reports"),
                      const SizedBox(height: 15),
                    ],
                  ),
                ),
              ),

              // 6. Incident Stream
              StreamBuilder<List<Map<String, dynamic>>>(
                stream: _supabase.from('reports').stream(primaryKey: ['id']).order('created_at'),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Text("No incidents reported nearby.", style: TextStyle(color: Colors.white24, fontSize: 12)),
                        ),
                      ),
                    );
                  }
                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _buildIncidentCard(snapshot.data![index]),
                        childCount: snapshot.data!.length,
                      ),
                    ),
                  );
                },
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          );
        },
      ),
    );
  }

  // --- UI Components ---

  Widget _buildSOSButton() {
    return GestureDetector(
      onLongPress: _triggerSOS,
      onLongPressStart: (_) => setState(() => _buttonScale = 0.92),
      onLongPressEnd: (_) => setState(() => _buttonScale = 1.0),
      child: AnimatedScale(
        scale: _buttonScale,
        duration: const Duration(milliseconds: 150),
        child: Container(
          height: 200, width: 200, // Size increased
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.emergencyRed,
            boxShadow: [
              BoxShadow(
                color: AppTheme.emergencyRed.withOpacity(0.35), 
                blurRadius: 50, 
                spreadRadius: 10
              ),
            ],
            gradient: const LinearGradient(
              colors: [AppTheme.emergencyRed, Color(0xFFD32F2F)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.gpp_maybe_rounded, color: Colors.white, size: 50),
                SizedBox(height: 8),
                Text("SOS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 36, letterSpacing: 1.5)),
                Text("Hold to Alert", style: TextStyle(color: Colors.white70, fontSize: 11)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionGrid() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildActionIcon(Icons.add_location_alt_rounded, "Report", Colors.orangeAccent, onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const IncidentReportScreen()));
        }),
        _buildActionIcon(Icons.group_add_rounded, "Contacts", Colors.greenAccent, isSpecial: true, onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const EmergencyContactsScreen()));
        }),
        _buildActionIcon(Icons.near_me_rounded, "Safe Path", Colors.blueAccent),
        _buildActionIcon(Icons.shield_rounded, "Protection", Colors.purpleAccent),
      ],
    );
  }

  Widget _buildActionIcon(IconData icon, String label, Color color, {VoidCallback? onTap, bool isSpecial = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18), // Button size increased
            decoration: BoxDecoration(
              color: isSpecial ? color.withOpacity(0.12) : AppTheme.cardColor,
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: isSpecial ? color.withOpacity(0.4) : Colors.white.withOpacity(0.06)),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 10),
          Text(label, style: TextStyle(color: isSpecial ? color : Colors.white70, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildSafetyTipCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.2)),
        gradient: LinearGradient(
          colors: [AppTheme.cardColor, AppTheme.primaryBlue.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_circle_rounded, color: Colors.amberAccent, size: 26),
              SizedBox(width: 10),
              Text("Expert Safety Tip", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
            ],
          ),
          SizedBox(height: 12),
          Text(
            "When walking alone at night, avoid using headphones. Staying alert to your surroundings is your first line of defense.",
            style: TextStyle(color: Colors.white54, fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildIncidentCard(Map<String, dynamic> report) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.cardColor.withOpacity(0.8),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.1), shape: BoxShape.circle),
            child: const Icon(Icons.warning_rounded, color: Colors.redAccent, size: 22),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(report['type'] ?? "Alert", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 4),
                Text(report['description'] ?? "Incident reported nearby", style: const TextStyle(color: Colors.white38, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white10, size: 16),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
    );
  }
}