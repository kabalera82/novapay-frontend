// lib/data/models/user.dart
import 'package:isar/isar.dart';

part 'user.g.dart';

@collection
class User {
  Id id = Isar.autoIncrement;
  String? username;
  String? lastName;
  String? password;

  @Index(unique: true, name: 'email_index')
  String? email;

  String? phone;

  // 'admin' o 'user'
  String role = 'user';
}

