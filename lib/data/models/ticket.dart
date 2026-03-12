// lib/data/models/ticket.dart
import 'package:isar/isar.dart';
import 'ticketLine.dart';

part 'ticket.g.dart';

enum TicketStatus { abierto, pagado, cancelado }
enum PaymentMethod { efectivo, tarjeta, mixto }

@collection
class Ticket {
  Id id = Isar.autoIncrement;
  late String uuid;
  late DateTime createdAt;
  TicketStatus status = TicketStatus.abierto;
  PaymentMethod paymentMethod = PaymentMethod.efectivo;
  double totalAmount = 0;
  int? tableNumber;
  String? tableOrLabel;
  bool isParked = false;
  String? zone;
  List<TicketLine> lines = [];
}
