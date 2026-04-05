// lib/services/config_service.dart
import 'package:isar/isar.dart';
import '../data/models/config.dart';
import '../data/models/business_config.dart';

class ConfigService {
  final Isar _isar;
  ConfigService(this._isar);

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
        ..cifNif = ''
        ..address = ''
        ..adminPassword = '1234';
      await _isar.writeTxn(() async {
        await _isar.businessConfigs.put(config);
      });
    }
  }
}
