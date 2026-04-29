// lib/presentation/controllers/ticket_controller.dart
import 'dart:async';
import 'dart:io';

import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../../data/models/ticket.dart';
import '../../data/models/ticket_line.dart';
import '../../data/models/fiscal_ticket_trace.dart';
import '../../data/models/verifactu_models.dart';
import '../../services/fiscal_ticket_trace_service.dart';
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
  static const String _aeatQrBaseUrl =
      'https://www2.agenciatributaria.gob.es/wlpl/inwinv/es/es.aeat.dit.adu.einv.qr.QRWidget?csv=';

  final TicketService _service;
  final VerifactuService _verifactuService;
  final ReceiptPrintService _receiptPrintService;
  final FiscalTicketTraceService _fiscalTraceService;

  TicketController(this._service, this._verifactuService, this._receiptPrintService, this._fiscalTraceService);

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

  Future<void> cancelActive() async {
    if (activeTicket.value == null) return;
    try {
      await _service.cancel(activeTicket.value!);
      activeTicket.value = null;
      await loadTickets();
      Get.find<TicketHistoryController>().loadAll();
      Get.find<ReportController>().loadLiveStats();
    } catch (e) {
      Get.snackbar('Error', 'No se pudo cancelar el ticket');
    }
  }

  Future<void> payLines(List<int> lineIndices, PaymentMethod method, {Map<int, int>? partialQtys}) async {
    if (activeTicket.value == null) return;
    try {
      final paidTicket = await _service.paySelectedLines(activeTicket.value!, lineIndices, method, partialQtys: partialQtys);
      
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

      // Emitir y imprimir el tiquet cobrado (sea parcial o total)
      await _emitAndPrint(paidTicket);
    } catch (e) {
      Get.snackbar('Error', 'No se pudo procesar el pago');
    }
  }

  Future<void> reprintTicket(Ticket ticket) async {
    try {
      final ticketToPrint = await _service.getById(ticket.id) ?? ticket;
      final trace = await _fiscalTraceService.getByTicketUuid(ticketToPrint.uuid);
      final ticketForPrint = _buildTicketForReprint(ticketToPrint, trace);

      final invoice = trace != null
          ? BackendInvoiceResponse(
              id: trace.invoiceId,
              series: trace.invoiceSeries,
              number: trace.invoiceNumber,
              type: 'SIMPLIFICADA',
              status: trace.printedFiscalStatus ?? trace.fiscalStatus ?? 'PENDIENTE',
              issueDate: trace.createdAt.toIso8601String(),
              totalAmount: trace.totalAmount,
            )
          : BackendInvoiceResponse(
              id: ticketForPrint.uuid,
              series: 'REIMP',
              number: ticketForPrint.id,
              type: 'SIMPLIFICADA',
              status: ticketForPrint.status.name.toUpperCase(),
              issueDate: ticketForPrint.createdAt.toIso8601String(),
              totalAmount: ticketForPrint.totalAmount,
            );

      await _receiptPrintService.printTicket(
        ticket: ticketForPrint,
        invoice: invoice,
        fiscalStatus: trace == null ? null : _fiscalStatusFromTrace(trace),
        provisionalQrPayload: trace?.printedQrPayload,
      );
    } catch (e) {
      Get.snackbar('Impresion', 'No se pudo reimprimir el ticket');
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
    var provisionalQrPayload = ticket.uuid;

    try {
      final InvoiceEmissionResult emission = await _verifactuService.emitTicket(ticket);
      invoiceForPrint = emission.invoice;
      fiscalStatus = emission.fiscalStatus;
      provisionalQrPayload = emission.invoice.id;
      await _fiscalTraceService.saveEmissionTrace(
        ticket: ticket,
        invoice: invoiceForPrint,
        fiscalStatus: fiscalStatus,
        printedFiscalStatus: fiscalStatus?.status ?? 'PENDIENTE_VALIDACION',
        printedQrPayload: _printedQrPayloadFromFiscalStatus(fiscalStatus, fallbackPayload: provisionalQrPayload),
        queueStatus: fiscalStatus == null ? 'PENDING' : 'FINAL',
      );
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
      final isOfflineLike = _isBackendUnavailableError(e);
      if (isOfflineLike) {
        invoiceForPrint = BackendInvoiceResponse(
          id: ticket.uuid,
          series: 'PEND',
          number: ticket.id,
          type: 'SIMPLIFICADA',
          status: 'PENDIENTE_ENVIO',
          issueDate: ticket.createdAt.toIso8601String(),
          totalAmount: ticket.totalAmount,
        );
        provisionalQrPayload = ticket.uuid;
        await _fiscalTraceService.saveEmissionTrace(
          ticket: ticket,
          invoice: invoiceForPrint,
          printedFiscalStatus: 'PENDIENTE_ENVIO',
          printedQrPayload: ticket.uuid,
          queueStatus: 'PENDING',
        );
        Get.find<VerifactuController>().refreshInteractions();
        Get.snackbar('Verifactu', 'Backend no disponible. El ticket queda pendiente de envío con QR provisional.');
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
            provisionalQrPayload: provisionalQrPayload,
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

  Ticket _buildTicketForReprint(Ticket ticket, FiscalTicketTrace? trace) {
    if (trace == null) {
      return _cloneTicket(ticket);
    }

    final ticketForPrint = _cloneTicket(ticket);
    if (ticketForPrint.lines.isEmpty && trace.lines.isNotEmpty) {
      ticketForPrint.lines = trace.lines
          .map(
            (line) => TicketLine()
              ..productName = line.productName
              ..quantity = line.quantity
              ..priceAtMoment = line.unitPrice
              ..totalLine = line.totalLine,
          )
          .toList();
      ticketForPrint.totalAmount = trace.totalAmount;
    }
    return ticketForPrint;
  }

  FiscalStatusResponse? _fiscalStatusFromTrace(FiscalTicketTrace trace) {
    final status = trace.printedFiscalStatus?.trim() ?? trace.fiscalStatus?.trim();
    if (status == null || status.isEmpty) {
      return null;
    }

    return FiscalStatusResponse(
      invoiceId: trace.invoiceId,
      status: status,
      retryCount: 0,
      responseCode: trace.responseCode,
      responseDescription: trace.responseDescription,
      secureVerificationCode: trace.secureVerificationCode,
      verificationUrl: trace.printedQrPayload ?? trace.verificationUrl,
    );
  }

  String? _printedQrPayloadFromFiscalStatus(FiscalStatusResponse? fiscalStatus, {String? fallbackPayload}) {
    if (fiscalStatus == null) {
      return fallbackPayload;
    }

    final url = fiscalStatus.verificationUrl?.trim();
    if (url != null && url.isNotEmpty) {
      return url;
    }

    final csv = fiscalStatus.secureVerificationCode?.trim();
    if (csv != null && csv.isNotEmpty) {
      return '$_aeatQrBaseUrl$csv';
    }

    return fallbackPayload;
  }

  bool _isBackendUnavailableError(Object error) {
    if (error is VerifactuLocalModeException) {
      return true;
    }
    if (error is TimeoutException || error is SocketException || error is http.ClientException) {
      return true;
    }
    if (error is VerifactuApiException) {
      return error.statusCode == null || error.statusCode! >= 500;
    }

    final text = error.toString().toLowerCase();
    return text.contains('socketexception') || text.contains('clientexception') || text.contains('timeoutexception');
  }
}
