// lib/presentation/controllers/ticket_controller.dart
import 'package:get/get.dart';
import '../../data/models/ticket.dart';
import '../../data/models/ticket_line.dart';
import '../../data/models/verifactu_models.dart';
import '../../services/receipt_print_service.dart';
import '../../services/ticket_service.dart';
import '../../services/verifactu_service.dart';
import 'product_controller.dart';
import 'report_controller.dart';
import 'ticket_history_controller.dart';
import 'verifactu_controller.dart';

class TicketController extends GetxController {
  static const bool _autoPrintAfterEmission = bool.fromEnvironment(
    'NOVAPAY_AUTO_PRINT_AFTER_EMISSION',
    defaultValue: true,
  );

  final TicketService _service;
  final VerifactuService _verifactuService;
  final ReceiptPrintService _receiptPrintService;

  TicketController(this._service, this._verifactuService, this._receiptPrintService);

  final openTickets = <Ticket>[].obs;
  final parkedTickets = <Ticket>[].obs;
  final activeTicket = Rxn<Ticket>();
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadTickets();
  }

  Future<void> loadTickets() async {
    try {
      isLoading.value = true;
      openTickets.value = await _service.getOpen();
      parkedTickets.value = await _service.getParked();
    } catch (e) {
      Get.snackbar('Error', 'No se pudieron cargar los tickets');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> selectOrCreateTicket({int? tableNumber, String? zone, String? tableOrLabel}) async {
    try {
      final existing = openTickets.firstWhereOrNull((t) => t.tableNumber == tableNumber && t.zone == zone);
      if (existing != null) {
        activeTicket.value = existing;
      } else {
        final ticket = await _service.create(tableNumber: tableNumber, zone: zone, tableOrLabel: tableOrLabel);
        activeTicket.value = ticket;
        await loadTickets();
      }
    } catch (e) {
      Get.snackbar('Error', 'No se pudo abrir el ticket');
    }
  }

  Future<void> addLineToActive(TicketLine line) async {
    if (activeTicket.value == null) return;
    try {
      await _service.addLine(activeTicket.value!, line);
      activeTicket.value = await _service.getById(activeTicket.value!.id);
      await loadTickets();
    } catch (e) {
      Get.snackbar('Error', 'No se pudo añadir la línea');
    }
  }

  Future<void> removeLineFromActive(String productName) async {
    if (activeTicket.value == null) return;
    try {
      await _service.removeLine(activeTicket.value!, productName);
      activeTicket.value = await _service.getById(activeTicket.value!.id);
      await loadTickets();
    } catch (e) {
      Get.snackbar('Error', 'No se pudo eliminar la línea');
    }
  }

  Future<void> parkActive() async {
    if (activeTicket.value == null) return;
    try {
      await _service.toggleParked(activeTicket.value!);
      activeTicket.value = null;
      await loadTickets();
    } catch (e) {
      Get.snackbar('Error', 'No se pudo aparcar el ticket');
    }
  }

  Future<void> unparkTicket(Ticket ticket) async {
    try {
      await _service.toggleParked(ticket);
      activeTicket.value = ticket;
      await loadTickets();
    } catch (e) {
      Get.snackbar('Error', 'No se pudo recuperar el ticket');
    }
  }

  Future<void> payActive(PaymentMethod method) async {
    if (activeTicket.value == null) return;
    try {
      final ticketForReceipt = _cloneTicket(activeTicket.value!);
      await _service.pay(activeTicket.value!, method);
      activeTicket.value = null;
      await loadTickets();
      Get.find<TicketHistoryController>().loadAll();
      await _emitAndPrint(ticketForReceipt);
    } catch (e) {
      Get.snackbar('Error', 'No se pudo cobrar el ticket');
    }
  }

  Future<void> reprintTicket(Ticket ticket) async {
    try {
      await _receiptPrintService.printTicket(
        ticket: ticket,
        invoice: BackendInvoiceResponse(
          id: ticket.uuid,
          series: 'TICKET',
          number: ticket.id,
          type: 'SIMPLIFICADA',
          status: 'REIMPRESION',
          issueDate: ticket.createdAt.toIso8601String(),
          totalAmount: ticket.totalAmount,
        ),
        fiscalStatus: null,
      );
      Get.snackbar('Impresion', 'Ticket reimpreso correctamente.');
    } catch (e) {
      Get.snackbar('Impresion', 'No se pudo reimprimir el ticket: $e');
    }
  }

  Future<void> cancelActive() async {
    if (activeTicket.value == null) return;
    try {
      await _service.cancel(activeTicket.value!);
      activeTicket.value = null;
      await loadTickets();
      Get.find<TicketHistoryController>().loadAll();
    } catch (e) {
      Get.snackbar('Error', 'No se pudo cancelar el ticket');
    }
  }

  Future<void> payLines(List<int> lineIndices, PaymentMethod method, {double? cashGiven, double? cashChange}) async {
    if (activeTicket.value == null) return;
    try {
      final current = activeTicket.value!;
      final isFullPayment = lineIndices.length == current.lines.length;
      final ticketForReceipt = _cloneTicket(current);

      await _service.paySelectedLines(activeTicket.value!, lineIndices, method);
      final updated = await _service.getById(activeTicket.value!.id);
      if (updated == null || updated.status == TicketStatus.pagado) {
        activeTicket.value = null;
      } else {
        activeTicket.value = updated;
      }
      await loadTickets();
      // Refresh product stock, live balance and ticket history after payment
      Get.find<ProductController>().loadAll();
      Get.find<ReportController>().loadLiveStats();
      Get.find<TicketHistoryController>().loadAll();
      if (isFullPayment) {
        await _emitAndPrint(ticketForReceipt, cashGiven: cashGiven, cashChange: cashChange);
      }
    } catch (e) {
      Get.snackbar('Error', 'No se pudo procesar el pago');
    }
  }

  Future<void> changeLineQuantity(String productName, int delta) async {
    if (activeTicket.value == null) return;
    try {
      await _service.updateLineQuantity(activeTicket.value!, productName, delta);
      activeTicket.value = await _service.getById(activeTicket.value!.id);
      await loadTickets();
    } catch (e) {
      Get.snackbar('Error', 'No se pudo cambiar la cantidad');
    }
  }

  void clearActive() => activeTicket.value = null;

  Future<List<Ticket>> todayTickets() async {
    try {
      return await _service.getByDate(DateTime.now());
    } catch (e) {
      Get.snackbar('Error', 'No se pudieron cargar los tickets del día');
      return [];
    }
  }

  Future<void> _emitAndPrint(Ticket ticket, {double? cashGiven, double? cashChange}) async {
    BackendInvoiceResponse invoiceForPrint = BackendInvoiceResponse(
      id: ticket.uuid,
      series: 'DEMO',
      number: ticket.id,
      type: 'SIMPLIFICADA',
      status: 'LOCAL_DEMO',
      issueDate: ticket.createdAt.toIso8601String(),
      totalAmount: ticket.totalAmount,
    );

    FiscalStatusResponse? fiscalStatus;
    var shouldPrint = _autoPrintAfterEmission;

    try {
      final InvoiceEmissionResult emission = await _verifactuService.emitTicket(ticket);
      invoiceForPrint = emission.invoice;
      fiscalStatus = emission.fiscalStatus;
      Get.find<VerifactuController>().refreshInteractions();
      if (fiscalStatus == null) {
        Get.snackbar('Verifactu', 'Ticket enviado al backend. Esperando respuesta fiscal de AEAT.');
      } else if (fiscalStatus.status == 'ACEPTADO') {
        final printMsg = shouldPrint ? ' Se imprimirá ticket.' : ' Impresión automática desactivada.';
        Get.snackbar('Verifactu', 'Ticket aceptado por AEAT.$printMsg');
      } else if (_isExpectedInvalidSignature(fiscalStatus)) {
        Get.snackbar(
          'Verifactu',
          'AEAT rechazó la firma (esperado en entorno actual con certificado personal). '
              'Ticket emitido sin QR oficial hasta disponer de certificado empresarial.',
        );
      } else {
        final code = fiscalStatus.responseCode != null ? ' [${fiscalStatus.responseCode}]' : '';
        final description = (fiscalStatus.responseDescription ?? '').trim();
        final detail = description.isNotEmpty ? ': $description' : '';
        Get.snackbar('Verifactu', 'Respuesta fiscal ${fiscalStatus.status}$code$detail');
      }
    } catch (e) {
      if (e is VerifactuLocalModeException) {
        Get.snackbar('Verifactu', e.message);
      } else {
        shouldPrint = false;
        final details = switch (e) {
          VerifactuApiException() => e.toString(),
          _ => e.toString(),
        };
        Get.snackbar('Verifactu', 'Fallo envio fiscal. No se imprimirá automático. $details');
      }
    } finally {
      if (shouldPrint) {
        try {
          await _receiptPrintService.printTicket(
            ticket: ticket,
            invoice: invoiceForPrint,
            fiscalStatus: fiscalStatus,
            cashGiven: cashGiven,
            cashChange: cashChange,
          );
        } catch (printError) {
          Get.snackbar('Impresion', 'No se pudo abrir el PDF: $printError');
        }
      }
    }
  }

  bool _isExpectedInvalidSignature(FiscalStatusResponse fiscalStatus) {
    final description = (fiscalStatus.responseDescription ?? '').toLowerCase();
    return fiscalStatus.status == 'RECHAZADO' &&
        description.contains('firma') &&
        (description.contains('inval') || description.contains('incorrect') || description.contains('no valida'));
  }

  Ticket _cloneTicket(Ticket source) {
    final cloned = Ticket()
      ..id = source.id
      ..uuid = source.uuid
      ..createdAt = source.createdAt
      ..status = source.status
      ..paymentMethod = source.paymentMethod
      ..totalAmount = source.totalAmount
      ..tableNumber = source.tableNumber
      ..tableOrLabel = source.tableOrLabel
      ..isParked = source.isParked
      ..zone = source.zone;

    cloned.lines = source.lines
        .map(
          (line) => TicketLine()
            ..productName = line.productName
            ..productId = line.productId
            ..quantity = line.quantity
            ..priceAtMoment = line.priceAtMoment
            ..totalLine = line.totalLine,
        )
        .toList();

    return cloned;
  }
}
