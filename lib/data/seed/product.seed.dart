// lib/data/seed/product.seed.dart
import 'package:isar/isar.dart';
import '../models/product.dart';
import '../models/enums/tax.rate.enum.dart';

Future<void> seedProducts(Isar isar) async {
  final existing = await isar.products.count();
  if (existing > 0) return;

  final products = [
    // Bebidas — IVA reducido 10%
    Product()..name = 'Agua 50cl'        ..price = 1.50 ..costPrice = 0.30 ..stock = 100 ..category = 'Bebidas' ..taxRate = TaxRate.reducido,
    Product()..name = 'Coca Cola'         ..price = 2.50 ..costPrice = 0.80 ..stock = 100 ..category = 'Bebidas' ..taxRate = TaxRate.reducido,
    Product()..name = 'Cerveza Estrella'  ..price = 2.50 ..costPrice = 0.70 ..stock = 100 ..category = 'Bebidas' ..taxRate = TaxRate.reducido,
    Product()..name = 'Vino Tinto Copa'   ..price = 3.00 ..costPrice = 0.90 ..stock = 100 ..category = 'Bebidas' ..taxRate = TaxRate.reducido,
    Product()..name = 'Café Solo'         ..price = 1.50 ..costPrice = 0.25 ..stock = 100 ..category = 'Bebidas' ..taxRate = TaxRate.reducido,
    Product()..name = 'Café con Leche'    ..price = 1.80 ..costPrice = 0.35 ..stock = 100 ..category = 'Bebidas' ..taxRate = TaxRate.reducido,
    Product()..name = 'Zumo Naranja'      ..price = 2.50 ..costPrice = 0.60 ..stock = 100 ..category = 'Bebidas' ..taxRate = TaxRate.reducido,
    Product()..name = 'Botella Agua 1.5L' ..price = 2.00 ..costPrice = 0.50 ..stock = 50  ..category = 'Bebidas' ..taxRate = TaxRate.reducido,
    // Comida — IVA reducido 10%
    Product()..name = 'Tosta Jamón'       ..price = 4.50 ..costPrice = 1.50 ..stock = 50  ..category = 'Comida'  ..taxRate = TaxRate.reducido,
    Product()..name = 'Bocadillo Mixto'   ..price = 3.50 ..costPrice = 1.20 ..stock = 50  ..category = 'Comida'  ..taxRate = TaxRate.reducido,
    Product()..name = 'Pincho Tortilla'   ..price = 2.00 ..costPrice = 0.60 ..stock = 50  ..category = 'Comida'  ..taxRate = TaxRate.reducido,
    Product()..name = 'Ensalada César'    ..price = 8.00 ..costPrice = 2.50 ..stock = 30  ..category = 'Comida'  ..taxRate = TaxRate.reducido,
    Product()..name = 'Hamburguesa'       ..price = 9.50 ..costPrice = 3.00 ..stock = 30  ..category = 'Comida'  ..taxRate = TaxRate.reducido,
    // Postres — IVA reducido 10%
    Product()..name = 'Flan Casero'       ..price = 3.50 ..costPrice = 0.80 ..stock = 20  ..category = 'Postres' ..taxRate = TaxRate.reducido,
    Product()..name = 'Tarta del Día'     ..price = 4.00 ..costPrice = 1.20 ..stock = 15  ..category = 'Postres' ..taxRate = TaxRate.reducido,
    Product()..name = 'Helado 2 Bolas'    ..price = 3.00 ..costPrice = 0.90 ..stock = 30  ..category = 'Postres' ..taxRate = TaxRate.reducido,
    // Tabaco — IVA general 21%
    Product()..name = 'Marlboro'          ..price = 5.50 ..costPrice = 4.20 ..stock = 50  ..category = 'Tabaco'  ..taxRate = TaxRate.general,
    Product()..name = 'Ducados'           ..price = 5.00 ..costPrice = 3.80 ..stock = 50  ..category = 'Tabaco'  ..taxRate = TaxRate.general,
    // Varios
    Product()..name = 'Chicles'           ..price = 1.00 ..costPrice = 0.40 ..stock = 100 ..category = 'Varios'  ..taxRate = TaxRate.general,
    Product()..name = 'Periódico'         ..price = 1.50 ..costPrice = 1.20 ..stock = 20  ..category = 'Varios'  ..taxRate = TaxRate.superReducido,
  ];

  await isar.writeTxn(() async {
    await isar.products.putAll(products);
  });
}