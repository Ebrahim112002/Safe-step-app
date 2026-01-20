import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../core/app_theme.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final DatabaseService _dbService = DatabaseService();
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    final data = await _dbService.getAllUsers();
    if (mounted) {
      setState(() {
        _users = data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredUsers = _users.where((user) {
      final email = user['email']?.toString().toLowerCase() ?? "";
      final phone = user['phone']?.toString() ?? "";
      return email.contains(_searchQuery.toLowerCase()) || phone.contains(_searchQuery);
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        title: const Text("User Management", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              style: const TextStyle(color: Colors.white),
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: "Search email or phone...",
                hintStyle: const TextStyle(color: Colors.white30),
                prefixIcon: const Icon(Icons.search, color: AppTheme.primaryBlue),
                filled: true,
                fillColor: const Color(0xFF1D1E33),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue)) 
              : ListView.builder(
                  itemCount: filteredUsers.length,
                  itemBuilder: (context, index) {
                    final user = filteredUsers[index];
                    bool isBanned = user['is_banned'] ?? false;
                    String role = user['role'] ?? 'user';

                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1D1E33),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: isBanned ? Colors.red.withOpacity(0.5) : Colors.white.withOpacity(0.05)
                        ),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isBanned ? Colors.red.withOpacity(0.1) : AppTheme.primaryBlue.withOpacity(0.1),
                          child: Icon(
                            isBanned ? Icons.block : (role == 'admin' ? Icons.admin_panel_settings : Icons.person), 
                            color: isBanned ? Colors.red : (role == 'admin' ? Colors.amber : AppTheme.primaryBlue), 
                            size: 24
                          ),
                        ),
                        title: Text(user['email'] ?? "No Email", style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Phone: ${user['phone'] ?? 'N/A'}", style: const TextStyle(color: Colors.white54, fontSize: 12)),
                            const SizedBox(height: 4),
                            // Role Badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: role == 'admin' ? Colors.amber.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                role.toUpperCase(),
                                style: TextStyle(color: role == 'admin' ? Colors.amber : Colors.blue, fontSize: 9, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Change Role Button (Admin <-> User)
                            IconButton(
                              icon: const Icon(Icons.manage_accounts, color: Colors.white70),
                              tooltip: "Change Role",
                              onPressed: () async {
                                await _dbService.toggleUserRole(user['id'], role);
                                _fetchUsers();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Role Updated Successfully")),
                                );
                              },
                            ),
                            // Ban/Unban Button
                            IconButton(
                              icon: Icon(
                                isBanned ? Icons.gavel_rounded : Icons.gavel_outlined,
                                color: isBanned ? Colors.red : Colors.grey,
                              ),
                              tooltip: isBanned ? "Unban User" : "Ban User",
                              onPressed: () async {
                                await _dbService.toggleUserBan(user['id'], isBanned);
                                _fetchUsers();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(isBanned ? "User Unbanned" : "User Banned")),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }
}