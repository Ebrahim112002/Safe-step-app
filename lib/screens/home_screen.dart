import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import 'emergency_contacts_screen.dart';
import 'incident_report_screen.dart';  import 'profile_screen.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _floatingController;
  late Animation<double> _floatingAnimation;

  @override
  void initState() {
    super.initState();
    // SOS বাটনের হালকা ফ্লোটিং এনিমেশন
    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _floatingAnimation = Tween<double>(begin: 0, end: 12).animate(
      CurvedAnimation(parent: _floatingController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _floatingController.dispose();
    super.dispose();
  }

  // Bottom Navigation এর জন্য পেজ লিস্ট
  final List<Widget> _pages = [
    const SafetyMainWidget(), // Safety/Map Page
    const IncidentReportScreen(), // Report Page
    const ProfileScreen(),
    const Center(child: Text("Safety Tips & Profile (Coming Soon)")), // Profile Page
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("SafeStep", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: false,
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.primaryBlue,
        elevation: 0.5,
        actions: [
          // Emergency Contacts এ যাওয়ার বাটন
          Container(
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.group_add_rounded, color: AppTheme.primaryBlue),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const EmergencyContactsScreen()),
              ),
            ),
          ),
        ],
      ),
      // IndexedStack ব্যবহারের ফলে পেজ সুইচ করলেও ডেটা হারাবে না
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: AppTheme.primaryBlue,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.security_rounded),
            label: 'Safety',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.report_gmailerrorred_rounded),
            label: 'Report',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// এটি হলো মেইন সেফটি পেজ (Map + SOS)
class SafetyMainWidget extends StatelessWidget {
  const SafetyMainWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // আগের এনিমেশন লজিকটি এখানে ব্যবহার করা হয়েছে
    final state = context.findAncestorStateOfType<_HomeScreenState>()!;
    
    return Stack(
      children: [
        // ম্যাপ প্লেসহোল্ডার
        Container(
          width: double.infinity,
          height: double.infinity,
          color: const Color(0xFFF8F9FA),
          child: Center(
            child: Icon(Icons.map_outlined, size: 100, color: Colors.blueGrey[100]),
          ),
        ),
        
        // ফ্লোটিং SOS বাটন
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 60.0),
            child: AnimatedBuilder(
              animation: state._floatingAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, -state._floatingAnimation.value),
                  child: child,
                );
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "LONG PRESS FOR EMERGENCY",
                    style: TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
                  ),
                  const SizedBox(height: 15),
                  GestureDetector(
                    onLongPress: () => _triggerSOS(context),
                    child: Container(
                      height: 130,
                      width: 130,
                      decoration: BoxDecoration(
                        color: AppTheme.sosRed,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.sosRed.withOpacity(0.3),
                            blurRadius: 25,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          "SOS",
                          style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _triggerSOS(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("SOS Activated!"),
        content: const Text("Emergency contacts are being notified with your live location."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("I AM SAFE", style: TextStyle(color: AppTheme.sosRed, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}