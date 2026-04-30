// lib/presentation/controllers/report_controller.dart
import 'dart:io';
import 'package:get/get.dart';
import '../../data/models/daily_report.dart';
import '../../services/report_service.dart';
import '../../services/export_service.dart';
import 'package:share_plus/share_plus.dart';

class ReportController extends GetxController {
  final ReportService _service;
  final ExportService _exportService;
  ReportController(this._service, this._exportService);

  final reports = <DailyReport>[].obs;
  final todayReport = Rxn<DailyReport>();
  final liveStats = Rxn<DailyReport>();
  final isLoading = false.obs;
  final isClosing = false.obs;
  final isExporting = false.obs;

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
      liveStats.value = report;
      await loadAll();
    } catch (e) {
      Get.snackbar('Error', 'No se pudo cerrar la jornada');
    } finally {
      isClosing.value = false;
    }
  }

  Future<DateTime> getLatestCloseTime() async {
    return await _service.getLatestCloseTime();
  }

  /// Reloads stats from DB after a new expense is saved.
  Future<void> refreshAfterExpense() async {
    await loadLiveStats();
    await loadToday();
  }

  // ── Getters (live stats take priority, fallback to closed report) ─────────

  double get todayCash => liveStats.value?.totalCash ?? todayReport.value?.totalCash ?? 0;

  double get todayCard => liveStats.value?.totalCard ?? todayReport.value?.totalCard ?? 0;

  /// Gross ticket income (cash + card), used as «Ingresos» in the balance view.
  double get todayTotal => (liveStats.value?.totalCash ?? 0) + (liveStats.value?.totalCard ?? 0);

  double get todayExpenses => liveStats.value?.totalExpenses ?? 0;

  int get todayCount => liveStats.value?.ticketCount ?? todayReport.value?.ticketCount ?? 0;

  bool get isAccumulatedPeriod {
    final start = liveStats.value?.date;
    if (start == null) return false;
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    return start.isBefore(todayStart);
  }

  Map<String, int> get todaySoldProducts {
    final summary = liveStats.value?.soldProductsSummary ?? todayReport.value?.soldProductsSummary ?? [];
    final map = <String, int>{};
    for (final entry in summary) {
      final idx = entry.lastIndexOf(':');
      if (idx <= 0 || idx >= entry.length - 1) {
        continue;
      }
      final name = entry.substring(0, idx).trim();
      final count = int.tryParse(entry.substring(idx + 1).trim()) ?? 0;
      if (name.isEmpty || count <= 0) {
        continue;
      }
      map[name] = count;
    }
    return map;
  }

  // ── Exportación ──────────────────────────────────────────────────────────

  /// Exporta todos los tickets y cierres a JSON y permite compartir
  Future<void> exportAllToJson() async {
    try {
      isExporting.value = true;
      final filePath = await _exportService.exportToJson();
      await _shareFile(filePath, 'Todos los tickets y cierres');
      Get.snackbar('Éxito', 'Datos exportados correctamente', snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Error', 'No se pudieron exportar los datos: $e');
    } finally {
      isExporting.value = false;
    }
  }

  /// Exporta solo los tickets y cierres del día a JSON y permite compartir
  Future<void> exportTodayToJson() async {
    try {
      isExporting.value = true;
      final filePath = await _exportService.exportTodayToJson();
      await _shareFile(filePath, 'Datos de hoy');
      Get.snackbar('Éxito', 'Datos de hoy exportados correctamente', snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Error', 'No se pudo exportar: $e');
    } finally {
      isExporting.value = false;
    }
  }

  /// Exporta un mes completo (del día 1 al último día del mes)
  Future<void> exportMonthToJson(DateTime monthDate) async {
    try {
      isExporting.value = true;
      final filePath = await _exportService.exportMonthToJson(monthDate);
      await _shareFile(filePath, 'Periodo ${monthDate.month.toString().padLeft(2, '0')}/${monthDate.year}');
      Get.snackbar('Éxito', 'Periodo exportado correctamente', snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Error', 'No se pudo exportar el periodo: $e');
    } finally {
      isExporting.value = false;
    }
  }

  /// Exporta un periodo personalizado (ambas fechas incluidas)
  Future<void> exportCustomPeriodToJson({required DateTime startDate, required DateTime endDate}) async {
    final startInclusive = DateTime(startDate.year, startDate.month, startDate.day);
    final endInclusive = DateTime(endDate.year, endDate.month, endDate.day);
    final endExclusive = endInclusive.add(const Duration(days: 1));

    final startTag =
        '${startInclusive.year}${startInclusive.month.toString().padLeft(2, '0')}${startInclusive.day.toString().padLeft(2, '0')}';
    final endTag =
        '${endInclusive.year}${endInclusive.month.toString().padLeft(2, '0')}${endInclusive.day.toString().padLeft(2, '0')}';

    try {
      isExporting.value = true;
      final filePath = await _exportService.exportPeriodToJson(
        startInclusive: startInclusive,
        endExclusive: endExclusive,
        periodLabel:
            'Periodo ${startInclusive.toIso8601String().split('T')[0]} al ${endInclusive.toIso8601String().split('T')[0]}',
        fileTag: 'range_${startTag}_$endTag',
      );
      await _shareFile(
        filePath,
        'Periodo ${startInclusive.day.toString().padLeft(2, '0')}/${startInclusive.month.toString().padLeft(2, '0')}/${startInclusive.year} '
        'a ${endInclusive.day.toString().padLeft(2, '0')}/${endInclusive.month.toString().padLeft(2, '0')}/${endInclusive.year}',
      );
      Get.snackbar('Éxito', 'Periodo exportado correctamente', snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Error', 'No se pudo exportar el periodo: $e');
    } finally {
      isExporting.value = false;
    }
  }

  /// Comparte un archivo usando la funcionalidad nativa
  Future<void> _shareFile(String filePath, String subject) async {
    try {
      print('🔄 Intentando compartir archivo: $filePath');

      // Verificar que el archivo existe
      final file = File(filePath);
      if (!file.existsSync()) {
        print('✗ El archivo no existe: $filePath');
        Get.snackbar(
          'Error',
          'El archivo no se creó correctamente',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 5),
        );
        return;
      }

      print('✓ Archivo encontrado: ${file.lengthSync()} bytes');

      final xfile = XFile(filePath);
      await Share.shareXFiles([xfile], subject: 'NovaPay - $subject', text: 'Reporte de caja exportado desde NovaPay');

      print('✓ Compartición iniciada correctamente');
    } catch (e) {
      print('✗ Error compartiendo archivo: $e');
      // Si falla la compartición, notificamos que se guardó el archivo
      Get.snackbar(
        'Archivo Guardado',
        'El JSON se guardó en: ${filePath.split('/').last}',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 5),
      );
    }
  }
}
