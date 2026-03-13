// lib/services/ticket.service.dart
import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';
import '../data/models/product.dart';
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

// UPDATE — pagar líneas seleccionadas (pago parcial o total)
// Si quedan líneas → ticket permanece abierto con las no pagadas.
// Si no quedan líneas → ticket se marca como pagado.
// Descuenta stock de los productos pagados.
Future<void> paySelectedLines(
  Isar isar,
  Ticket ticket,
  List<int> lineIndices,
  PaymentMethod method,
) async {
  final paidLines   = <TicketLine>[];
  final remaining   = <TicketLine>[];
  for (int i = 0; i < ticket.lines.length; i++) {
    if (lineIndices.contains(i)) {
      paidLines.add(ticket.lines[i]);
    } else {
      remaining.add(ticket.lines[i]);
    }
  }
  ticket.lines       = remaining;
  ticket.totalAmount = remaining.fold(0.0, (sum, l) => sum + l.totalLine);

  if (remaining.isEmpty) {
    ticket.status        = TicketStatus.pagado;
    ticket.paymentMethod = method;
    ticket.isParked      = false;
  }

  // Descontar stock de los productos vendidos
  final allProducts = await isar.products.where().findAll();
  await isar.writeTxn(() async {
    await isar.tickets.put(ticket);
    for (final line in paidLines) {
      final product = allProducts
          .where((p) => p.name == line.productName)
          .firstOrNull;
      if (product != null) {
        product.stock = (product.stock - line.quantity).clamp(0, 999999);
        await isar.products.put(product);
      }
    }
  });
}

// UPDATE — cambia la cantidad de una línea (+1 / -1). Si qty llega a 0 elimina la línea.
Future<void> updateLineQuantity(
  Isar isar,
  Ticket ticket,
  String productName,
  int delta, // +1 o -1
) async {
  final lines = List<TicketLine>.from(ticket.lines);
  final idx = lines.indexWhere((l) => l.productName == productName);
  if (idx < 0) return;
  lines[idx].quantity += delta;
  if (lines[idx].quantity <= 0) {
    lines.removeAt(idx);
  } else {
    lines[idx].totalLine = lines[idx].quantity * lines[idx].priceAtMoment;
  }
  ticket.lines = lines;
  ticket.totalAmount = lines.fold(0.0, (sum, l) => sum + l.totalLine);
  await isar.writeTxn(() async {
    await isar.tickets.put(ticket);
  });
}

// UPDATE — reabre un ticket pagado o cancelado
Future<void> reopenTicket(Isar isar, Ticket ticket) async {
  ticket.status   = TicketStatus.abierto;
  ticket.isParked = false;
  await isar.writeTxn(() async {
    await isar.tickets.put(ticket);
  });
}

// READ — todos los tickets sin filtro
Future<List<Ticket>> getAllTickets(Isar isar) async {
  return await isar.tickets.where().findAll();
}

// DELETE
Future<void> deleteTicket(Isar isar, int id) async {
  await isar.writeTxn(() async {
    await isar.tickets.delete(id);
  });
}