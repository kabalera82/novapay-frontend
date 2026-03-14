// lib/presentation/controllers/admin_shell_controller.dart
import 'package:get/get.dart';

class AdminShellController extends GetxController {
  final selectedIndex = 0.obs;
  final tableCount    = 12.obs;

  void navigateTo(int index) => selectedIndex.value = index;
}
