import 'package:flutter/material.dart';
import '../core/app_theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // প্রোফাইল হেডার
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              decoration: const BoxDecoration(
                color: AppTheme.primaryBlue,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, size: 60, color: AppTheme.primaryBlue),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    "User Name", // ইউজারের নাম
                    style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    "Verified Citizen",
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // সেফটি টিপস সেকশন (SRS FR-4.1)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Daily Safety Tips", 
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
                  const SizedBox(height: 15),
                  _buildSafetyTipCard(
                    context,
                    "Avoid Isolated Areas",
                    "Try to stay in well-lit areas during night travel.",
                    Icons.lightbulb_outline,
                  ),
                  _buildSafetyTipCard(
                    context,
                    "Keep Contacts Updated",
                    "Ensure your emergency contacts are always reachable.",
                    Icons.security,
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // সেটিংস অপশন
                  const Text("Account Settings", 
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
                  const SizedBox(height: 10),
                  _buildSettingsTile(Icons.notifications_active_outlined, "Notifications"),
                  _buildSettingsTile(Icons.lock_outline, "Privacy Policy"),
                  _buildSettingsTile(Icons.help_outline, "Help & Support"),
                  
                  const SizedBox(height: 20),
                  
                  // লগআউট বাটন
                  ListTile(
                    onTap: () {},
                    leading: const Icon(Icons.logout, color: AppTheme.sosRed),
                    title: const Text("Logout", style: TextStyle(color: AppTheme.sosRed, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // সেফটি টিপস কার্ড ডিজাইন
  Widget _buildSafetyTipCard(BuildContext context, String title, String desc, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryBlue, size: 30),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(desc, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // সেটিংস টাইল ডিজাইন
  Widget _buildSettingsTile(IconData icon, String title) {
    return ListTile(
      leading: Icon(icon, color: Colors.black87),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () {},
    );
  }
}