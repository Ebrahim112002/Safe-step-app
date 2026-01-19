import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/app_theme.dart';
import 'main_navigation.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleRegister() async {
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      _showError("Please fill all fields");
      return;
    }
    setState(() => _isLoading = true);
    try {
      final res = await Supabase.instance.client.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (res.user != null) {
        await Supabase.instance.client.from('profiles').insert({
          'id': res.user!.id,
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
        });
        if (mounted)
          Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (c) => const MainNavigation()),
              (r) => false);
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String m) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(m), backgroundColor: Colors.red));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            const SizedBox(height: 60),
            const Text("Create Account",
                style: TextStyle(
                    fontSize: 32,
                    color: Colors.white,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 40),
            _buildField("Name", Icons.person, _nameController),
            const SizedBox(height: 20),
            _buildField("Email", Icons.email, _emailController),
            const SizedBox(height: 20),
            _buildField("Password", Icons.lock, _passwordController,
                isPass: true),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15))),
                onPressed: _isLoading ? null : _handleRegister,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Sign Up",
                        style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String l, IconData i, TextEditingController c,
      {bool isPass = false}) {
    return TextField(
      controller: c,
      obscureText: isPass,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
          labelText: l,
          prefixIcon: Icon(i, color: AppTheme.primaryBlue),
          filled: true,
          fillColor: AppTheme.cardColor,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15))),
    );
  }
}
