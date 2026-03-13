// lib/presentation/controllers/expense.controller.dart
import 'package:get/get.dart';
import 'package:isar/isar.dart';

import '../../data/models/expense.dart';
import '../../services/expense.service.dart';

class ExpenseController extends GetxController {
  final Isar isar;
  ExpenseController(this.isar);

  final todayExpenses = <Expense>[].obs;
  final allExpenses   = <Expense>[].obs;
  final isLoading     = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadAll();
    loadToday();
  }

  Future<void> loadToday() async {
    todayExpenses.value = await getExpensesByDate(DateTime.now());
  }

  Future<void> loadAll() async {
    isLoading.value   = true;
    allExpenses.value = await getAllExpenses();
    isLoading.value   = false;
  }

  Future<void> addExpense(Expense expense) async {
    await createExpense(isar, expense);
    await Future.wait([loadToday(), loadAll()]);
  }

  Future<void> removeExpense(int id) async {
    await deleteExpense(id);
    await Future.wait([loadToday(), loadAll()]);
  }

  double get todayTotal =>
      todayExpenses.fold(0.0, (sum, e) => sum + e.amount);

  double totalByCategory(ExpenseCategory cat) => todayExpenses
      .where((e) => e.category == cat)
      .fold(0.0, (sum, e) => sum + e.amount);
}
