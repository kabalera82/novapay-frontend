// lib/presentation/pages/dashboard.caja.page.dart
import 'package:flutter/material.dart';

import 'login.page.dart';

class DashboardCajaPage extends StatelessWidget {
  const DashboardCajaPage({super.key});
  // dashboard.caja.page.dart
static const String routename = '/dashboard/caja';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Caja'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () =>
                Navigator.pushReplacementNamed(context, LoginPage.routename),
          ),
        ],
      ),
      body: const Center(child: Text('Dashboard Caja — próximamente')),
    );
  }
}