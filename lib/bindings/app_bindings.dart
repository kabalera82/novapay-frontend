// lib/bindings/app_bindings.dart
import 'package:get/get.dart';
import 'package:isar/isar.dart';

import '../services/product_service.dart';
import '../services/ticket_service.dart';
import '../services/user_service.dart';
import '../services/report_service.dart';
import '../services/config_service.dart';
import '../services/expense_service.dart';
import '../services/receipt_print_service.dart';
import '../services/verifactu_service.dart';
import '../presentation/controllers/admin_shell_controller.dart';
import '../presentation/controllers/auth_controller.dart';
import '../presentation/controllers/user_controller.dart';
import '../presentation/controllers/product_controller.dart';
import '../presentation/controllers/ticket_controller.dart';
import '../presentation/controllers/ticket_history_controller.dart';
import '../presentation/controllers/report_controller.dart';
import '../presentation/controllers/config_controller.dart';
import '../presentation/controllers/expense_controller.dart';
import '../presentation/controllers/verifactu_controller.dart';

class AppBindings extends Bindings {
  final Isar isar;
  AppBindings(this.isar);

  @override
  void dependencies() {
    // ── Servicios ────────────────────────────────────────────────────────────
    Get.put(UserService(isar), permanent: true);
    Get.put(ProductService(isar), permanent: true);
    Get.put(TicketService(isar), permanent: true);
    Get.put(ReportService(isar), permanent: true);
    Get.put(ConfigService(isar), permanent: true);
    Get.put(ExpenseService(isar), permanent: true);
    Get.put(VerifactuService(Get.find<ConfigService>()), permanent: true);
    Get.put(ReceiptPrintService(Get.find<UserService>(), Get.find<ConfigService>()), permanent: true);

    // ── Controladores ────────────────────────────────────────────────────────
    Get.put(AdminShellController(), permanent: true);
    Get.put(AuthController(Get.find<UserService>()), permanent: true);
    Get.put(UserController(Get.find<UserService>()), permanent: true);
    Get.put(ProductController(Get.find<ProductService>()), permanent: true);
    Get.put(
      TicketController(Get.find<TicketService>(), Get.find<VerifactuService>(), Get.find<ReceiptPrintService>()),
      permanent: true,
    );
    Get.put(TicketHistoryController(Get.find<TicketService>()), permanent: true);
    Get.put(ReportController(Get.find<ReportService>()), permanent: true);
    Get.put(ConfigController(Get.find<ConfigService>()), permanent: true);
    Get.put(ExpenseController(Get.find<ExpenseService>()), permanent: true);
    Get.put(VerifactuController(Get.find<VerifactuService>(), Get.find<UserService>()), permanent: true);
  }
}
