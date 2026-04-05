// lib/services/ticket_service.dart
import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';
import '../data/models/product.dart';
import '../data/models/ticket.dart';
import '../data/models/ticket_line.dart';

class TicketService {
  final Isar _isar;
  TicketService(this._isar);

  static const _uuid = Uuid();

  Future<Ticket> create({int? tableNumber, String? zone, String? tableOrLabel}) async {
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

    await _isar.writeTxn(() async {
      await _isar.tickets.put(ticket);
    });
    return ticket;
  }

  Future<Ticket?> getById(int id) async {
    return _isar.tickets.get(id);
  }

  Future<List<Ticket>> getOpen() async {
    return _isar.tickets.filter().statusEqualTo(TicketStatus.abierto).sortByCreatedAtDesc().findAll();
  }

  Future<List<Ticket>> getParked() async {
    return _isar.tickets.filter().isParkedEqualTo(true).sortByCreatedAtDesc().findAll();
  }

  Future<List<Ticket>> getByDate(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return _isar.tickets.filter().createdAtBetween(start, end).sortByCreatedAtDesc().findAll();
  }

  Future<List<Ticket>> getAll() async {
    return _isar.tickets.where().sortByCreatedAtDesc().findAll();
  }

  Future<void> addLine(Ticket ticket, TicketLine line) async {
    final lines = List<TicketLine>.from(ticket.lines);
    final existing = lines.indexWhere((l) => l.productName == line.productName);
    if (existing >= 0) {
      lines[existing].quantity += line.quantity;
      lines[existing].totalLine = lines[existing].quantity * lines[existing].priceAtMoment;
    } else {
      lines.add(line);
    }
    ticket.lines = lines;
    ticket.totalAmount = lines.fold(0, (sum, l) => sum + l.totalLine);
    await _isar.writeTxn(() async {
      await _isar.tickets.put(ticket);
    });
  }

  Future<void> removeLine(Ticket ticket, String productName) async {
    ticket.lines = ticket.lines.where((l) => l.productName != productName).toList();
    ticket.totalAmount = ticket.lines.fold(0, (sum, l) => sum + l.totalLine);
    await _isar.writeTxn(() async {
      await _isar.tickets.put(ticket);
    });
  }

  Future<void> toggleParked(Ticket ticket) async {
    ticket.isParked = !ticket.isParked;
    await _isar.writeTxn(() async {
      await _isar.tickets.put(ticket);
    });
  }

  Future<void> pay(Ticket ticket, PaymentMethod method) async {
    ticket.status = TicketStatus.pagado;
    ticket.paymentMethod = method;
    ticket.isParked = false;
    await _isar.writeTxn(() async {
      await _isar.tickets.put(ticket);
    });
  }

  Future<void> cancel(Ticket ticket) async {
    ticket.status = TicketStatus.cancelado;
    await _isar.writeTxn(() async {
      await _isar.tickets.put(ticket);
    });
  }

  Future<void> paySelectedLines(Ticket ticket, List<int> lineIndices, PaymentMethod method) async {
    final paidLines = <TicketLine>[];
    final remaining = <TicketLine>[];
    for (int i = 0; i < ticket.lines.length; i++) {
      if (lineIndices.contains(i)) {
        paidLines.add(ticket.lines[i]);
      } else {
        remaining.add(ticket.lines[i]);
      }
    }

    if (remaining.isEmpty) {
      // Fully paid — keep lines intact for history, just change status
      ticket.status = TicketStatus.pagado;
      ticket.paymentMethod = method;
      ticket.isParked = false;
      // ticket.lines and ticket.totalAmount stay as-is (full history preserved)
    } else {
      // Partial payment — remove paid lines, keep the rest
      ticket.lines = remaining;
      ticket.totalAmount = remaining.fold(0.0, (sum, l) => sum + l.totalLine);
    }

    final allProducts = await _isar.products.where().findAll();
    await _isar.writeTxn(() async {
      await _isar.tickets.put(ticket);
      for (final line in paidLines) {
        final product = allProducts.where((p) => p.name == line.productName).firstOrNull;
        if (product != null) {
          final isUnlimited = product.stock > 100 || product.stock < 0;
          if (!isUnlimited) {
            product.stock = (product.stock - line.quantity).clamp(0, 999999);
            await _isar.products.put(product);
          }
        }
      }
    });
  }

  Future<void> updateLineQuantity(Ticket ticket, String productName, int delta) async {
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
    await _isar.writeTxn(() async {
      await _isar.tickets.put(ticket);
    });
  }

  Future<void> reopen(Ticket ticket) async {
    ticket.status = TicketStatus.abierto;
    ticket.isParked = false;
    await _isar.writeTxn(() async {
      await _isar.tickets.put(ticket);
    });
  }

  Future<void> delete(int id) async {
    await _isar.writeTxn(() async {
      await _isar.tickets.delete(id);
    });
  }

  Future<void> updatePaymentMethod(Ticket ticket, PaymentMethod method) async {
    ticket.paymentMethod = method;
    await _isar.writeTxn(() async {
      await _isar.tickets.put(ticket);
    });
  }

  /// Corrige un ticket ya cerrado (pagado/cancelado).
  /// Mantiene únicamente las líneas seleccionadas como las lineas finales cobradas,
  /// recalcula el totalAmount y cierra el ticket como [pagado].
  /// NO descuenta stock (ya fue descontado en el cobro original).
  Future<void> correctPayment(Ticket ticket, List<int> lineIndices, PaymentMethod method) async {
    final finalLines = [
      for (int i = 0; i < ticket.lines.length; i++)
        if (lineIndices.contains(i)) ticket.lines[i],
    ];
    ticket.lines = finalLines;
    ticket.totalAmount = finalLines.fold(0.0, (sum, l) => sum + l.totalLine);
    ticket.status = TicketStatus.pagado;
    ticket.paymentMethod = method;
    ticket.isParked = false;
    await _isar.writeTxn(() async {
      await _isar.tickets.put(ticket);
    });
  }
}
