// lib/services/producto.service.dart
// lib/services/config.service.dart
import 'package:isar/isar.dart';
import '../data/models/config.dart';
import '../data/models/business.config.dart';

// ---- Config (ajustes del terminal) ----

Future<Config> getConfig(Isar isar) async {
  final existing = await isar.configs.where().findFirst();
  if (existing != null) return existing;
  // Si no existe, crea la config por defecto
  final config = Config()
    ..businessMode = 'bar'
    ..businessName = 'Mi Negocio';
  await isar.writeTxn(() async {
    await isar.configs.put(config);
  });
  return config;
}

Future<void> saveConfig(Isar isar, Config config) async {
  await isar.writeTxn(() async {
    await isar.configs.put(config);
  });
}

// ---- BusinessConfig (datos fiscales) ----

Future<BusinessConfig?> getBusinessConfig(Isar isar) async {
  return await isar.businessConfigs.where().findFirst();
}

Future<void> saveBusinessConfig(Isar isar, BusinessConfig config) async {
  await isar.writeTxn(() async {
    await isar.businessConfigs.put(config);
  });
}

// SEED — config fiscal vacía lista para rellenar
Future<void> seedBusinessConfig(Isar isar) async {
  final existing = await isar.businessConfigs.count();
  if (existing > 0) return;
  final config = BusinessConfig()
    ..businessName = ''
    ..cifNif = ''
    ..address = ''
    ..adminPassword = '1234';
  await isar.writeTxn(() async {
    await isar.businessConfigs.put(config);
  });
}