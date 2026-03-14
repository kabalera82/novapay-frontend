// lib/services/expense_service.dart
import 'package:isar/isar.dart';

import '../data/models/expense.dart';
import '../data/models/product.dart';

class ExpenseService {
  final Isar _isar;
  ExpenseService(this._isar);

  Future<Expense> create(Expense expense) async {
    await _isar.writeTxn(() async {
      await _isar.expenses.put(expense);
      if (expense.category == ExpenseCategory.compras &&
          expense.productId > 0 &&
          expense.quantity > 0) {
        final product = await _isar.products.get(expense.productId);
        if (product != null) {
          product.stock += expense.quantity;
          await _isar.products.put(product);
        }
      }
    });
    return expense;
  }

  Future<List<Expense>> getAll() async {
    return _isar.expenses.where().sortByDateDesc().findAll();
  }

  Future<List<Expense>> getByDate(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = DateTime(date.year, date.month, date.day, 23, 59, 59);
    return _isar.expenses
        .filter()
        .dateBetween(start, end)
        .sortByDateDesc()
        .findAll();
  }

  Future<void> delete(int id) async {
    await _isar.writeTxn(() async {
      await _isar.expenses.delete(id);
    });
  }
}
