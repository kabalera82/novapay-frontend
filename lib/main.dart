// lib/main.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:media_kit/media_kit.dart';

import 'config/theme.dart';
import 'data/local/isar.dart';
import 'data/seed/product.seed.dart';
import 'services/userServices.dart';
import 'services/config.service.dart';
import 'bindings/app.bindings.dart';
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
  await seedProducts(isar);
  await seedBusinessConfig(isar);
  runApp(MainApp(isar: isar));
}

class MainApp extends StatelessWidget {
  final isar;
  const MainApp({super.key, required this.isar});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Novapay TPV',
      theme: AppTheme.lightTheme,
      initialBinding: AppBindings(isar),
      home: const SplashPage(),
      routes: {
        SplashPage.routename:        (_) => const SplashPage(),
        LoginPage.routename:         (_) => const LoginPage(),
        DashboardUsersPage.routename:(_) => const DashboardUsersPage(),
        DashboardCajaPage.routename: (_) => const DashboardCajaPage(),
        ProfilePage.routename:       (_) => const ProfilePage(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}