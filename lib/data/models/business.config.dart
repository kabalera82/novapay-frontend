import 'package:isar/isar.dart';

part 'business.config.g.dart';

@collection
class BusinessConfig {
  Id id = Isar.autoIncrement;
  String businessName = '';
  String cifNif = '';
  String address = '';
  String? logoPath;
  String adminPassword = '';
  String? phone;
  String? email;
}
