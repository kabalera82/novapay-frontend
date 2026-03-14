// lib/services/report_service.dart
import 'package:isar/isar.dart';
import '../data/models/daily_report.dart';
import '../data/models/expense.dart';
import '../data/models/ticket.dart';

class ReportService {
  final Isar _isar;
  ReportService(this._isar);

  // ── Helpers ───────────────────────────────────────────────────────────────

  Future<DailyReport> _buildStats(DateTime start, DateTime end) async {
    final tickets = await _isar.tickets
        .filter()
        .statusEqualTo(TicketStatus.pagado)
        .and()
        .createdAtBetween(start, end)
        .findAll();

    double totalCash = 0;
    double totalCard = 0;
    final Map<String, int> productCount = {};

    for (final ticket in tickets) {
      if (ticket.paymentMethod == PaymentMethod.efectivo) {
        totalCash += ticket.totalAmount;
      } else if (ticket.paymentMethod == PaymentMethod.tarjeta) {
        totalCard += ticket.totalAmount;
      } else {
        totalCash += ticket.totalAmount / 2;
        totalCard += ticket.totalAmount / 2;
      }
      for (final line in ticket.lines) {
        productCount[line.productName] =
            (productCount[line.productName] ?? 0) + line.quantity;
      }
    }

    final summary = productCount.entries
        .map((e) => '${e.key}:${e.value}')
        .toList();

    return DailyReport()
      ..date         = start
      ..totalCash    = totalCash
      ..totalCard    = totalCard
      ..grandTotal   = totalCash + totalCard
      ..ticketCount  = tickets.length
      ..totalExpenses = 0
      ..soldProductsSummary = summary;
  }

  // ── Live stats (no save) ──────────────────────────────────────────────────

  Future<DailyReport> getLiveStats() async {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    final end   = start.add(const Duration(days: 1));
    final report = await _buildStats(start, end);

    // Include today's expenses in live stats
    final expenses = await _isar.expenses
        .filter()
        .dateBetween(start, end)
        .findAll();
    final totalExpenses = expenses.fold(0.0, (sum, e) => sum + e.amount);
    report.totalExpenses = totalExpenses;
    report.grandTotal    = report.totalCash + report.totalCard - totalExpenses;

    return report;
  }

  // ── Close day (persists report with real expenses) ────────────────────────

  Future<DailyReport> closeDay() async {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    final end   = start.add(const Duration(days: 1));

    final report = await _buildStats(start, end);

    // Query actual expenses for today
    final expenses = await _isar.expenses
        .filter()
        .dateBetween(start, end)
        .findAll();
    final totalExpenses =
        expenses.fold(0.0, (sum, e) => sum + e.amount);

    report
      ..date          = today
      ..totalExpenses = totalExpenses
      ..grandTotal    = report.totalCash + report.totalCard - totalExpenses;

    await _isar.writeTxn(() async {
      await _isar.dailyReports.put(report);
    });

    return report;
  }

  // ── Queries ───────────────────────────────────────────────────────────────

  Future<DailyReport?> getByDate(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end   = DateTime(date.year, date.month, date.day, 23, 59, 59);
    return _isar.dailyReports
        .filter()
        .dateBetween(start, end)
        .findFirst();
  }

  Future<List<DailyReport>> getAll() async {
    return _isar.dailyReports
        .where()
        .sortByDateDesc()
        .findAll();
  }
}
