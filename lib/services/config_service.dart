// lib/services/config_service.dart
import 'package:isar/isar.dart';
import '../data/models/daily_report.dart';
import '../data/models/expense.dart';
import '../data/models/fiscal_ticket_trace.dart';
import '../data/models/config.dart';
import '../data/models/business_config.dart';
import '../data/models/product.dart';
import '../data/models/ticket.dart';
import '../data/models/user.dart';
import '../data/seed/product_seed.dart';
import 'user_service.dart';

class ConfigService {
  final Isar _isar;
  ConfigService(this._isar);

  /// Reinicio de fábrica local: elimina todo Isar y conserva solo semillas
  /// mínimas (usuario admin por defecto + catálogo inicial de productos).
  Future<void> factoryResetKeepingSeeds() async {
    await _isar.writeTxn(() async {
      await _isar.clear();
    });

    await UserService(_isar).seedAdmin();
    await seedProducts(_isar);
  }

  Future<Config> getConfig() async {
    final existing = await _isar.configs.where().findFirst();
    if (existing != null) return existing;
    final config = Config()..businessMode = 'bar';
    await _isar.writeTxn(() async {
      await _isar.configs.put(config);
    });
    return config;
  }

  Future<void> saveConfig(Config config) async {
    await _isar.writeTxn(() async {
      await _isar.configs.put(config);
    });
  }

  Future<BusinessConfig?> getBusinessConfig() async {
    return _isar.businessConfigs.where().findFirst();
  }

  Future<void> saveBusinessConfig(BusinessConfig config) async {
    await _isar.writeTxn(() async {
      await _isar.businessConfigs.put(config);
    });
  }

  Future<void> seedBusinessConfig() async {
    final existing = await _isar.businessConfigs.where().findFirst();
    if (existing == null) {
      final config = BusinessConfig()
        ..businessName = ''
        ..fiscalName = ''
        ..cifNif = ''
        ..address = ''
        ..adminPassword = '1234';
      await _isar.writeTxn(() async {
        await _isar.businessConfigs.put(config);
      });
    }
  }
}
