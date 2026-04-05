import 'package:get/get.dart';

import '../../data/models/user.dart';
import '../../data/models/verifactu_models.dart';
import '../../services/user_service.dart';
import '../../services/verifactu_service.dart';

class VerifactuController extends GetxController {
  final VerifactuService _service;
  final UserService _userService;
  VerifactuController(this._service, this._userService);

  final interactions = <FiscalInteraction>[].obs;
  final isLoading = false.obs;
  final isSubmitting = false.obs;
  final errorMessage = RxnString();
  final backendState = Rxn<VerifactuBackendState>();
  final subscriptionSummary = Rxn<VerifactuSubscriptionSummary>();
  final adminUser = Rxn<User>();
  final hasActiveJwtSession = false.obs;

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
      await _service.resetLocalVerifactuState();
      backendState.value = await _service.getBackendState();
      hasActiveJwtSession.value = _service.hasActiveJwtSession;
      subscriptionSummary.value = null;
      interactions.clear();
      await _syncAdminBackendLock(false);
      Get.snackbar('Verifactu', 'Estado local reiniciado. Ahora puedes registrar desde cero.');
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
