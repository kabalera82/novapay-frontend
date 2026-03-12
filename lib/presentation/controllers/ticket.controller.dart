// lib/presentation/controllers/ticket.controller.dart
import 'package:get/get.dart';
import 'package:isar/isar.dart';
import '../../data/models/ticket.dart';
import '../../data/models/ticketLine.dart';
import '../../services/ticket.service.dart';

class TicketController extends GetxController {
  final Isar isar;
  TicketController(this.isar);

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
    isLoading.value = true;
    openTickets.value   = await getOpenTickets(isar);
    parkedTickets.value = await getParkedTickets(isar);
    isLoading.value = false;
  }

  Future<void> selectOrCreateTicket({
    int? tableNumber,
    String? zone,
    String? tableOrLabel,
  }) async {
    final existing = openTickets.firstWhereOrNull(
      (t) => t.tableNumber == tableNumber && t.zone == zone,
    );
    if (existing != null) {
      activeTicket.value = existing;
    } else {
      final ticket = await createTicket(
        isar,
        tableNumber: tableNumber,
        zone: zone,
        tableOrLabel: tableOrLabel,
      );
      activeTicket.value = ticket;
      await loadTickets();
    }
  }

  Future<void> addLineToActive(TicketLine line) async {
    if (activeTicket.value == null) return;
    await addLine(isar, activeTicket.value!, line);
    activeTicket.value = await getTicketById(isar, activeTicket.value!.id);
    await loadTickets();
  }

  Future<void> removeLineFromActive(String productName) async {
    if (activeTicket.value == null) return;
    await removeLine(isar, activeTicket.value!, productName);
    activeTicket.value = await getTicketById(isar, activeTicket.value!.id);
    await loadTickets();
  }

  Future<void> parkActive() async {
    if (activeTicket.value == null) return;
    await toggleParked(isar, activeTicket.value!);
    activeTicket.value = null;
    await loadTickets();
  }

  Future<void> unparkTicket(Ticket ticket) async {
    await toggleParked(isar, ticket);
    activeTicket.value = ticket;
    await loadTickets();
  }

  Future<void> payActive(PaymentMethod method) async {
    if (activeTicket.value == null) return;
    await payTicket(isar, activeTicket.value!, method);
    activeTicket.value = null;
    await loadTickets();
  }

  Future<void> cancelActive() async {
    if (activeTicket.value == null) return;
    await cancelTicket(isar, activeTicket.value!);
    activeTicket.value = null;
    await loadTickets();
  }

  void clearActive() => activeTicket.value = null;

  Future<List<Ticket>> todayTickets() async {
    return await getTicketsByDate(isar, DateTime.now());
  }
}