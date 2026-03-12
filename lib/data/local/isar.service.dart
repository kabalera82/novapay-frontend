// lib/local/isar.service.dart
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../../data/models/user.dart';
import '../../data/models/product.dart';
import '../../data/models/ticket.dart';
import '../../data/models/daily.report.dart';
import '../../data/models/config.dart';
import '../../data/models/business.config.dart';

class IsarService {
  late Future<Isar> db;

  IsarService() {
    db = _openDB();
  }

  Future<Isar> _openDB() async {
    if (Isar.instanceNames.isNotEmpty) {
      return Isar.getInstance()!;
    }
    final dir = await getApplicationDocumentsDirectory();
    return await Isar.open(
      [
        UserSchema,
        ProductSchema,
        TicketSchema,
        DailyReportSchema,
        ConfigSchema,
        BusinessConfigSchema,
      ],
      directory: dir.path,
    );
  }
}