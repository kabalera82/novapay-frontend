import 'package:get/get.dart';

import '../../data/models/fiscal_ticket_trace.dart';
import '../../data/models/ticket.dart';
import '../../data/models/user.dart';
import '../../data/models/verifactu_models.dart';
import '../../services/fiscal_ticket_trace_service.dart';
import '../../services/ticket_service.dart';
import '../../services/user_service.dart';
import '../../services/verifactu_service.dart';
import '../../services/config_service.dart';
import 'ticket_controller.dart';

class VerifactuController extends GetxController {
  final VerifactuService _service;
  final UserService _userService;
  final FiscalTicketTraceService _fiscalTraceService;
  final TicketService _ticketService;
  VerifactuController(this._service, this._userService, this._fiscalTraceService, this._ticketService);

  final interactions = <FiscalInteraction>[].obs;
  final isLoading = false.obs;
  final isSubmitting = false.obs;
  final errorMessage = RxnString();
  final backendState = Rxn<VerifactuBackendState>();
  final subscriptionSummary = Rxn<VerifactuSubscriptionSummary>();
  final adminUser = Rxn<User>();
  final hasActiveJwtSession = false.obs;
  final tracesByInvoice = <String, FiscalTicketTrace>{}.obs;

  @override
  void onInit() {
    super.onInit();
    loadContext();
  }

  Future<void> loadContext() async {
    backendState.value = await _service.getBackendState();
    hasActiveJwtSession.value = _service.hasActiveJwtSession;
    adminUser.value = await _userService.getAdmin();

    if ((backendState.value?.registered ?? false) && !hasActiveJwtSession.value) {
      try {
        await _service.authenticateBackend();
        backendState.value = await _service.getBackendState();
        hasActiveJwtSession.value = _service.hasActiveJwtSession;
      } catch (_) {
        // Si la sesión no puede restaurarse, seguimos con el estado actual sin bloquear la UI.
      }
    }

    await _syncAdminBackendLock(backendState.value?.registered ?? false);

    if (backendState.value?.registered ?? false) {
      await refreshSubscriptionSummary(showSnackbarOnError: false);
      await refreshInteractions();
    } else {
      subscriptionSummary.value = null;
    }
  }

  Future<void> registerBackend({
    required String companyName,
    required String taxId,
    required String address,
    required String email,
    required String password,
    required String passwordConfirmation,
    required String planCode,
    required String billingCycle,
    required bool isNewSystem,
    String? hash,
  }) async {
    try {
      isSubmitting.value = true;
      final normalizedHash = hash?.trim();
      final result = await _service.registerBackendUser(
        companyName: companyName,
        taxId: taxId,
        address: address,
        email: email,
        password: password,
        passwordConfirmation: passwordConfirmation,
        planCode: planCode,
        billingCycle: billingCycle,
        isNewSystem: isNewSystem,
        clientHash: (normalizedHash == null || normalizedHash.isEmpty) ? null : normalizedHash,
      );
      backendState.value = await _service.getBackendState();
      hasActiveJwtSession.value = _service.hasActiveJwtSession;
      await _syncAdminBackendLock(backendState.value?.registered ?? false);
      await refreshSubscriptionSummary(showSnackbarOnError: false);
      final companySuffix = result.companyId != null ? ' companyId=${result.companyId}' : '';
      final clientSuffix = result.clientId != null ? ' clientId=${result.clientId}' : '';
      final planSuffix = (result.planCode != null && result.billingCycle != null)
          ? ' ${result.planCode}/${result.billingCycle} cuota=${result.baseAmount} limite=${result.invoiceLimit} overage=${result.overagePerInvoice}'
          : '';
      Get.snackbar(
        'Verifactu',
        '${result.message}.$companySuffix$clientSuffix$planSuffix Ahora autentica para activar el backend.',
      );
    } catch (e) {
      Get.snackbar('Verifactu', 'Registro fallido: $e');
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<void> authenticateNow() async {
    try {
      isSubmitting.value = true;
      await _service.authenticateBackend();
      backendState.value = await _service.getBackendState();
      hasActiveJwtSession.value = _service.hasActiveJwtSession;
      await _syncAdminBackendLock(backendState.value?.registered ?? false);
      await refreshSubscriptionSummary(showSnackbarOnError: false);
      Get.snackbar('Verifactu', 'Autenticación correcta. Backend habilitado por 15 días.');
      await refreshInteractions();
    } catch (e) {
      Get.snackbar('Verifactu', 'No se pudo autenticar: $e');
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<void> authenticateWithCredentials({required String email, required String password}) async {
    try {
      isSubmitting.value = true;
      await _service.authenticateBackendWithCredentials(
        email: email,
        password: password,
        fallbackClientId: adminUser.value?.taxId,
      );
      backendState.value = await _service.getBackendState();
      hasActiveJwtSession.value = _service.hasActiveJwtSession;
      await _syncAdminBackendLock((backendState.value?.registered ?? false) || hasActiveJwtSession.value);
      await refreshSubscriptionSummary(showSnackbarOnError: true);
      Get.snackbar('Verifactu', 'Sesión iniciada correctamente con email y contraseña.');
      await refreshInteractions();
    } catch (e) {
      Get.snackbar('Verifactu', 'No se pudo conectar: $e');
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<void> disconnectBackend() async {
    try {
      isSubmitting.value = true;
      await _service.logoutBackend();
      backendState.value = await _service.getBackendState();
      hasActiveJwtSession.value = _service.hasActiveJwtSession;
      subscriptionSummary.value = null;
      interactions.clear();
      await _syncAdminBackendLock((backendState.value?.registered ?? false) || hasActiveJwtSession.value);
      Get.snackbar('Verifactu', 'Sesión backend cerrada. Puedes reconectar cuando quieras.');
    } catch (e) {
      Get.snackbar('Verifactu', 'No se pudo cerrar la sesión backend: $e');
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<void> changePassword({required String currentPassword, required String newPassword}) async {
    try {
      isSubmitting.value = true;
      await _service.changePassword(currentPassword: currentPassword, newPassword: newPassword);
      hasActiveJwtSession.value = _service.hasActiveJwtSession;
      Get.snackbar('Verifactu', 'Contraseña actualizada. Vuelve a conectar con la nueva contraseña.');
    } catch (e) {
      Get.snackbar('Verifactu', 'No se pudo cambiar contraseña: $e');
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<void> refreshSubscriptionSummary({bool showSnackbarOnError = true}) async {
    try {
      final hasSession = hasActiveJwtSession.value;
      if (!(backendState.value?.registered ?? false) && !hasSession) {
        subscriptionSummary.value = null;
        return;
      }

      subscriptionSummary.value = await _service.fetchSubscriptionSummary();
    } catch (e) {
      if (e is VerifactuApiException && e.statusCode == 404) {
        await _service.resetLocalVerifactuState();
        backendState.value = await _service.getBackendState();
        hasActiveJwtSession.value = _service.hasActiveJwtSession;
        subscriptionSummary.value = null;
        interactions.clear();
        await _syncAdminBackendLock(false);
        if (showSnackbarOnError) {
          Get.snackbar('Verifactu', 'No existe registro backend para este cliente. Se reinició el estado local.');
        }
        return;
      }

      subscriptionSummary.value = null;
      if (showSnackbarOnError) {
        Get.snackbar('Verifactu', 'No se pudo cargar el consumo actual: $e');
      }
    }
  }

  Future<void> refreshInteractions() async {
    try {
      isLoading.value = true;
      errorMessage.value = null;
      backendState.value = await _service.getBackendState();
      hasActiveJwtSession.value = _service.hasActiveJwtSession;

      if (!(backendState.value?.canUseBackend ?? false) && !hasActiveJwtSession.value) {
        interactions.clear();
        await _syncAdminBackendLock((backendState.value?.registered ?? false) || hasActiveJwtSession.value);
        return;
      }

      final backendIdentity = await _service.refreshCompanyIdentityFromBackend();
      if (backendIdentity != null) {
        await _syncAdminIdentity(backendIdentity);
      }

      interactions.value = await _service.fetchInteractions();
      await _loadLocalTraces(interactions);
      await _syncAdminBackendLock((backendState.value?.registered ?? false) || hasActiveJwtSession.value);
    } catch (e) {
      errorMessage.value = 'No se pudieron cargar las interacciones Verifactu.';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> resetLocalState() async {
    try {
      isSubmitting.value = true;
      await _service.logoutBackend();
      await Get.find<ConfigService>().factoryResetKeepingSeeds();
      backendState.value = await _service.getBackendState();
      hasActiveJwtSession.value = _service.hasActiveJwtSession;
      adminUser.value = await _userService.getAdmin();
      subscriptionSummary.value = null;
      interactions.clear();
      tracesByInvoice.clear();
      Get.snackbar('Verifactu', 'Reinicio de fábrica completado: solo se conservaron admin/1234 y productos semilla.');
    } catch (e) {
      Get.snackbar('Verifactu', 'No se pudo reiniciar el estado local: $e');
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<void> requestPasswordRecovery(String email) async {
    if (email.trim().isEmpty) {
      Get.snackbar('Verifactu', 'Indica un email para recuperar contraseña.');
      return;
    }

    try {
      isSubmitting.value = true;
      await _service.requestPasswordRecovery(email: email);
      Get.snackbar('Verifactu', 'Solicitud enviada. Revisa tu email para recuperar contraseña.');
    } catch (e) {
      Get.snackbar('Verifactu', 'No se pudo recuperar contraseña: $e');
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<void> refreshStatus() async {
    await refreshSubscriptionSummary(showSnackbarOnError: false);
    await refreshInteractions();
  }

  bool canRetryInteraction(FiscalInteraction item) {
    final remediable = canRemediateInteraction(item);
    if (!remediable) {
      return false;
    }
    return item.responseCode?.trim() != '3000';
  }

  bool canRemediateInteraction(FiscalInteraction item) {
    return item.status == 'RECHAZADO' || item.status == 'ERROR_PERMANENTE';
  }

  Future<void> retryInteraction(FiscalInteraction item) async {
    if (!canRetryInteraction(item)) {
      Get.snackbar('Verifactu', 'Solo se pueden reenviar tickets rechazados o con error permanente.');
      return;
    }

    try {
      isSubmitting.value = true;
      await _service.retryFiscalSubmission(item.invoiceId);
      Get.snackbar('Verifactu', 'Reenvío lanzado para ${item.invoiceSeries}-${item.invoiceNumber}.');
      await refreshInteractions();
    } catch (e) {
      Get.snackbar('Verifactu', 'No se pudo reenviar ${item.invoiceSeries}-${item.invoiceNumber}: $e');
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<void> retryRejectedInteractions(List<FiscalInteraction> items) async {
    final retryable = items.where(canRetryInteraction).toList();
    if (retryable.isEmpty) {
      Get.snackbar('Verifactu', 'No hay tickets rechazados para reenviar.');
      return;
    }

    try {
      isSubmitting.value = true;
      var successCount = 0;

      for (final item in retryable) {
        try {
          await _service.retryFiscalSubmission(item.invoiceId);
          successCount++;
        } catch (_) {
          // Continuamos con el resto para no bloquear el reenvío masivo.
        }
      }

      await refreshInteractions();

      if (successCount == retryable.length) {
        Get.snackbar('Verifactu', 'Reenvío lanzado para $successCount tickets rechazados.');
      } else {
        Get.snackbar('Verifactu', 'Se reenviaron $successCount de ${retryable.length} tickets rechazados.');
      }
    } catch (e) {
      Get.snackbar('Verifactu', 'No se pudo completar el reenvío masivo: $e');
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<void> remediateRejectedInteraction(FiscalInteraction item, {required String reason}) async {
    if (!canRemediateInteraction(item)) {
      Get.snackbar('Verifactu', 'Solo se puede subsanar tickets rechazados o con error permanente.');
      return;
    }

    final sanitizedReason = reason.trim();
    if (sanitizedReason.isEmpty) {
      Get.snackbar('Verifactu', 'Indica un motivo de subsanación para anular la factura.');
      return;
    }

    try {
      isSubmitting.value = true;
      var alreadyCancelled = false;
      try {
        await _service.cancelInvoice(invoiceId: item.invoiceId, reason: sanitizedReason);
      } on VerifactuApiException catch (e) {
        final body = (e.responseBody ?? '').toUpperCase();
        final alreadyCancelledConflict = e.statusCode == 409 && body.contains('ANULADA');
        if (alreadyCancelledConflict) {
          alreadyCancelled = true;
        } else {
          rethrow;
        }
      }

      final trace = tracesByInvoice[item.invoiceId] ?? await _fiscalTraceService.getByInvoiceId(item.invoiceId);
      if (trace != null && trace.lines.isNotEmpty) {
        final canCreate = !(await _hasRecoverableOpenTicket(trace));
        if (canCreate) {
          await _ticketService.createFromFiscalTrace(trace);
        }
        if (Get.isRegistered<TicketController>()) {
          await Get.find<TicketController>().loadTickets();
        }
      }
      await refreshInteractions();
      final actionMsg = alreadyCancelled ? 'Ya estaba anulada en backend.' : 'Anulada correctamente en backend.';
      final recreatedMsg = (trace != null && trace.lines.isNotEmpty)
          ? ' Ticket local listo para corregir y reemitir.'
          : ' No se pudieron recuperar automáticamente las líneas del ticket local; tendrás que rehacerlas manualmente.';
      Get.snackbar('Verifactu', 'Factura ${item.invoiceSeries}-${item.invoiceNumber}: $actionMsg$recreatedMsg');
    } catch (e) {
      Get.snackbar('Verifactu', 'No se pudo completar la subsanación: $e');
    } finally {
      isSubmitting.value = false;
    }
  }

  FiscalTicketTrace? traceForInvoice(String invoiceId) => tracesByInvoice[invoiceId];

  Future<void> _loadLocalTraces(List<FiscalInteraction> items) async {
    final ids = items.map((item) => item.invoiceId).where((id) => id.trim().isNotEmpty).toList();
    final traces = await _fiscalTraceService.getByInvoiceIds(ids);
    final missing = items.where((item) => !traces.containsKey(item.invoiceId)).toList();
    if (missing.isNotEmpty) {
      await _recoverMissingTraces(missing, traces);
    }
    tracesByInvoice.value = traces;
  }

  Future<void> _recoverMissingTraces(List<FiscalInteraction> missing, Map<String, FiscalTicketTrace> traces) async {
    final allTickets = await _ticketService.getAll();
    final paidTickets = allTickets.where((t) => t.status == TicketStatus.pagado && t.lines.isNotEmpty).toList();
    final usedTicketUuids = traces.values.map((t) => t.ticketUuid).whereType<String>().toSet();

    for (final interaction in missing) {
      final expectedAmount = interaction.totalAmount;
      final referenceAt = _interactionTimestamp(interaction);
      final interactionDate = DateTime.tryParse(interaction.issueDate);

      Ticket? best;
      double bestScore = double.infinity;

      for (final ticket in paidTickets) {
        if (usedTicketUuids.contains(ticket.uuid)) {
          continue;
        }

        final amountDiff = (ticket.totalAmount - expectedAmount).abs();
        if (amountDiff > 0.01) {
          continue;
        }

        final sameIssueDay =
            interactionDate != null &&
            ticket.createdAt.year == interactionDate.year &&
            ticket.createdAt.month == interactionDate.month &&
            ticket.createdAt.day == interactionDate.day;

        if (!sameIssueDay && referenceAt != null) {
          final hoursDiff = (ticket.createdAt.difference(referenceAt).inMinutes.abs() / 60.0);
          if (hoursDiff > 24) {
            continue;
          }
        }

        final timeDiffMinutes = referenceAt == null
            ? 0.0
            : (ticket.createdAt.difference(referenceAt).inMinutes.abs().toDouble());
        final score = (amountDiff * 100000) + timeDiffMinutes;

        if (score < bestScore) {
          bestScore = score;
          best = ticket;
        }
      }

      if (best == null) {
        continue;
      }

      await _fiscalTraceService.saveEmissionTrace(
        ticket: best,
        invoice: BackendInvoiceResponse(
          id: interaction.invoiceId,
          series: interaction.invoiceSeries,
          number: interaction.invoiceNumber,
          type: 'SIMPLIFICADA',
          status: interaction.status,
          issueDate: interaction.issueDate,
          totalAmount: interaction.totalAmount,
        ),
      );

      usedTicketUuids.add(best.uuid);
      final saved = await _fiscalTraceService.getByInvoiceId(interaction.invoiceId);
      if (saved != null) {
        traces[interaction.invoiceId] = saved;
      }
    }
  }

  DateTime? _interactionTimestamp(FiscalInteraction item) {
    final respondedAt = DateTime.tryParse(item.respondedAt ?? '');
    if (respondedAt != null) {
      return respondedAt;
    }

    final sentAt = DateTime.tryParse(item.sentAt ?? '');
    if (sentAt != null) {
      return sentAt;
    }

    return DateTime.tryParse(item.issueDate);
  }

  Future<bool> _hasRecoverableOpenTicket(FiscalTicketTrace trace) async {
    final open = await _ticketService.getOpen();
    final candidates = open.where((t) => (t.totalAmount - trace.totalAmount).abs() <= 0.01 && t.lines.isNotEmpty);
    final expectedSignature = trace.lines
        .map((l) => '${l.productName}|${l.quantity}|${l.unitPrice.toStringAsFixed(2)}')
        .join('||');

    for (final ticket in candidates) {
      final ticketSignature = ticket.lines
          .map((l) => '${l.productName}|${l.quantity}|${l.priceAtMoment.toStringAsFixed(2)}')
          .join('||');
      if (ticketSignature == expectedSignature) {
        return true;
      }
    }
    return false;
  }

  Future<void> _syncAdminBackendLock(bool lockFields) async {
    final admin = adminUser.value ?? await _userService.getAdmin();
    if (admin == null) {
      return;
    }
    if (admin.backendEditable == lockFields) {
      return;
    }

    admin.backendEditable = lockFields;
    await _userService.save(admin);
    adminUser.value = admin;
  }

  Future<void> _syncAdminIdentity(VerifactuCompanyIdentity identity) async {
    final admin = adminUser.value ?? await _userService.getAdmin();
    if (admin == null) {
      return;
    }

    var changed = false;

    final companyName = identity.companyName?.trim();
    if (companyName != null && companyName.isNotEmpty && admin.companyName != companyName) {
      admin.companyName = companyName;
      changed = true;
    }

    final taxId = identity.taxId?.trim();
    if (taxId != null && taxId.isNotEmpty && admin.taxId != taxId) {
      admin.taxId = taxId;
      changed = true;
    }

    final address = identity.address?.trim();
    if (address != null && address.isNotEmpty && admin.address != address) {
      admin.address = address;
      changed = true;
    }

    if (!changed) {
      return;
    }

    await _userService.save(admin);
    adminUser.value = admin;
  }
}
