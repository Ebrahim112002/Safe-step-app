import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Supabase import
import '../core/app_theme.dart';
import 'emergency_contacts_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  double _buttonScale = 1.0;
  
  // 1. Supabase client use korun Firebase bad diye
  final SupabaseClient _supabase = Supabase.instance.client;

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'Good Morning';
    if (hour >= 12 && hour < 17) return 'Good Afternoon';
    if (hour >= 17 && hour < 20) return 'Good Evening';
    return 'Good Night';
  }

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
    // 2. Current User ID fetch kora
    final userId = _supabase.auth.currentUser?.id;

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: const Text("SafeStep", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
        actions: [
          IconButton(
            padding: const EdgeInsets.only(right: 20),
            icon: const Icon(Icons.contact_phone_rounded, color: Colors.white, size: 26),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const EmergencyContactsScreen())),
          ),
        ],
      ),
      // 3. Supabase stream use kora
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _supabase
            .from('profiles')
            .stream(primaryKey: ['id'])
            .eq('id', userId ?? ''),
        builder: (context, snapshot) {
          String userName = "User";

          if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            userName = snapshot.data!.first['name'] ?? "User";
          }

          // Jodi snapshot error hoy ba loading hoy tao jeno UI hang na hoy
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(height: 10),
                // SOS Button
                Center(
                  child: GestureDetector(
                    onLongPressStart: (_) => setState(() => _buttonScale = 0.9),
                    onLongPressEnd: (_) => setState(() => _buttonScale = 1.0),
                    onLongPress: _triggerSOS,
                    child: AnimatedScale(
                      scale: _buttonScale,
                      duration: const Duration(milliseconds: 150),
                      child: Container(
                        height: 180,
                        width: 180,
                        decoration: BoxDecoration(
                          color: AppTheme.emergencyRed,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.emergencyRed.withOpacity(0.3),
                              blurRadius: 40,
                              spreadRadius: 10,
                            )
                          ],
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.warning_amber_rounded, color: Colors.white, size: 65),
                            SizedBox(height: 5),
                            Text("HOLD SOS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 35),

                // Live Greetings
                Column(
                  children: [
                    Text(
                      "${_getGreeting()}, $userName", 
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle, color: Colors.greenAccent, size: 16),
                        SizedBox(width: 5),
                        Text("Safe Route Status: Active", 
                          style: TextStyle(color: Colors.greenAccent, fontSize: 14, fontWeight: FontWeight.w500)
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 40),

                // Cards
                Row(
                  children: [
                    _buildSquareCard("Safe Route", Icons.map_rounded, AppTheme.primaryBlue),
                    const SizedBox(width: 15),
                    _buildSquareCard("Safety Heatmap", Icons.grain, AppTheme.accentPurple),
                  ],
                ),
                const SizedBox(height: 25),
                _buildAssessmentCard(),
              ],
            ),
          );
        },
      ),
    );
  }

  // Card widgets (Apnar code e ja chilo tai thakbe...)
  Widget _buildSquareCard(String title, IconData icon, Color color) {
    return Expanded(
      child: Container(
        height: 140,
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 40),
            const SizedBox(height: 12),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _buildAssessmentCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: const Row(
        children: [
          Icon(Icons.analytics_outlined, color: AppTheme.primaryBlue),
          SizedBox(width: 15),
          Expanded(
            child: Text(
              "Current Safety Score: 8.5/10. Surroundings are stable.",
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}