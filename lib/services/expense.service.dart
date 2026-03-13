// lib/services/expense.service.dart
import 'dart:convert';
import 'dart:io';

import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../data/models/expense.dart';
import '../data/models/product.dart';

// ── Fichero JSON de persistencia ──────────────────────────────────────────────

Future<File> _expenseFile() async {
  final dir = await getApplicationDocumentsDirectory();
  return File('${dir.path}/expenses.json');
}

Future<List<Expense>> _readAll() async {
  final file = await _expenseFile();
  if (!await file.exists()) return [];
  try {
    final raw  = await file.readAsString();
    final list = jsonDecode(raw) as List<dynamic>;
    return list.map((e) => Expense.fromJson(e as Map<String, dynamic>)).toList();
  } catch (_) {
    return [];
  }
}

Future<void> _writeAll(List<Expense> expenses) async {
  final file = await _expenseFile();
  await file.writeAsString(jsonEncode(expenses.map((e) => e.toJson()).toList()));
}

int _nextId(List<Expense> all) =>
    all.isEmpty ? 1 : all.map((e) => e.id).reduce((a, b) => a > b ? a : b) + 1;

// ── CREATE — registra gasto y, si es compra, incrementa stock ─────────────────

Future<Expense> createExpense(Isar isar, Expense expense) async {
  final all     = await _readAll();
  final saved   = expense.copyWith(id: _nextId(all));
  all.add(saved);
  await _writeAll(all);

  // Si es compra, incrementar stock del producto vinculado
  if (saved.category == ExpenseCategory.compras &&
      saved.productId > 0 &&
      saved.quantity > 0) {
    await isar.writeTxn(() async {
      final product = await isar.products.get(saved.productId);
      if (product != null) {
        product.stock += saved.quantity;
        await isar.products.put(product);
      }
    });
  }

  return saved;
}

// ── READ ──────────────────────────────────────────────────────────────────────

Future<List<Expense>> getAllExpenses() async {
  final all = await _readAll();
  return all..sort((a, b) => b.date.compareTo(a.date));
}

Future<List<Expense>> getExpensesByDate(DateTime date) async {
  final start = DateTime(date.year, date.month, date.day);
  final end   = start.add(const Duration(days: 1));
  final all   = await _readAll();
  return all
      .where((e) => e.date.isAfter(start) && e.date.isBefore(end))
      .toList()
    ..sort((a, b) => b.date.compareTo(a.date));
}

// ── DELETE ────────────────────────────────────────────────────────────────────

Future<void> deleteExpense(int id) async {
  final all = await _readAll();
  all.removeWhere((e) => e.id == id);
  await _writeAll(all);
}
