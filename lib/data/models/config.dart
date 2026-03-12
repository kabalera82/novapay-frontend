import 'package:isar/isar.dart';

part 'config.g.dart';

@collection
class Config {
  Id id = Isar.autoIncrement;
  String businessMode = 'bar';
  String businessName = '';
  String? printerMacAddress;
}
