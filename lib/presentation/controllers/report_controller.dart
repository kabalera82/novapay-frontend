// lib/presentation/controllers/report_controller.dart
import 'package:get/get.dart';
import '../../data/models/daily_report.dart';
import '../../services/report_service.dart';

class ReportController extends GetxController {
  final ReportService _service;
  ReportController(this._service);

  final reports     = <DailyReport>[].obs;
  final todayReport = Rxn<DailyReport>();
  final liveStats   = Rxn<DailyReport>();
  final isLoading   = false.obs;
  final isClosing   = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadAll();
    loadToday();
    loadLiveStats();
  }

  Future<void> loadAll() async {
    try {
      isLoading.value = true;
      reports.value = await _service.getAll();
    } catch (e) {
      Get.snackbar('Error', 'No se pudieron cargar los informes');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadToday() async {
    try {
      todayReport.value = await _service.getByDate(DateTime.now());
    } catch (e) {
      Get.snackbar('Error', 'No se pudo cargar el informe de hoy');
    }
  }

  Future<void> loadLiveStats() async {
    try {
      liveStats.value = await _service.getLiveStats();
    } catch (e) {
      Get.snackbar('Error', 'No se pudo calcular el balance');
    }
  }

  Future<void> closeDay() async {
    try {
      isClosing.value = true;
      final report = await _service.closeDay();
      todayReport.value = report;
      liveStats.value   = report;
      await loadAll();
    } catch (e) {
      Get.snackbar('Error', 'No se pudo cerrar la jornada');
    } finally {
      isClosing.value = false;
    }
  }

  /// Reloads stats from DB after a new expense is saved.
  Future<void> refreshAfterExpense() async {
    await loadLiveStats();
    await loadToday();
  }

  // ── Getters (live stats take priority, fallback to closed report) ─────────

  double get todayCash => liveStats.value?.totalCash
      ?? todayReport.value?.totalCash ?? 0;

  double get todayCard => liveStats.value?.totalCard
      ?? todayReport.value?.totalCard ?? 0;

  /// Gross ticket income (cash + card), used as «Ingresos» in the balance view.
  double get todayTotal =>
      (liveStats.value?.totalCash ?? 0) + (liveStats.value?.totalCard ?? 0);

  double get todayExpenses => liveStats.value?.totalExpenses ?? 0;

  int get todayCount => liveStats.value?.ticketCount
      ?? todayReport.value?.ticketCount ?? 0;

  Map<String, int> get todaySoldProducts {
    final summary = liveStats.value?.soldProductsSummary
        ?? todayReport.value?.soldProductsSummary ?? [];
    final map = <String, int>{};
    for (final entry in summary) {
      final parts = entry.split(':');
      if (parts.length == 2) map[parts[0]] = int.tryParse(parts[1]) ?? 0;
    }
    return map;
  }
}
