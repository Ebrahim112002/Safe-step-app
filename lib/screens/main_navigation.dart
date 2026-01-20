import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Add this
import 'home_screen.dart';
import 'safety_screen.dart';
import 'incident_list_screen.dart'; 
import 'profile_screen.dart';
import 'my_incidence_screen.dart';
import 'admin_users_screen.dart'; // Assume apni ei file-ta banaben users list-er jonno
import '../core/app_theme.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;
  bool _isAdmin = false; // Admin status check korar jonno

  @override
  void initState() {
    super.initState();
    _checkRole(); // Screen load hobar shomoy role check hobe
  }

  // Supabase theke role check korar function
  Future<void> _checkRole() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final data = await Supabase.instance.client
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .single();
      
      if (mounted) {
        setState(() {
          _isAdmin = data['role'] == 'admin';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Dynamic Screen List: Admin hole 6 ta, na hole 5 ta
    final List<Widget> screens = [
      const HomeScreen(),
      const SafetyScreen(),
      const IncidentListScreen(),
      const MyIncidenceScreen(),
      if (_isAdmin) const AdminUsersScreen(), // Admin hole Users Screen add hobe
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: screens[_selectedIndex],
      bottomNavigationBar: Container(
        padding: const EdgeInsets.only(bottom: 20, left: 10, right: 10),
        decoration: BoxDecoration(color: AppTheme.darkBg),
        child: Container(
          height: 75,
          decoration: BoxDecoration(
            color: const Color(0xFF1D1E33).withOpacity(0.95),
            borderRadius: BorderRadius.circular(35),
            border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(Icons.home_outlined, Icons.home, "Home", 0),
              _navItem(Icons.explore_outlined, Icons.explore, "Track", 1),
              _navItem(Icons.campaign_outlined, Icons.campaign, "Feed", 2),
              _navItem(Icons.assignment_outlined, Icons.assignment, "Reports", 3),
              
              // Dynamic Admin Nav Item
              if (_isAdmin) 
                _navItem(Icons.group_outlined, Icons.group, "Users", 4),
              
              // Profile-er index dynamic hobe (admin hole 5, na hole 4)
              _navItem(Icons.person_outline, Icons.person, "Profile", _isAdmin ? 5 : 4),
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
        onTap: () => setState(() => _selectedIndex = index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? AppTheme.primaryBlue : Colors.white54,
              size: isSelected ? 26 : 22,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white38,
                fontSize: 8,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}