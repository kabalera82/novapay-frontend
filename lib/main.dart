// lib/main.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:isar/isar.dart';
import 'package:media_kit/media_kit.dart';

import 'config/theme.dart';
import 'config/app_routes.dart';
import 'data/local/isar.dart';
import 'data/seed/product_seed.dart';
import 'services/user_service.dart';
import 'services/config_service.dart';
import 'bindings/app_bindings.dart';
import 'presentation/pages/splash_page.dart';
import 'presentation/pages/login_page.dart';
import 'presentation/pages/admin/admin_shell_page.dart';
import 'presentation/pages/user/user_shell_page.dart';
import 'presentation/pages/profile_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  final isar = await openIsar();
  await UserService(isar).seedAdmin();
  await seedProducts(isar);
  await ConfigService(isar).seedBusinessConfig();
  runApp(MainApp(isar: isar));
}

class MainApp extends StatelessWidget {
  final Isar isar;
  const MainApp({super.key, required this.isar});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Novapay TPV',
      theme: AppTheme.lightModernTheme,
      initialBinding: AppBindings(isar),
      initialRoute: AppRoutes.splash,
      getPages: [
        GetPage(name: AppRoutes.splash,  page: () => const SplashPage()),
        GetPage(name: AppRoutes.login,   page: () => const LoginPage()),
        GetPage(name: AppRoutes.admin,   page: () => const AdminShellPage()),
        GetPage(name: AppRoutes.user,    page: () => const UserShellPage()),
        GetPage(name: AppRoutes.profile, page: () => const ProfilePage()),
      ],
      debugShowCheckedModeBanner: false,
    );
  }
}
