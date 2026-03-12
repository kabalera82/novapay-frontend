// lib/data/models/ticketLine.dart
import 'package:isar/isar.dart';

@embedded
class TicketLine {
  late String productName;
  int quantity = 1;
  double priceAtMoment = 0;
  double totalLine = 0;
}

