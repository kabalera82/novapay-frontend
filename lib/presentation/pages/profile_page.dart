// lib/presentation/pages/profile_page.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/models/user.dart';
import '../../config/app_routes.dart';
import '../widgets/profile/profile_form_widget.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments;
    final user = args is User ? args : User();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi perfil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () => Get.offNamed(AppRoutes.login),
          ),
        ],
      ),
      body: ProfileFormWidget(user: user),
    );
  }
}
