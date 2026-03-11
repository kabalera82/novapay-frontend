// lib/local/isar.service.dart
// apertura y acceso a la base de datos local Isar
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../../data/models/user.dart';

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
      [UserSchema],
      directory: dir.path,
    );
  }
}