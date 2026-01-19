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

  final List<Widget> _screens = [
    const HomeScreen(),
    const SafetyScreen(),
    const IncidentReportScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      // 1. extendBody false kora hoyeche jate content Navbar er upore thake
      extendBody: false, 
      
      // 2. Stack bad diye sorasori screen load kora hoyeche
      body: _screens[_selectedIndex],

      // 3. Floating Navbar with its own space
      bottomNavigationBar: Container(
        padding: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
        color: AppTheme.darkBg, // Navbar er pichone solid color jate content upore thake
        child: Container(
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