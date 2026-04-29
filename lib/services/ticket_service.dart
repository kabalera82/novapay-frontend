// lib/services/ticket_service.dart
import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';
import '../data/models/fiscal_ticket_trace.dart';
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

  Future<Ticket?> getByUuid(String uuid) async {
    return _isar.tickets.filter().uuidEqualTo(uuid).findFirst();
  }

  /// Tickets activos NO aparcados (mesas abiertas en sala).
  Future<List<Ticket>> getOpen() async {
    return _isar.tickets
        .filter()
        .statusEqualTo(TicketStatus.abierto)
        .isParkedEqualTo(false)
        .findAll();
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

  /// Devuelve solo tickets cerrados (pagado o cancelado), ordenados por fecha desc.
  /// Usado por el historial: los tickets abiertos pertenecen a la sala.
  Future<List<Ticket>> getClosed() async {
    return _isar.tickets
        .filter()
        .statusEqualTo(TicketStatus.pagado)
        .or()
        .statusEqualTo(TicketStatus.cancelado)
        .sortByCreatedAtDesc()
        .findAll();
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

  /// Pago total de un ticket (todas sus líneas).
  /// Decrementa el stock de todos los productos incluidos.
  Future<void> pay(Ticket ticket, PaymentMethod method) async {
    ticket.status        = TicketStatus.pagado;
    ticket.paymentMethod = method;
    ticket.isParked      = false;

    final affectedIds = ticket.lines.map((l) => l.productId).toSet().toList();
    final affectedProducts = await _isar.products
        .where()
        .findAll()
        .then((all) => all.where((p) => affectedIds.contains(p.id)).toList());

    await _isar.writeTxn(() async {
      await _isar.tickets.put(ticket);
      for (final line in ticket.lines) {
        _decrementStock(affectedProducts, line);
      }
      for (final p in affectedProducts) {
        await _isar.products.put(p);
      }
    });
  }

  Future<void> cancel(Ticket ticket) async {
    ticket.status = TicketStatus.cancelado;
    await _isar.writeTxn(() async {
      await _isar.tickets.put(ticket);
    });
  }

  /// Paga las líneas indicadas por índice.
  /// [partialQtys] permite indicar cuántas unidades se pagan por línea
  /// (clave = índice de línea, valor = cantidad a pagar).
  /// Si no se especifica para una línea, se paga la cantidad completa.
  Future<Ticket> paySelectedLines(
    Ticket ticket,
    List<int> lineIndices,
    PaymentMethod method, {
    Map<int, int>? partialQtys,
    double mixedCashAmount = 0,
    double mixedCardAmount = 0,
  }) async {
    final paidLines = <TicketLine>[];
    final remaining = <TicketLine>[];

    for (int i = 0; i < ticket.lines.length; i++) {
      if (!lineIndices.contains(i)) {
        remaining.add(ticket.lines[i]);
        continue;
      }

      final line      = ticket.lines[i];
      final qtyToPay  = (partialQtys?[i] ?? line.quantity).clamp(1, line.quantity);

      if (qtyToPay >= line.quantity) {
        // Línea completa cobrada
        paidLines.add(line);
      } else {
        // Pago parcial: registrar la parte cobrada y dejar el resto
        final paid = TicketLine()
          ..productName   = line.productName
          ..productId     = line.productId
          ..quantity      = qtyToPay
          ..priceAtMoment = line.priceAtMoment
          ..totalLine     = line.priceAtMoment * qtyToPay;
        paidLines.add(paid);

        final rest = TicketLine()
          ..productName   = line.productName
          ..productId     = line.productId
          ..quantity      = line.quantity - qtyToPay
          ..priceAtMoment = line.priceAtMoment
          ..totalLine     = line.priceAtMoment * (line.quantity - qtyToPay);
        remaining.add(rest);
      }
    }

    // Leer stock antes de la transacción de escritura
    final affectedIds      = paidLines.map((l) => l.productId).toSet().toList();
    final affectedProducts = await _isar.products
        .where()
        .findAll()
        .then((all) => all.where((p) => affectedIds.contains(p.id)).toList());

    if (remaining.isEmpty) {
      // ── Pago TOTAL ────────────────────────────────────────────────────────
      // El ticket original queda como registro histórico completo.
      ticket.status          = TicketStatus.pagado;
      ticket.paymentMethod   = method;
      ticket.mixedCashAmount = mixedCashAmount;
      ticket.mixedCardAmount = mixedCardAmount;
      ticket.isParked        = false;
      // ticket.lines y totalAmount se mantienen (historial íntegro)

      await _isar.writeTxn(() async {
        await _isar.tickets.put(ticket);
        for (final line in paidLines) {
          _decrementStock(affectedProducts, line);
        }
        for (final p in affectedProducts) {
          await _isar.products.put(p);
        }
      });
      return ticket;
    } else {
      // ── Pago PARCIAL ──────────────────────────────────────────────────────
      // Se crea un ticket cerrado con las líneas cobradas como registro
      // histórico. El ticket original sigue abierto con las líneas pendientes.
      final paymentRecord = Ticket()
        ..uuid               = _uuid.v4()
        ..parentTicketUuid   = ticket.uuid   // vincula al ticket padre
        ..createdAt          = DateTime.now()
        ..status             = TicketStatus.pagado
        ..paymentMethod      = method
        ..mixedCashAmount    = mixedCashAmount
        ..mixedCardAmount    = mixedCardAmount
        ..tableNumber        = ticket.tableNumber
        ..zone               = ticket.zone
        ..tableOrLabel       = ticket.tableOrLabel
        ..isParked           = false
        ..totalAmount        = paidLines.fold(0.0, (s, l) => s + l.totalLine)
        ..lines              = paidLines;

      ticket.lines       = remaining;
      ticket.totalAmount = remaining.fold(0.0, (s, l) => s + l.totalLine);

      await _isar.writeTxn(() async {
        await _isar.tickets.put(paymentRecord); // registro histórico cerrado
        await _isar.tickets.put(ticket);         // ticket abierto con resto
        for (final line in paidLines) {
          _decrementStock(affectedProducts, line);
        }
        for (final p in affectedProducts) {
          await _isar.products.put(p);
        }
      });
      return paymentRecord;
    }
  }

  /// Decrementa el stock del producto asociado a [line] en la lista en memoria.
  /// La escritura a Isar la hace el llamador dentro de writeTxn.
  void _decrementStock(List<Product> products, TicketLine line) {
    final idx = products.indexWhere((p) => p.id == line.productId);
    if (idx >= 0 && products[idx].stock > 0) {
      products[idx].stock =
          (products[idx].stock - line.quantity).clamp(0, 999999);
    }
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
  Future<void> correctPayment(
    Ticket ticket,
    List<int> lineIndices,
    PaymentMethod method, {
    double mixedCashAmount = 0,
    double mixedCardAmount = 0,
  }) async {
    final finalLines = [
      for (int i = 0; i < ticket.lines.length; i++)
        if (lineIndices.contains(i)) ticket.lines[i],
    ];
    ticket.lines = finalLines;
    ticket.totalAmount = finalLines.fold(0.0, (sum, l) => sum + l.totalLine);
    ticket.status = TicketStatus.pagado;
    ticket.paymentMethod = method;
    ticket.mixedCashAmount = mixedCashAmount;
    ticket.mixedCardAmount = mixedCardAmount;
    ticket.isParked = false;
    await _isar.writeTxn(() async {
      await _isar.tickets.put(ticket);
    });
  }

  Future<Ticket> createFromFiscalTrace(FiscalTicketTrace trace) async {
    final ticket = Ticket()
      ..uuid = _uuid.v4()
      ..createdAt = DateTime.now()
      ..status = TicketStatus.pagado
      ..paymentMethod = _parsePaymentMethod(trace.paymentMethod)
      ..tableNumber = trace.ticketTableNumber
      ..tableOrLabel = trace.ticketTableLabel
      ..zone = trace.ticketZone
      ..isParked = false
      ..lines = trace.lines
          .map(
            (line) => TicketLine()
              ..productName = line.productName
              ..quantity = line.quantity
              ..priceAtMoment = line.unitPrice
              ..totalLine = line.totalLine,
          )
          .toList();

    ticket.totalAmount = ticket.lines.fold(0.0, (sum, line) => sum + line.totalLine);

    await _isar.writeTxn(() async {
      await _isar.tickets.put(ticket);
    });

    return ticket;
  }

  PaymentMethod _parsePaymentMethod(String? raw) {
    switch (raw) {
      case 'tarjeta':
        return PaymentMethod.tarjeta;
      case 'mixto':
        return PaymentMethod.mixto;
      case 'efectivo':
      default:
        return PaymentMethod.efectivo;
    }
  }
}
