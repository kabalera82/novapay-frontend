// lib/presentation/controllers/report.controller.dart
import 'package:get/get.dart';
import 'package:isar/isar.dart';
import '../../data/models/daily.report.dart';
import '../../services/report.service.dart';

class ReportController extends GetxController {
  final Isar isar;
  ReportController(this.isar);

  final reports     = <DailyReport>[].obs;
  final todayReport = Rxn<DailyReport>();
  final isLoading   = false.obs;
  final isClosing   = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadAll();
    loadToday();
  }

  Future<void> loadAll() async {
    isLoading.value = true;
    reports.value = await getAllReports(isar);
    isLoading.value = false;
  }

  Future<void> loadToday() async {
    todayReport.value = await getReportByDate(isar, DateTime.now());
  }

  Future<void> closeDay() async {
    isClosing.value = true;
    final report = await closeDailyReport(isar);
    todayReport.value = report;
    await loadAll();
    isClosing.value = false;
  }

  Future<void> addExpenseToday(double amount) async {
    await addExpense(isar, amount);
    await loadToday();
    await loadAll();
  }

  double get todayCash     => todayReport.value?.totalCash ?? 0;
  double get todayCard     => todayReport.value?.totalCard ?? 0;
  double get todayTotal    => todayReport.value?.grandTotal ?? 0;
  double get todayExpenses => todayReport.value?.totalExpenses ?? 0;
  int    get todayCount    => todayReport.value?.ticketCount ?? 0;

  Map<String, int> get todaySoldProducts {
    final summary = todayReport.value?.soldProductsSummary ?? [];
    final map = <String, int>{};
    for (final entry in summary) {
      final parts = entry.split(':');
      if (parts.length == 2) map[parts[0]] = int.tryParse(parts[1]) ?? 0;
    }
    return map;
  }
}