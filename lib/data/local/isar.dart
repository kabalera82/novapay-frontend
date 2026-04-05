// lib/data/local/isar.dart
import 'dart:io';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../../data/models/user.dart';
import '../../data/models/product.dart';
import '../../data/models/ticket.dart';
import '../../data/models/daily_report.dart';
import '../../data/models/config.dart';
import '../../data/models/business_config.dart';
import '../../data/models/expense.dart';

const String _factoryResetMarkerFileName = '.novapay_factory_reset_done';

Future<Isar> openIsar() async {
  if (Isar.instanceNames.isNotEmpty) {
    return Isar.getInstance()!;
  }
  final dir = await getApplicationDocumentsDirectory();
  final isar = await Isar.open([
    UserSchema,
    ProductSchema,
    TicketSchema,
    DailyReportSchema,
    ConfigSchema,
    BusinessConfigSchema,
    ExpenseSchema,
  ], directory: dir.path);

  await _runFactoryResetIfNeeded(dir.path, isar);
  return isar;
}

Future<void> _runFactoryResetIfNeeded(String directoryPath, Isar isar) async {
  final markerFile = File('$directoryPath${Platform.pathSeparator}$_factoryResetMarkerFileName');
  if (await markerFile.exists()) {
    return;
  }

  await isar.writeTxn(() async {
    await isar.users.clear();
    await isar.tickets.clear();
    await isar.dailyReports.clear();
    await isar.configs.clear();
    await isar.businessConfigs.clear();
    await isar.expenses.clear();
    await isar.products.clear();
  });

  await markerFile.writeAsString('Factory reset completed at ${DateTime.now().toIso8601String()}', flush: true);
}
