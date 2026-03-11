import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../../data/models/user.dart';

Future<Isar> openIsar() async {
  if (Isar.instanceNames.isNotEmpty) {
    return Isar.getInstance()!; // ya está abierta, la reutilizas
  }
  final dir = await getApplicationDocumentsDirectory();
  return await Isar.open(
    [UserSchema], // le dices qué tablas/colecciones existen
    directory: dir.path, // dónde guardar el archivo de la BD

  );
}