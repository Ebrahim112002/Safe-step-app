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
  
  // Dummy data for Safety Score
  final double _safetyScore = 8.5;

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
              // 1. Sleek App Bar (Greetings & Emergency Contacts Access)
              SliverAppBar(
                expandedHeight: 120,
                floating: true,
                backgroundColor: AppTheme.darkBg,
                elevation: 0,
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
                    padding: const EdgeInsets.only(top: 20),
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
                      const SizedBox(height: 10),
                      
                      // 2. Safety Status Card
                      _buildSafetyStatusCard(),

                      const SizedBox(height: 35), 
                      
                      // 3. SOS Button
                      _buildSOSButton(),
                      
                      const SizedBox(height: 45),

                      // 4. Quick Actions (Horizontal Sleek Design)
                      _buildSectionTitle("Quick Actions"),
                      const SizedBox(height: 18),
                      _buildQuickActionList(),

                      const SizedBox(height: 35),

                      // 5. Safety Score Section
                      _buildSafetyScoreSection(),

                      const SizedBox(height: 30),

                      // 6. Expert Safety Tip
                      _buildSafetyTipCard(),

                      const SizedBox(height: 40),

                      // 7. Live Incidents List Title
                      _buildSectionTitle("Nearby Live Reports"),
                      const SizedBox(height: 15),
                    ],
                  ),
                ),
              ),

              // 8. Incident Stream
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

  Widget _buildSafetyStatusCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.greenAccent.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.greenAccent.withOpacity(0.2)),
      ),
      child: const Row(
        children: [
          Icon(Icons.verified_user_rounded, color: Colors.greenAccent, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Your environment is Secure", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                Text("Real-time protection is active", style: TextStyle(color: Colors.white38, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSOSButton() {
    return GestureDetector(
      onLongPress: _triggerSOS,
      onLongPressStart: (_) => setState(() => _buttonScale = 0.92),
      onLongPressEnd: (_) => setState(() => _buttonScale = 1.0),
      child: AnimatedScale(
        scale: _buttonScale,
        duration: const Duration(milliseconds: 150),
        child: Container(
          height: 200, width: 200,
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

  Widget _buildQuickActionList() {
    return SizedBox(
      height: 110,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: [
          _buildActionCard(
            Icons.add_location_alt_rounded, 
            "Report", 
            Colors.orangeAccent, 
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const IncidentReportScreen()))
          ),
          _buildActionCard(Icons.map_rounded, "Safe Path", Colors.blueAccent),
          _buildActionCard(Icons.local_police_rounded, "Police", Colors.redAccent),
          _buildActionCard(
            Icons.group_add_rounded, 
            "Contact", 
            Colors.purpleAccent,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const EmergencyContactsScreen()))
          ),
          _buildActionCard(Icons.share_location_rounded, "Track Me", Colors.greenAccent),
        ],
      ),
    );
  }

  Widget _buildActionCard(IconData icon, String label, Color color, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        margin: const EdgeInsets.only(right: 15),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: color.withOpacity(0.1), width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 10),
            Text(
              label, 
              style: TextStyle(
                color: color.withOpacity(0.9), 
                fontSize: 12, 
                fontWeight: FontWeight.bold
              )
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSafetyScoreSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Your Safety Score", style: TextStyle(color: Colors.white70, fontSize: 12)),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text("$_safetyScore", style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                  const Text("/10", style: TextStyle(color: Colors.white24, fontSize: 14)),
                ],
              ),
            ],
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            onPressed: () {},
            child: const Text("Check Up", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
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
              Icon(Icons.lightbulb_outline_rounded, color: Colors.amberAccent, size: 22),
              SizedBox(width: 8),
              Text("Expert Safety Tip", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          SizedBox(height: 12),
          Text(
            "Avoid poorly lit paths even if they are shorter. Always prioritize well-trafficked roads during late hours.",
            style: TextStyle(color: Colors.white54, fontSize: 12, height: 1.6),
          ),
        ],
      ),
    );
  }

  Widget _buildIncidentCard(Map<String, dynamic> report) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor.withOpacity(0.6),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.03)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.1), shape: BoxShape.circle),
            child: const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 20),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(report['type'] ?? "Alert", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                Text(report['description'] ?? "Incident reported nearby", style: const TextStyle(color: Colors.white38, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: Colors.white10),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
    );
  }
}