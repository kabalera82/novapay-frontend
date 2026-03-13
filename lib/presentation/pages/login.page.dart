// lib/presentation/pages/login.page.dart
// pantalla de login, validación de usuario y contraseña, redirección a dashboard o perfil según rol
import 'package:flutter/material.dart';

import '../../data/local/isar.dart';
import '../../services/userServices.dart';
import 'admin/admin.shell.page.dart';
import 'profile.page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  // login.page.dart
static const String routename = '/login';

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final isar = await openIsar();
    final user = await loginUser(isar, _userCtrl.text, _passCtrl.text);
    if (!mounted) return;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuario o contraseña incorrectos')),
      );
      return;
    }

    if (user.role == 'admin') {
      Navigator.pushReplacementNamed(context, AdminShellPage.routename, arguments: user);
    } else {
      Navigator.pushReplacementNamed(context, ProfilePage.routename, arguments: user);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bienvenido a NovaPay')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: 80,
                  maxHeight: 260,
                  minWidth: 80,
                  maxWidth: 360,
                ),
                child: Image.asset('assets/images/novapay.webp', fit: BoxFit.contain),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _userCtrl,
                decoration: const InputDecoration(labelText: 'Usuario o Email'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Contraseña'),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _login,
                  child: const Text('Iniciar sesión'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}