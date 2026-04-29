// lib/presentation/controllers/ticket_history_controller.dart
import 'package:get/get.dart';
import '../../data/models/ticket.dart';
import '../../data/models/ticket_line.dart';
import '../../services/ticket_service.dart';
import 'report_controller.dart';

class TicketHistoryController extends GetxController {
  final TicketService _service;
  TicketHistoryController(this._service);

  final allTickets   = <Ticket>[].obs;
  final isLoading    = false.obs;

  /// Ticket que se está editando para corrección desde el historial.
  /// null cuando no hay ninguna corrección en curso.
  final editingTicket = Rxn<Ticket>();

  @override
  void onInit() {
    super.onInit();
    loadAll();
  }

  Future<void> loadAll() async {
    try {
      isLoading.value  = true;
      // Solo tickets cerrados (pagado/cancelado).
      // Los tickets abiertos son mesas activas y pertenecen a la sección Sala.
      allTickets.value = await _service.getClosed();
    } catch (e) {
      Get.snackbar('Error', 'No se pudo cargar el historial');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteById(int id) async {
    try {
      await _service.delete(id);
      await loadAll();
    } catch (e) {
      Get.snackbar('Error', 'No se pudo eliminar el ticket');
    }
  }

  Future<void> changePaymentMethod(Ticket ticket, PaymentMethod method) async {
    try {
      await _service.updatePaymentMethod(ticket, method);
      await loadAll();
    } catch (e) {
      Get.snackbar('Error', 'No se pudo cambiar el método de pago');
    }
  }

  // ── Corrección de cobro desde historial ────────────────────────────────────

  /// Inicia la edición de un ticket cerrado.
  /// Carga la copia más reciente de Isar y la expone en [editingTicket].
  Future<void> startEditing(Ticket ticket) async {
    try {
      editingTicket.value = await _service.getById(ticket.id);
    } catch (e) {
      Get.snackbar('Error', 'No se pudo cargar el ticket para edición');
    }
  }

  /// Limpia el ticket en edición (al cerrar el panel sin completar).
  void stopEditing() {
    editingTicket.value = null;
  }

  Future<void> addLineToEditing(TicketLine line) async {
    if (editingTicket.value == null) return;
    try {
      await _service.addLine(editingTicket.value!, line);
      editingTicket.value = await _service.getById(editingTicket.value!.id);
    } catch (e) {
      Get.snackbar('Error', 'No se pudo añadir la línea');
    }
  }

  Future<void> removeLineFromEditing(String productName) async {
    if (editingTicket.value == null) return;
    try {
      await _service.removeLine(editingTicket.value!, productName);
      editingTicket.value = await _service.getById(editingTicket.value!.id);
    } catch (e) {
      Get.snackbar('Error', 'No se pudo eliminar la línea');
    }
  }

  Future<void> changeLineQtyInEditing(String productName, int delta) async {
    if (editingTicket.value == null) return;
    try {
      await _service.updateLineQuantity(editingTicket.value!, productName, delta);
      editingTicket.value = await _service.getById(editingTicket.value!.id);
    } catch (e) {
      Get.snackbar('Error', 'No se pudo actualizar la cantidad');
    }
  }

  /// Finaliza la corrección: guarda las líneas seleccionadas como cobro definitivo
  /// y cierra el ticket como [pagado]. El ticket NO vuelve a la sala.
  Future<void> rechargeEditing(
    List<int> lineIndices,
    PaymentMethod method, {
    double mixedCashAmount = 0,
    double mixedCardAmount = 0,
  }) async {
    if (editingTicket.value == null) return;
    try {
      await _service.correctPayment(
        editingTicket.value!,
        lineIndices,
        method,
        mixedCashAmount: mixedCashAmount,
        mixedCardAmount: mixedCardAmount,
      );
      editingTicket.value = null;
      await loadAll();
      Get.find<ReportController>().loadLiveStats();
    } catch (e) {
      Get.snackbar('Error', 'No se pudo completar la corrección de cobro');
    }
  }

  /// Cancela el ticket en edición (marca como cancelado sin volver a sala).
  Future<void> cancelEditing() async {
    if (editingTicket.value == null) return;
    try {
      await _service.cancel(editingTicket.value!);
      editingTicket.value = null;
      await loadAll();
      Get.find<ReportController>().loadLiveStats();
    } catch (e) {
      Get.snackbar('Error', 'No se pudo cancelar el ticket');
    }
  }
}
