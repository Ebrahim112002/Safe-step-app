import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import 'emergency_contacts_screen.dart';
import 'incident_report_screen.dart';
import 'profile_screen.dart';

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

  @override
  Widget build(BuildContext context) {
    // পেজ লিস্ট এখন build মেথডের ভেতরে যাতে এনিমেশন পাস করা সহজ হয়
    final List<Widget> _pages = [
      SafetyMainWidget(animation: _floatingAnimation), 
      const IncidentReportScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("SafeStep", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.primaryBlue,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.group_add_rounded),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const EmergencyContactsScreen()),
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: AppTheme.primaryBlue,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.security_rounded), label: 'Safety'),
          BottomNavigationBarItem(icon: Icon(Icons.report_gmailerrorred_rounded), label: 'Report'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded), label: 'Profile'),
        ],
      ),
    );
  }
}

class SafetyMainWidget extends StatelessWidget {
  final Animation<double> animation;
  const SafetyMainWidget({super.key, required this.animation});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: double.infinity,
          color: const Color(0xFFF8F9FA),
          child: Center(child: Icon(Icons.map_outlined, size: 100, color: Colors.blueGrey[100])),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 60.0),
            child: AnimatedBuilder(
              animation: animation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, -animation.value),
                  child: child,
                );
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("LONG PRESS FOR EMERGENCY", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  const SizedBox(height: 15),
                  GestureDetector(
                    onLongPress: () => _triggerSOS(context),
                    child: Container(
                      height: 120,
                      width: 120,
                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                      child: const Center(child: Text("SOS", style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold))),
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
      builder: (context) => AlertDialog(
        title: const Text("SOS Activated!"),
        content: const Text("Emergency contacts notified."),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("I AM SAFE"))],
      ),
    );
  }
}