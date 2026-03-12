// lib/data/models/product.dart
import 'package:isar/isar.dart';

part 'product.g.dart';

@collection
class Product {
  Id id = Isar.autoIncrement;
  late String name;
  late double price;
  double? costPrice;
  int stock = 0;
  String? category;
  String? barcode;
  String? imagePath;
  double taxRate = 0.21;
}
