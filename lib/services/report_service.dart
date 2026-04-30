// lib/services/report_service.dart
import 'package:isar/isar.dart';
import '../data/models/daily_report.dart';
import '../data/models/expense.dart';
import '../data/models/ticket.dart';

class ReportService {
  final Isar _isar;
  ReportService(this._isar);

  DateTime _startOfDay(DateTime date) => DateTime(date.year, date.month, date.day);

  DateTime _endOfDay(DateTime date) => DateTime(date.year, date.month, date.day, 23, 59, 59);

  Future<DateTime> _resolveOpenPeriodStart() async {
    final lastClose = await getLatestClose();
    if (lastClose != null && lastClose.closedAt != null) {
      return lastClose.closedAt!;
    }

    final paidTickets = await _isar.tickets.filter().statusEqualTo(TicketStatus.pagado).sortByCreatedAt().findFirst();
    final expenses = await _isar.expenses.where().sortByDate().findFirst();

    DateTime? earliest;
    if (paidTickets != null) earliest = paidTickets.createdAt;
    if (expenses != null && (earliest == null || expenses.date.isBefore(earliest))) {
      earliest = expenses.date;
    }

    return earliest ?? _startOfDay(DateTime.now());
  }

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
        totalCash += ticket.mixedCashAmount;
        totalCard += ticket.mixedCardAmount;
      }
      for (final line in ticket.lines) {
        productCount[line.productName] = (productCount[line.productName] ?? 0) + line.quantity;
      }
    }

    final summary = productCount.entries.map((e) => '${e.key}:${e.value}').toList();

    // Include expenses
    final expenses = await _isar.expenses.filter().dateBetween(start, end).findAll();
    final totalExpenses = expenses.fold(0.0, (sum, e) => sum + e.amount);

    return DailyReport()
      ..date = _startOfDay(end == DateTime.now() ? end : start)
      ..totalCash = totalCash
      ..totalCard = totalCard
      ..grandTotal = totalCash + totalCard - totalExpenses
      ..ticketCount = tickets.length
      ..totalExpenses = totalExpenses
      ..soldProductsSummary = summary;
  }

  // ── Live stats (no save) ──────────────────────────────────────────────────

  Future<DailyReport> getLiveStats() async {
    final now = DateTime.now();
    final start = await _resolveOpenPeriodStart();
    final end = now;
    return await _buildStats(start, end);
  }

  // ── Close day (persists report with real expenses) ────────────────────────

  Future<DailyReport> closeDay() async {
    final now = DateTime.now();
    final start = await _resolveOpenPeriodStart();
    final end = now;

    final report = await _buildStats(start, end);
    report.date = _startOfDay(now);
    report.closedAt = now;

    await _isar.writeTxn(() async {
      await _isar.dailyReports.put(report);
    });

    return report;
  }

  // ── Queries ───────────────────────────────────────────────────────────────

  Future<DailyReport?> getByDate(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = DateTime(date.year, date.month, date.day, 23, 59, 59);
    return _isar.dailyReports.filter().dateBetween(start, end).findFirst();
  }

  Future<List<DailyReport>> getAll() async {
    return _isar.dailyReports.where().sortByDateDesc().findAll();
  }

  Future<DailyReport?> getLatestClose() async {
    return _isar.dailyReports.where().sortByClosedAtDesc().findFirst();
  }

  Future<DateTime> getLatestCloseTime() async {
    final last = await getLatestClose();
    if (last != null && last.closedAt != null) {
      return last.closedAt!;
    }
    final start = await _resolveOpenPeriodStart();
    return start;
  }
}
