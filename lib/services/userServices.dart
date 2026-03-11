import 'package:isar/isar.dart';
import '../data/models/user.dart';

// CREATE — registra un nuevo usuario
Future<void> registerUser(Isar isar, String email, String password) async {
  final user = User()
    ..email = email
    ..password = password;
  await isar.writeTxn(() async {
    await isar.users.put(user);
  });
}

// READ — obtiene un usuario por id
Future<User?> getUserById(Isar isar, int id) async {
  return await isar.users.get(id);
}

// READ — obtiene todos los usuarios
Future<List<User>> getAllUsers(Isar isar) async {
  return await isar.users.where().findAll();
}

// READ — login: busca por email o por username + password
Future<User?> loginUser(Isar isar, String identifier, String password) async {
  // Intenta por email primero
  final byEmail = await isar.users
      .filter()
      .emailEqualTo(identifier)
      .passwordEqualTo(password)
      .findFirst();
  if (byEmail != null) return byEmail;

  // Si no, intenta por username
  return await isar.users
      .filter()
      .usernameEqualTo(identifier)
      .passwordEqualTo(password)
      .findFirst();
}

// UPDATE — actualiza los datos de un usuario existente
Future<void> updateUser(Isar isar, User user) async {
  await isar.writeTxn(() async {
    await isar.users.put(user); // put hace insert o update según el id
  });
}

// DELETE — elimina un usuario por id
Future<void> deleteUser(Isar isar, int id) async {
  await isar.writeTxn(() async {
    await isar.users.delete(id);
  });
}

// SEED — crea o corrige el usuario admin
Future<void> seedAdmin(Isar isar) async {
  final existing = await isar.users
      .filter()
      .emailEqualTo('admin')
      .findFirst();
  // Si ya existe pero el role no está bien (BD antigua sin campo role), lo corrige
  if (existing != null) {
    if (existing.role != 'admin') {
      existing.role = 'admin';
      await isar.writeTxn(() async => await isar.users.put(existing));
    }
    return;
  }
  final admin = User()
    ..username = 'Admin'
    ..email = 'admin'
    ..password = '1234'
    ..role = 'admin';
  await isar.writeTxn(() async {
    await isar.users.put(admin);
  });
}