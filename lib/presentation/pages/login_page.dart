// lib/presentation/pages/login_page.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/auth_controller.dart';
import '../../config/app_routes.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _showPassword = false;

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final authCtrl = Get.find<AuthController>();
    final ok = await authCtrl.login(_userCtrl.text, _passCtrl.text);

    if (!mounted) return;

    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Usuario o contraseña incorrectos')));
      return;
    }

    if (authCtrl.isAdmin) {
      Get.offNamed(AppRoutes.admin, arguments: authCtrl.currentUser.value);
    } else {
      Get.offNamed(AppRoutes.user, arguments: authCtrl.currentUser.value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authCtrl = Get.find<AuthController>();
    final isAndroid = Theme.of(context).platform == TargetPlatform.android;
    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    final hideLogo = isAndroid && keyboardOpen;

    return Scaffold(
      appBar: AppBar(title: const Text('Bienvenido a NovaPay')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!hideLogo) ...[
                  ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 80, maxHeight: 260, minWidth: 80, maxWidth: 360),
                    child: Image.asset('assets/images/novapay.webp', fit: BoxFit.contain),
                  ),
                  const SizedBox(height: 32),
                ],
                TextField(
                  controller: _userCtrl,
                  decoration: const InputDecoration(labelText: 'Usuario o Email'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passCtrl,
                  obscureText: !_showPassword,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    suffixIcon: IconButton(
                      onPressed: () => setState(() => _showPassword = !_showPassword),
                      icon: Icon(_showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                      tooltip: _showPassword ? 'Ocultar contraseña' : 'Mostrar contraseña',
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Obx(
                  () => SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: authCtrl.isLoading.value ? null : _login,
                      child: authCtrl.isLoading.value
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Iniciar sesión'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
