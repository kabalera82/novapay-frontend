import 'package:isar/isar.dart';

part 'daily.report.g.dart';

@collection
class DailyReport {
  Id id = Isar.autoIncrement;
  late DateTime date;
  double totalCash = 0;
  double totalCard = 0;
  double grandTotal = 0;
  int ticketCount = 0;
  double totalExpenses = 0;
  List<String> soldProductsSummary = [];
}
