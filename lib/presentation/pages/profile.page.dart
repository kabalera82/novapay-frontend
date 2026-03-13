// lib/presentation/pages/profile.page.dart
import 'package:flutter/material.dart';

import '../../data/models/user.dart';
import '../widgets/profile/profile.form.widget.dart';
import 'login.page.dart';

class ProfilePage extends StatelessWidget {
  static const String routename = '/profile';

  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final user = args is User ? args : User();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi perfil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () =>
                Navigator.pushReplacementNamed(context, LoginPage.routename),
          ),
        ],
      ),
      body: ProfileFormWidget(user: user),
    );
  }
}
