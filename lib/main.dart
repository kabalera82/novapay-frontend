// lib/main.dart
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';

import 'config/theme.dart';
import 'data/local/isar.dart';
import 'services/userServices.dart';
import 'presentation/pages/splash.page.dart';
import 'presentation/pages/login.page.dart';
import 'presentation/pages/dashboard.users.page.dart';
import 'presentation/pages/dashboard.caja.page.dart';
import 'presentation/pages/profile.page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  final isar = await openIsar();
  await seedAdmin(isar);
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Novapay TPV',
      theme: AppTheme.lightTheme,
      home: const SplashPage(),
      routes: {
        SplashPage.routename: (_) => const SplashPage(),
        LoginPage.routename: (_) => const LoginPage(),
        DashboardUsersPage.routename: (_) => const DashboardUsersPage(),
        DashboardCajaPage.routename: (_) => const DashboardCajaPage(),
        ProfilePage.routename: (_) => const ProfilePage(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}