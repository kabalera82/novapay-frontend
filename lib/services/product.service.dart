// lib/services/product.service.dart
import 'package:isar/isar.dart';
import '../data/models/product.dart';

// CREATE
Future<void> createProduct(Isar isar, Product product) async {
  await isar.writeTxn(() async {
    await isar.products.put(product);
  });
}

// READ — por id
Future<Product?> getProductById(Isar isar, int id) async {
  return await isar.products.get(id);
}

// READ — todos
Future<List<Product>> getAllProducts(Isar isar) async {
  return await isar.products.where().findAll();
}

// READ — por categoría
Future<List<Product>> getProductsByCategory(Isar isar, String category) async {
  final all = await isar.products.where().findAll();
  return all.where((p) => p.category == category).toList();
}

// READ — búsqueda por nombre
Future<List<Product>> searchProducts(Isar isar, String query) async {
  final all = await isar.products.where().findAll();
  return all
      .where((p) => p.name.toLowerCase().contains(query.toLowerCase()))
      .toList();
}

// UPDATE
Future<void> updateProduct(Isar isar, Product product) async {
  await isar.writeTxn(() async {
    await isar.products.put(product);
  });
}

// UPDATE — descuenta stock al vender
Future<void> decrementStock(Isar isar, int productId, int quantity) async {
  final product = await isar.products.get(productId);
  if (product == null) return;
  product.stock = (product.stock - quantity).clamp(0, 99999);
  await isar.writeTxn(() async {
    await isar.products.put(product);
  });
}

// DELETE
Future<void> deleteProduct(Isar isar, int id) async {
  await isar.writeTxn(() async {
    await isar.products.delete(id);
  });
}