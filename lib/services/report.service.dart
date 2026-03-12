// lib/services/report.service.dart
import 'package:isar/isar.dart';
import '../data/models/daily.report.dart';
import '../data/models/ticket.dart';

// Genera y guarda el cierre de jornada del día actual
Future<DailyReport> closeDailyReport(Isar isar) async {
  final today = DateTime.now();
  final start = DateTime(today.year, today.month, today.day);
  final end = start.add(const Duration(days: 1));

  final allTickets = await isar.tickets.where().findAll();
  final tickets = allTickets.where((t) =>
    t.status == TicketStatus.pagado &&
    t.createdAt.isAfter(start) &&
    t.createdAt.isBefore(end)
  ).toList();

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

  final report = DailyReport()
    ..date = today
    ..totalCash = totalCash
    ..totalCard = totalCard
    ..grandTotal = totalCash + totalCard
    ..ticketCount = tickets.length
    ..totalExpenses = 0
    ..soldProductsSummary = summary;

  await isar.writeTxn(() async {
    await isar.dailyReports.put(report);
  });

  return report;
}

// READ — reporte de un día concreto
Future<DailyReport?> getReportByDate(Isar isar, DateTime date) async {
  final start = DateTime(date.year, date.month, date.day);
  final end = start.add(const Duration(days: 1));
  final all = await isar.dailyReports.where().findAll();
  try {
    return all.firstWhere((r) => r.date.isAfter(start) && r.date.isBefore(end));
  } catch (_) {
    return null;
  }
}

// READ — todos los reportes ordenados por fecha desc
Future<List<DailyReport>> getAllReports(Isar isar) async {
  final all = await isar.dailyReports.where().findAll();
  all.sort((a, b) => b.date.compareTo(a.date));
  return all;
}

// UPDATE — añadir gasto manual al reporte del día
Future<void> addExpense(Isar isar, double amount) async {
  final report = await getReportByDate(isar, DateTime.now());
  if (report == null) return;
  report.totalExpenses += amount;
  report.grandTotal = report.totalCash + report.totalCard - report.totalExpenses;
  await isar.writeTxn(() async {
    await isar.dailyReports.put(report);
  });
}