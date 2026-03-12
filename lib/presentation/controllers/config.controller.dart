// lib/presentation/controllers/config.controller.dart
import 'package:get/get.dart';
import 'package:isar/isar.dart';
import '../../data/models/config.dart';
import '../../data/models/business.config.dart';
import '../../services/config.service.dart';

class ConfigController extends GetxController {
  final Isar isar;
  ConfigController(this.isar);

  final config         = Rxn<Config>();
  final businessConfig = Rxn<BusinessConfig>();
  final isLoading      = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadAll();
  }

  Future<void> loadAll() async {
    isLoading.value = true;
    config.value         = await getConfig(isar);
    businessConfig.value = await getBusinessConfig(isar);
    isLoading.value = false;
  }

  Future<void> updateConfig(Config updated) async {
    await saveConfig(isar, updated);
    config.value = updated;
  }

  Future<void> updateBusinessConfig(BusinessConfig updated) async {
    await saveBusinessConfig(isar, updated);
    businessConfig.value = updated;
  }

  String get businessName => config.value?.businessName ?? '';
  String get businessMode => config.value?.businessMode ?? 'bar';
  String get legalName    => businessConfig.value?.businessName ?? '';
  String get cifNif       => businessConfig.value?.cifNif ?? '';
  String get address      => businessConfig.value?.address ?? '';

  bool verifyAdminPassword(String input) {
    return businessConfig.value?.adminPassword == input;
  }
}