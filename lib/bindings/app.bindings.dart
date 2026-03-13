// lib/bindings/app.bindings.dart
import 'package:get/get.dart';
import 'package:isar/isar.dart';
import '../presentation/controllers/admin.shell.controller.dart';
import '../presentation/controllers/product.controller.dart';
import '../presentation/controllers/ticket.controller.dart';
import '../presentation/controllers/report.controller.dart';
import '../presentation/controllers/config.controller.dart';

class AppBindings extends Bindings {
  final Isar isar;
  AppBindings(this.isar);

  @override
  void dependencies() {
    Get.put(AdminShellController(),  permanent: true);
    Get.put(ProductController(isar), permanent: true);
    Get.put(TicketController(isar),  permanent: true);
    Get.put(ReportController(isar),  permanent: true);
    Get.put(ConfigController(isar),  permanent: true);
  }
}