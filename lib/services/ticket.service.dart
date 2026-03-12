// lib/services/ticket.service.dart
import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';
import '../data/models/ticket.dart';
import '../data/models/ticketLine.dart';

const _uuid = Uuid();

// CREATE — abre un nuevo ticket
Future<Ticket> createTicket(Isar isar, {int? tableNumber, String? zone, String? tableOrLabel}) async {
  final ticket = Ticket()
    ..uuid = _uuid.v4()
    ..createdAt = DateTime.now()
    ..status = TicketStatus.abierto
    ..paymentMethod = PaymentMethod.efectivo
    ..totalAmount = 0
    ..tableNumber = tableNumber
    ..zone = zone
    ..tableOrLabel = tableOrLabel
    ..isParked = false
    ..lines = [];

  await isar.writeTxn(() async {
    await isar.tickets.put(ticket);
  });
  return ticket;
}

// READ — por id
Future<Ticket?> getTicketById(Isar isar, int id) async {
  return await isar.tickets.get(id);
}

// READ — todos los tickets abiertos
Future<List<Ticket>> getOpenTickets(Isar isar) async {
  final all = await isar.tickets.where().findAll();
  return all.where((t) => t.status == TicketStatus.abierto).toList();
}

// READ — tickets aparcados
Future<List<Ticket>> getParkedTickets(Isar isar) async {
  final all = await isar.tickets.where().findAll();
  return all.where((t) => t.isParked).toList();
}

// READ — tickets del día
Future<List<Ticket>> getTicketsByDate(Isar isar, DateTime date) async {
  final start = DateTime(date.year, date.month, date.day);
  final end = start.add(const Duration(days: 1));
  final all = await isar.tickets.where().findAll();
  return all.where((t) =>
    t.createdAt.isAfter(start) && t.createdAt.isBefore(end)
  ).toList();
}

// UPDATE — añade una línea al ticket
Future<void> addLine(Isar isar, Ticket ticket, TicketLine line) async {
  final lines = List<TicketLine>.from(ticket.lines);
  // Si ya existe el producto, incrementa cantidad
  final existing = lines.indexWhere((l) => l.productName == line.productName);
  if (existing >= 0) {
    lines[existing].quantity += line.quantity;
    lines[existing].totalLine = lines[existing].quantity * lines[existing].priceAtMoment;
  } else {
    lines.add(line);
  }
  ticket.lines = lines;
  ticket.totalAmount = lines.fold(0, (sum, l) => sum + l.totalLine);
  await isar.writeTxn(() async {
    await isar.tickets.put(ticket);
  });
}

// UPDATE — elimina una línea del ticket
Future<void> removeLine(Isar isar, Ticket ticket, String productName) async {
  ticket.lines = ticket.lines.where((l) => l.productName != productName).toList();
  ticket.totalAmount = ticket.lines.fold(0, (sum, l) => sum + l.totalLine);
  await isar.writeTxn(() async {
    await isar.tickets.put(ticket);
  });
}

// UPDATE — aparcar / desaparcar ticket
Future<void> toggleParked(Isar isar, Ticket ticket) async {
  ticket.isParked = !ticket.isParked;
  await isar.writeTxn(() async {
    await isar.tickets.put(ticket);
  });
}

// UPDATE — cobrar ticket
Future<void> payTicket(Isar isar, Ticket ticket, PaymentMethod method) async {
  ticket.status = TicketStatus.pagado;
  ticket.paymentMethod = method;
  ticket.isParked = false;
  await isar.writeTxn(() async {
    await isar.tickets.put(ticket);
  });
}

// UPDATE — cancelar ticket
Future<void> cancelTicket(Isar isar, Ticket ticket) async {
  ticket.status = TicketStatus.cancelado;
  await isar.writeTxn(() async {
    await isar.tickets.put(ticket);
  });
}

// DELETE
Future<void> deleteTicket(Isar isar, int id) async {
  await isar.writeTxn(() async {
    await isar.tickets.delete(id);
  });
}