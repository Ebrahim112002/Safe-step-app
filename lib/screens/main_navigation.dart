import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'safety_screen.dart';
import 'incident_report_screen.dart';
import 'profile_screen.dart';
import '../core/app_theme.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  // স্ক্রিন লিস্ট
  final List<Widget> _screens = [
    const HomeScreen(),
    const SafetyScreen(),
    const IncidentReportScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // extendBody: true দিলে বডি নেভিগেশন বারের নিচ পর্যন্ত বিস্তৃত হয়
      extendBody: true, 
      body: Stack(
        children: [
          // বর্তমান স্ক্রিন
          _screens[_selectedIndex],
          
          // নিচের দিকে একটি হালকা গ্রাডিয়েন্ট যাতে নেভিগেশন বারের পেছনের লেখা বোঝা না যায়
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppTheme.darkBg.withOpacity(0.0),
                    AppTheme.darkBg.withOpacity(0.8),
                    AppTheme.darkBg,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        // margin দিয়ে বারটিকে ভাসমান রাখা হয়েছে
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 30),
        height: 70,
        decoration: BoxDecoration(
          color: const Color(0xFF1D1E33).withOpacity(0.95),
          borderRadius: BorderRadius.circular(35),
          border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(35),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(Icons.home_outlined, Icons.home, "Home", 0),
              _navItem(Icons.shield_outlined, Icons.shield, "Safety", 1),
              _navItem(Icons.report_gmailerrorred, Icons.report, "Reports", 2),
              _navItem(Icons.person_outline, Icons.person, "Profile", 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, IconData activeIcon, String label, int index) {
    bool isSelected = _selectedIndex == index;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _selectedIndex = index),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryBlue.withOpacity(0.1) : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSelected ? activeIcon : icon,
                color: isSelected ? AppTheme.primaryBlue : Colors.white60,
                size: 26,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white60,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}