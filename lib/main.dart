// lib/main.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:isar/isar.dart';
import 'package:media_kit/media_kit.dart';
import 'package:flutter/services.dart'; // Para controlar la orientación y el modo de pantalla

import 'config/theme.dart';
import 'data/local/isar.dart';
import 'data/seed/product.seed.dart';
import 'services/userServices.dart';
import 'services/config.service.dart';
import 'bindings/app.bindings.dart';
import 'presentation/pages/splash.page.dart';
import 'presentation/pages/login.page.dart';
import 'presentation/pages/admin/admin.shell.page.dart';
import 'presentation/pages/profile.page.dart';

void main() async {
  // Asegura que los bindings de Flutter estén inicializados
  WidgetsFlutterBinding.ensureInitialized();

  // Oculta la barra de estado (arriba) y la barra de navegación/taskbar (abajo)
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // Fija la orientación en horizontal (Landscape) para que no se gire solo
  SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);

  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  final isar = await openIsar();
  await seedAdmin(isar);
  await seedProducts(isar);
  await seedBusinessConfig(isar);
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
      home: const SplashPage(),
      routes: {
        SplashPage.routename: (_) => const SplashPage(),
        LoginPage.routename: (_) => const LoginPage(),
        AdminShellPage.routename: (_) => const AdminShellPage(),
        ProfilePage.routename: (_) => const ProfilePage(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
