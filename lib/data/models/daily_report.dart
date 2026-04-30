// lib/data/models/daily_report.dart
import 'package:isar/isar.dart';

part 'daily_report.g.dart';

@collection
class DailyReport {
  Id id = Isar.autoIncrement;

  @Index()
  late DateTime date;

  @Index()
  DateTime? closedAt;

  double totalCash      = 0;
  double totalCard      = 0;
  double grandTotal     = 0;
  int    ticketCount    = 0;
  double totalExpenses  = 0;
  List<String> soldProductsSummary = [];
}
