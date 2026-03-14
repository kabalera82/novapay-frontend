// lib/presentation/controllers/ticket_controller.dart
import 'package:get/get.dart';
import '../../data/models/ticket.dart';
import '../../data/models/ticket_line.dart';
import '../../services/ticket_service.dart';
import 'product_controller.dart';
import 'report_controller.dart';
import 'ticket_history_controller.dart';

class TicketController extends GetxController {
  final TicketService _service;
  TicketController(this._service);

  final openTickets   = <Ticket>[].obs;
  final parkedTickets = <Ticket>[].obs;
  final activeTicket  = Rxn<Ticket>();
  final isLoading     = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadTickets();
  }

  Future<void> loadTickets() async {
    try {
      isLoading.value = true;
      openTickets.value   = await _service.getOpen();
      parkedTickets.value = await _service.getParked();
    } catch (e) {
      Get.snackbar('Error', 'No se pudieron cargar los tickets');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> selectOrCreateTicket({
    int? tableNumber,
    String? zone,
    String? tableOrLabel,
  }) async {
    try {
      final existing = openTickets.firstWhereOrNull(
        (t) => t.tableNumber == tableNumber && t.zone == zone,
      );
      if (existing != null) {
        activeTicket.value = existing;
      } else {
        final ticket = await _service.create(
          tableNumber: tableNumber,
          zone: zone,
          tableOrLabel: tableOrLabel,
        );
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
      await _service.pay(activeTicket.value!, method);
      activeTicket.value = null;
      await loadTickets();
      Get.find<TicketHistoryController>().loadAll();
    } catch (e) {
      Get.snackbar('Error', 'No se pudo cobrar el ticket');
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

  Future<void> payLines(List<int> lineIndices, PaymentMethod method) async {
    if (activeTicket.value == null) return;
    try {
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
}
