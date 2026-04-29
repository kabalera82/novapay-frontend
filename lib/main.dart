// lib/main.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:isar/isar.dart';
import 'package:media_kit/media_kit.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'config/theme.dart';
import 'config/app_routes.dart';
import 'data/local/isar.dart';
import 'services/config_service.dart';
import 'bindings/app_bindings.dart';
import 'presentation/pages/splash_page.dart';
import 'presentation/pages/login_page.dart';
import 'presentation/pages/admin/admin_shell_page.dart';
import 'presentation/pages/user/user_shell_page.dart';
import 'presentation/pages/profile_page.dart';
import 'package:flutter/services.dart'; // Para controlar la orientación y el modo de pantalla

const bool _resetOnStartForTests = bool.fromEnvironment('TEST_RESET_ON_START', defaultValue: false);

Future<bool> _consumeTestResetFlag() async {
  if (!_resetOnStartForTests) return false;

  final supportDir = await getApplicationSupportDirectory();
  final markerPath = p.join(supportDir.path, '.test_reset_on_start_consumed');
  final markerFile = File(markerPath);

  if (await markerFile.exists()) return false;

  await markerFile.parent.create(recursive: true);
  await markerFile.writeAsString(DateTime.now().toIso8601String(), flush: true);
  return true;
}

void main() async {
  // Asegura que los bindings de Flutter estén inicializados
  WidgetsFlutterBinding.ensureInitialized();

  // Oculta la barra de estado (arriba) y la barra de navegación/taskbar (abajo)
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // Fija la orientación en horizontal (Landscape) para que no se gire solo
  SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);

  // Inicializa el servicio de base de datos y otros servicios necesarios antes de ejecutar la aplicación
  MediaKit.ensureInitialized();
  final isar = await openIsar();
  if (await _consumeTestResetFlag()) {
    await ConfigService(isar).factoryResetKeepingSeeds();
  }
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
        GetPage(name: AppRoutes.splash, page: () => const SplashPage()),
        GetPage(name: AppRoutes.login, page: () => const LoginPage()),
        GetPage(name: AppRoutes.admin, page: () => const AdminShellPage()),
        GetPage(name: AppRoutes.user, page: () => const UserShellPage()),
        GetPage(name: AppRoutes.profile, page: () => const ProfilePage()),
      ],
      debugShowCheckedModeBanner: false,
    );
  }
}
