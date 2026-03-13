// lib/presentation/controllers/admin.shell.controller.dart
import 'package:get/get.dart';

class AdminShellController extends GetxController {
  final selectedIndex = 0.obs;

  void navigateTo(int index) => selectedIndex.value = index;
}
