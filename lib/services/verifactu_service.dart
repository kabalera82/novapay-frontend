import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../data/models/ticket.dart';
import '../data/models/verifactu_models.dart';
import '../data/models/business_config.dart';
import 'config_service.dart';

class VerifactuApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? responseBody;

  const VerifactuApiException(this.message, {this.statusCode, this.responseBody});

  @override
  String toString() {
    if (statusCode == null) {
      return message;
    }
    return '$message (HTTP $statusCode) ${responseBody ?? ''}'.trim();
  }
}

class VerifactuLocalModeException implements Exception {
  final String message;
  const VerifactuLocalModeException(this.message);

  @override
  String toString() => message;
}

class VerifactuBackendState {
  final bool registered;
  final bool canUseBackend;
  final bool requiresAuth;
  final bool isNewSystem;
  final DateTime? lastAuthAt;

  const VerifactuBackendState({
    required this.registered,
    required this.canUseBackend,
    required this.requiresAuth,
    required this.isNewSystem,
    required this.lastAuthAt,
  });
}

class VerifactuRegistrationResult {
  final String message;
  final String? companyId;
  final String? terminalId;
  final String? clientId;
  final String? planCode;
  final String? billingCycle;
  final String? baseAmount;
  final String? invoiceLimit;
  final String? overagePerInvoice;

  const VerifactuRegistrationResult({
    required this.message,
    this.companyId,
    this.terminalId,
    this.clientId,
    this.planCode,
    this.billingCycle,
    this.baseAmount,
    this.invoiceLimit,
    this.overagePerInvoice,
  });

  factory VerifactuRegistrationResult.fromJson(Map<String, dynamic> json) {
    return VerifactuRegistrationResult(
      message: (json['message'] as String?) ?? 'Registro backend completado',
      companyId: json['companyId'] as String?,
      terminalId: json['terminalId'] as String?,
      clientId: json['clientId'] as String?,
      planCode: json['planCode'] as String?,
      billingCycle: json['billingCycle'] as String?,
      baseAmount: json['baseAmount'] as String?,
      invoiceLimit: json['invoiceLimit'] as String?,
      overagePerInvoice: json['overagePerInvoice'] as String?,
    );
  }
}

class VerifactuSubscriptionSummary {
  final String clientId;
  final String companyId;
  final String? terminalId;
  final String planCode;
  final String billingCycle;
  final String periodStart;
  final String periodEnd;
  final int serviceDaysRemaining;
  final String paymentStatus;
  final int includedInvoices;
  final int consumedInvoices;
  final int remainingInvoices;
  final int overageInvoices;
  final String baseAmount;
  final String overagePerInvoice;
  final String estimatedOverage;
  final String estimatedTotal;

  const VerifactuSubscriptionSummary({
    required this.clientId,
    required this.companyId,
    this.terminalId,
    required this.planCode,
    required this.billingCycle,
    required this.periodStart,
    required this.periodEnd,
    required this.serviceDaysRemaining,
    required this.paymentStatus,
    required this.includedInvoices,
    required this.consumedInvoices,
    required this.remainingInvoices,
    required this.overageInvoices,
    required this.baseAmount,
    required this.overagePerInvoice,
    required this.estimatedOverage,
    required this.estimatedTotal,
  });

  factory VerifactuSubscriptionSummary.fromJson(Map<String, dynamic> json) {
    return VerifactuSubscriptionSummary(
      clientId: (json['clientId'] as String?) ?? '',
      companyId: (json['companyId'] as String?) ?? '',
      terminalId: json['terminalId'] as String?,
      planCode: (json['planCode'] as String?) ?? '',
      billingCycle: (json['billingCycle'] as String?) ?? '',
      periodStart: (json['periodStart'] as String?) ?? '',
      periodEnd: (json['periodEnd'] as String?) ?? '',
      serviceDaysRemaining: (json['serviceDaysRemaining'] as num?)?.toInt() ?? 0,
      paymentStatus: (json['paymentStatus'] as String?) ?? 'DESCONOCIDO',
      includedInvoices: (json['includedInvoices'] as num?)?.toInt() ?? 0,
      consumedInvoices: (json['consumedInvoices'] as num?)?.toInt() ?? 0,
      remainingInvoices: (json['remainingInvoices'] as num?)?.toInt() ?? 0,
      overageInvoices: (json['overageInvoices'] as num?)?.toInt() ?? 0,
      baseAmount: (json['baseAmount'] as String?) ?? '0.00',
      overagePerInvoice: (json['overagePerInvoice'] as String?) ?? '0.00',
      estimatedOverage: (json['estimatedOverage'] as String?) ?? '0.00',
      estimatedTotal: (json['estimatedTotal'] as String?) ?? '0.00',
    );
  }
}

class VerifactuCompanyIdentity {
  final String? companyName;
  final String? taxId;
  final String? address;

  const VerifactuCompanyIdentity({this.companyName, this.taxId, this.address});

  bool get hasData {
    return (companyName != null && companyName!.trim().isNotEmpty) ||
        (taxId != null && taxId!.trim().isNotEmpty) ||
        (address != null && address!.trim().isNotEmpty);
  }
}

class VerifactuService {
  static const String _baseUrlFromEnv = String.fromEnvironment('NOVAPAY_BACKEND_URL', defaultValue: '');
  static const String _clientId = String.fromEnvironment('NOVAPAY_CLIENT_ID', defaultValue: 'novapay-client');
  static const String _clientSecret = String.fromEnvironment(
    'NOVAPAY_CLIENT_SECRET',
    defaultValue: 'novapay-secret-2024',
  );
  static const String _companyId = String.fromEnvironment(
    'NOVAPAY_COMPANY_ID',
    defaultValue: '550e8400-e29b-41d4-a716-446655440000',
  );
  static const String _terminalId = String.fromEnvironment(
    'NOVAPAY_TERMINAL_ID',
    defaultValue: '550e8400-e29b-41d4-a716-446655440001',
  );
  static const String _series = String.fromEnvironment('NOVAPAY_INVOICE_SERIES', defaultValue: 'TPV');
  static const String _defaultTaxType = String.fromEnvironment('NOVAPAY_TAX_TYPE', defaultValue: 'IVA_REDUCIDO');
  static const Duration _maxAuthAge = Duration(days: 15);

  final http.Client _httpClient;
  final ConfigService _configService;
  VerifactuService(this._configService, {http.Client? httpClient}) : _httpClient = httpClient ?? http.Client();

  String? _accessToken;
  DateTime? _tokenExpiresAt;
  String? _resolvedCompanyId;
  String? _resolvedTerminalId;

  String get _baseUrl {
    if (_baseUrlFromEnv.trim().isNotEmpty) {
      return _baseUrlFromEnv.trim();
    }
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8080';
    }
    return 'http://localhost:8080';
  }

  Future<VerifactuBackendState> getBackendState() async {
    final config = await _configService.getConfig();
    final hasClientId = config.verifactuClientId != null && config.verifactuClientId!.trim().isNotEmpty;
    final registered = config.verifactuRegistered && hasClientId;
    if (!registered) {
      if (config.verifactuRegistered) {
        config
          ..verifactuRegistered = false
          ..verifactuClientId = null
          ..verifactuLastAuthAt = null;
        await _configService.saveConfig(config);
      }
      return const VerifactuBackendState(
        registered: false,
        canUseBackend: false,
        requiresAuth: false,
        isNewSystem: false,
        lastAuthAt: null,
      );
    }

    final lastAuth = config.verifactuLastAuthAt;
    final hasLocalToken = hasActiveJwtSession;
    final authExpired = lastAuth == null || DateTime.now().difference(lastAuth) > _maxAuthAge;
    final requiresAuth = !hasLocalToken || authExpired;

    return VerifactuBackendState(
      registered: true,
      canUseBackend: hasLocalToken && !authExpired,
      requiresAuth: requiresAuth,
      isNewSystem: config.verifactuIsNewSystem,
      lastAuthAt: lastAuth,
    );
  }

  Future<VerifactuRegistrationResult> registerBackendUser({
    required String companyName,
    required String taxId,
    required String address,
    required String email,
    required String password,
    required String passwordConfirmation,
    required String planCode,
    required String billingCycle,
    required bool isNewSystem,
    String? clientHash,
  }) async {
    final normalizedHash = clientHash?.trim();
    final payload = {
      'companyName': companyName,
      'taxId': taxId,
      'address': address,
      'email': email,
      'password': password,
      'passwordConfirmation': passwordConfirmation,
      'planCode': planCode,
      'billingCycle': billingCycle,
      'isNewSystem': isNewSystem,
    };
    if (!isNewSystem && normalizedHash != null && normalizedHash.isNotEmpty) {
      payload['clientHash'] = normalizedHash;
    }

    final response = await _httpClient.post(
      Uri.parse('$_baseUrl/api/v1/verifactu/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw VerifactuApiException(
        'No se pudo registrar en backend Verifactu',
        statusCode: response.statusCode,
        responseBody: response.body,
      );
    }

    final responseJson = decodeJsonObject(response.body);
    final registrationResult = VerifactuRegistrationResult.fromJson(responseJson);

    final cfg = await _configService.getConfig();
    cfg
      ..verifactuRegistered = true
      ..verifactuIsNewSystem = isNewSystem
      ..verifactuClientHash = password
      ..verifactuClientId = taxId
      ..verifactuLastAuthAt = null;
    await _configService.saveConfig(cfg);

    await _syncBusinessIdentity(companyName: companyName, taxId: taxId, address: address);

    return registrationResult;
  }

  Future<void> authenticateBackend() async {
    final cfg = await _configService.getConfig();
    if (!cfg.verifactuRegistered) {
      throw const VerifactuLocalModeException('No registrado en backend Verifactu. Se mantiene modo local.');
    }

    await _ensureToken(forceRefresh: true);
    cfg.verifactuLastAuthAt = DateTime.now();
    await _configService.saveConfig(cfg);

    await refreshCompanyIdentityFromBackend();
  }

  Future<void> authenticateBackendWithCredentials({
    required String email,
    required String password,
    String? fallbackClientId,
  }) async {
    final response = await _httpClient.post(
      Uri.parse('$_baseUrl/api/v1/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email.trim(), 'password': password}),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw VerifactuApiException(
        'No se pudo iniciar sesión con email y contraseña',
        statusCode: response.statusCode,
        responseBody: response.body,
      );
    }

    final body = decodeJsonObject(response.body);
    final token = (body['access_token'] as String?) ?? (body['accessToken'] as String?);
    final expiresIn = ((body['expires_in'] as num?) ?? (body['expiresIn'] as num?) ?? 3600).toInt();
    final clientIdFromLogin =
        ((body['clientId'] as String?) ??
                (body['client_id'] as String?) ??
                (body['taxId'] as String?) ??
                (body['tax_id'] as String?))
            ?.trim();
    final fallback = fallbackClientId?.trim();
    final resolvedClientId = (clientIdFromLogin != null && clientIdFromLogin.isNotEmpty)
        ? clientIdFromLogin
        : ((fallback != null && fallback.isNotEmpty) ? fallback : null);
    if (token == null || token.isEmpty) {
      throw Exception('Token JWT vacío en respuesta de login por email.');
    }

    final hasJwtFromLogin = _looksLikeJwt(token);

    // Algunas implementaciones de /auth/login devuelven JWT real y otras un placeholder.
    if (hasJwtFromLogin) {
      _accessToken = token;
      _tokenExpiresAt = DateTime.now().add(Duration(seconds: expiresIn - 5));
    } else {
      _accessToken = null;
      _tokenExpiresAt = null;
    }

    final cfg = await _configService.getConfig();
    cfg
      ..verifactuClientId = (resolvedClientId != null && resolvedClientId.isNotEmpty)
          ? resolvedClientId
          : cfg.verifactuClientId
      ..verifactuRegistered = (resolvedClientId != null && resolvedClientId.isNotEmpty) ? true : cfg.verifactuRegistered
      ..verifactuClientHash = password
      ..verifactuLastAuthAt = DateTime.now();

    if (cfg.verifactuClientId == null || cfg.verifactuClientId!.trim().isEmpty) {
      cfg.verifactuRegistered = false;
    }

    await _configService.saveConfig(cfg);

    // Si el login ya entregó JWT válido, se usa directamente.
    if (hasJwtFromLogin) {
      await refreshCompanyIdentityFromBackend();
      return;
    }

    // Si no hay JWT en /login, se intenta flujo legacy /auth/token.
    if (cfg.verifactuClientId == null || cfg.verifactuClientId!.trim().isEmpty) {
      throw const VerifactuApiException(
        'Login correcto, pero backend no devolvió clientId para obtener JWT operativo. '
        'Revisa respuesta de /api/v1/auth/login.',
      );
    }

    await _ensureToken(forceRefresh: true);
    await refreshCompanyIdentityFromBackend();
  }

  Future<void> requestPasswordRecovery({required String email}) async {
    final response = await _httpClient.post(
      Uri.parse('$_baseUrl/api/v1/auth/forgot-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email.trim()}),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw VerifactuApiException(
        'No se pudo iniciar la recuperación de contraseña',
        statusCode: response.statusCode,
        responseBody: response.body,
      );
    }
  }

  Future<void> logoutBackend() async {
    _accessToken = null;
    _tokenExpiresAt = null;

    final cfg = await _configService.getConfig();
    cfg.verifactuLastAuthAt = null;
    await _configService.saveConfig(cfg);
  }

  Future<void> resetLocalVerifactuState() async {
    _accessToken = null;
    _tokenExpiresAt = null;

    final cfg = await _configService.getConfig();
    cfg
      ..verifactuRegistered = false
      ..verifactuIsNewSystem = false
      ..verifactuClientId = null
      ..verifactuClientHash = null
      ..verifactuLastAuthAt = null;
    await _configService.saveConfig(cfg);
  }

  bool get hasActiveJwtSession {
    if (_accessToken == null || _tokenExpiresAt == null) {
      return false;
    }
    return DateTime.now().isBefore(_tokenExpiresAt!);
  }

  Future<void> changePassword({required String currentPassword, required String newPassword}) async {
    final cfg = await _configService.getConfig();
    final clientId = cfg.verifactuClientId;
    if (clientId == null || clientId.trim().isEmpty) {
      throw const VerifactuLocalModeException('No hay clientId configurado para cambiar contraseña.');
    }

    await _ensureToken(forceRefresh: true);

    final response = await _httpClient.post(
      Uri.parse('$_baseUrl/api/v1/auth/change-password'),
      headers: {..._jsonAuthHeaders, 'X-Client-Id': clientId.trim()},
      body: jsonEncode({'currentPassword': currentPassword, 'newPassword': newPassword, 'temporalPassword': null}),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw VerifactuApiException(
        'No se pudo cambiar la contraseña',
        statusCode: response.statusCode,
        responseBody: response.body,
      );
    }

    cfg.verifactuClientHash = newPassword;
    await _configService.saveConfig(cfg);
    _accessToken = null;
    _tokenExpiresAt = null;
  }

  Future<VerifactuSubscriptionSummary> fetchSubscriptionSummary() async {
    final cfg = await _configService.getConfig();
    final clientId = cfg.verifactuClientId;
    if (clientId == null || clientId.trim().isEmpty) {
      throw const VerifactuLocalModeException('No hay clientId configurado para consultar consumo.');
    }

    final response = await _httpClient.get(
      Uri.parse('$_baseUrl/api/v1/verifactu/subscription/${clientId.trim()}'),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw VerifactuApiException(
        'No se pudo obtener el resumen de suscripción',
        statusCode: response.statusCode,
        responseBody: response.body,
      );
    }

    final summary = VerifactuSubscriptionSummary.fromJson(decodeJsonObject(response.body));
    _resolvedCompanyId = summary.companyId.trim().isEmpty ? null : summary.companyId.trim();
    final terminal = summary.terminalId?.trim();
    _resolvedTerminalId = (terminal == null || terminal.isEmpty) ? null : terminal;
    return summary;
  }

  Future<InvoiceEmissionResult> emitTicket(Ticket ticket) async {
    if (ticket.lines.isEmpty) {
      throw Exception('No se puede emitir una factura sin líneas.');
    }

    final state = await getBackendState();
    if (!state.registered) {
      throw const VerifactuLocalModeException('Modo local: la app no está registrada en backend Verifactu.');
    }
    if (state.requiresAuth) {
      throw const VerifactuLocalModeException(
        'Modo local: debes autenticarte en backend Verifactu al menos cada 15 días.',
      );
    }

    await _ensureToken();

    final now = DateTime.now();
    final issueDate = DateFormat('yyyy-MM-dd').format(now);
    final number = now.millisecondsSinceEpoch.remainder(1000000);
    final fiscalContext = await _resolveEmissionContext();

    final payload = {
      'series': _series,
      'number': number,
      'type': 'SIMPLIFICADA',
      'companyId': fiscalContext.companyId,
      'terminalId': fiscalContext.terminalId,
      'issueDate': issueDate,
      'lines': ticket.lines
          .map(
            (line) => {
              'description': line.productName,
              'quantity': line.quantity,
              'unitPrice': line.priceAtMoment,
              'taxType': _defaultTaxType,
            },
          )
          .toList(),
      'rectifiedInvoiceId': null,
    };

    final emitResponse = await _httpClient.post(
      Uri.parse('$_baseUrl/api/v1/invoices'),
      headers: _jsonAuthHeaders,
      body: jsonEncode(payload),
    );

    if (emitResponse.statusCode != 201) {
      throw VerifactuApiException(
        'Error al emitir factura',
        statusCode: emitResponse.statusCode,
        responseBody: emitResponse.body,
      );
    }

    final invoice = BackendInvoiceResponse.fromJson(decodeJsonObject(emitResponse.body));

    final fiscalStatus = await pollFiscalStatus(invoice.id);
    return InvoiceEmissionResult(invoice: invoice, fiscalStatus: fiscalStatus);
  }

  Future<FiscalStatusResponse?> pollFiscalStatus(
    String invoiceId, {
    int maxAttempts = 15,
    Duration delay = const Duration(seconds: 2),
  }) async {
    final state = await getBackendState();
    if (!state.canUseBackend) {
      return null;
    }

    await _ensureToken();

    FiscalStatusResponse? latest;
    for (var i = 0; i < maxAttempts; i++) {
      final response = await _httpClient.get(
        Uri.parse('$_baseUrl/api/v1/fiscal/status/$invoiceId'),
        headers: _authHeaders,
      );

      if (response.statusCode == 200) {
        latest = FiscalStatusResponse.fromJson(decodeJsonObject(response.body));
        if (latest.status != 'PENDIENTE_ENVIO' && latest.status != 'ENVIANDO') {
          return latest;
        }
      } else if (response.statusCode == 404) {
        return null;
      }

      await Future.delayed(delay);
    }

    return latest;
  }

  Future<List<FiscalInteraction>> fetchInteractions({int limit = 200}) async {
    final state = await getBackendState();
    if (!state.canUseBackend) {
      return [];
    }

    await _ensureToken();

    final response = await _httpClient.get(
      Uri.parse('$_baseUrl/api/v1/fiscal/interactions?limit=$limit'),
      headers: _authHeaders,
    );

    if (response.statusCode != 200) {
      throw VerifactuApiException(
        'Error al cargar interacciones fiscales',
        statusCode: response.statusCode,
        responseBody: response.body,
      );
    }

    return decodeJsonObjectList(response.body).map(FiscalInteraction.fromJson).toList();
  }

  Future<void> retryFiscalSubmission(String invoiceId) async {
    final state = await getBackendState();
    if (!state.canUseBackend && !hasActiveJwtSession) {
      throw const VerifactuLocalModeException('No hay sesión activa en backend para reenviar.');
    }

    await _ensureToken();

    final response = await _httpClient.post(
      Uri.parse('$_baseUrl/api/v1/fiscal/retry/$invoiceId'),
      headers: _authHeaders,
    );

    if (response.statusCode != 204) {
      throw VerifactuApiException(
        'Error al reintentar envío fiscal',
        statusCode: response.statusCode,
        responseBody: response.body,
      );
    }
  }

  Future<VerifactuCompanyIdentity?> refreshCompanyIdentityFromBackend() async {
    final cfg = await _configService.getConfig();
    final clientId = cfg.verifactuClientId?.trim();
    if (clientId == null || clientId.isEmpty) {
      return null;
    }

    await _ensureToken();

    String? companyId = _resolvedCompanyId;
    if (companyId == null || companyId.isEmpty) {
      try {
        final summary = await fetchSubscriptionSummary();
        companyId = summary.companyId.trim();
      } catch (_) {
        companyId = null;
      }
    }

    final payload = await _tryFetchCompanyPayload(clientId: clientId, companyId: companyId);
    if (payload == null) {
      return null;
    }

    final companyMap = _extractCompanyMap(payload);

    final companyName = _firstNonBlankString(companyMap, const [
      'name',
      'companyName',
      'businessName',
      'razonSocial',
      'nombreRazon',
    ]);
    final taxId = _firstNonBlankString(companyMap, const ['taxId', 'cif', 'cifNif', 'nif', 'clientId']);
    final address = _firstNonBlankString(companyMap, const ['address', 'direccion', 'fiscalAddress']);

    final identity = VerifactuCompanyIdentity(companyName: companyName, taxId: taxId, address: address);
    if (!identity.hasData) {
      return null;
    }

    await _syncBusinessIdentity(companyName: companyName, taxId: taxId, address: address);
    return identity;
  }

  Future<void> _ensureToken({bool forceRefresh = false}) async {
    if (_accessToken != null &&
        _tokenExpiresAt != null &&
        DateTime.now().isBefore(_tokenExpiresAt!) &&
        !forceRefresh &&
        _looksLikeJwt(_accessToken!)) {
      return;
    }

    final cfg = await _configService.getConfig();
    final authClientId = cfg.verifactuClientId ?? _clientId;
    final authSecret = (cfg.verifactuClientHash != null && cfg.verifactuClientHash!.isNotEmpty)
        ? cfg.verifactuClientHash!
        : _clientSecret;

    final response = await _httpClient.post(
      Uri.parse('$_baseUrl/api/v1/auth/token'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'clientId': authClientId, 'clientSecret': authSecret}),
    );

    if (response.statusCode != 200) {
      throw VerifactuApiException(
        'No se pudo autenticar con backend fiscal',
        statusCode: response.statusCode,
        responseBody: response.body,
      );
    }

    final body = decodeJsonObject(response.body);
    final token = ((body['accessToken'] as String?) ?? (body['access_token'] as String?))?.trim();
    final expiresRaw = body['expiresIn'] ?? body['expires_in'];
    final expiresIn = switch (expiresRaw) {
      num n => n.toInt(),
      String s => int.tryParse(s) ?? 60,
      _ => 60,
    };
    if (token == null || token.isEmpty) {
      throw Exception('Token JWT vacío en respuesta de autenticación.');
    }

    _accessToken = token;
    _tokenExpiresAt = DateTime.now().add(Duration(seconds: expiresIn - 5));
  }

  bool _looksLikeJwt(String token) {
    final parts = token.split('.');
    return parts.length == 3 && parts.every((part) => part.isNotEmpty);
  }

  Future<({String companyId, String terminalId})> _resolveEmissionContext() async {
    if (_resolvedCompanyId != null && _resolvedTerminalId != null) {
      return (companyId: _resolvedCompanyId!, terminalId: _resolvedTerminalId!);
    }

    try {
      await fetchSubscriptionSummary();
    } catch (_) {
      // Si falla consulta de contexto, se evaluará fallback/env abajo.
    }

    if (_resolvedCompanyId != null && _resolvedTerminalId != null) {
      return (companyId: _resolvedCompanyId!, terminalId: _resolvedTerminalId!);
    }

    final hasEnvFallback = _companyId.trim().isNotEmpty && _terminalId.trim().isNotEmpty;
    if (hasEnvFallback) {
      return (companyId: _companyId.trim(), terminalId: _terminalId.trim());
    }

    throw const VerifactuApiException(
      'No se pudo resolver companyId/terminalId del cliente para emitir. '
      'Revisa suscripción Verifactu y alta de TPV en backend.',
    );
  }

  Map<String, String> get _authHeaders {
    return {'Authorization': 'Bearer $_accessToken', 'Accept': 'application/json'};
  }

  Map<String, String> get _jsonAuthHeaders {
    return {..._authHeaders, 'Content-Type': 'application/json'};
  }

  Future<void> _syncBusinessIdentity({String? companyName, String? taxId, String? address}) async {
    final existing = await _configService.getBusinessConfig();
    final business = existing ?? BusinessConfig();

    final normalizedCompanyName = companyName?.trim();
    final normalizedTaxId = taxId?.trim();
    final normalizedAddress = address?.trim();

    var changed = false;

    if (normalizedCompanyName != null &&
        normalizedCompanyName.isNotEmpty &&
        business.businessName != normalizedCompanyName) {
      business.businessName = normalizedCompanyName;
      changed = true;
    }

    if (normalizedTaxId != null && normalizedTaxId.isNotEmpty && business.cifNif != normalizedTaxId) {
      business.cifNif = normalizedTaxId;
      changed = true;
    }

    if (normalizedAddress != null && normalizedAddress.isNotEmpty && business.address != normalizedAddress) {
      business.address = normalizedAddress;
      changed = true;
    }

    if (changed || existing == null) {
      await _configService.saveBusinessConfig(business);
    }
  }

  Future<Map<String, dynamic>?> _tryFetchCompanyPayload({required String clientId, String? companyId}) async {
    final endpoints = <String>['/api/v1/verifactu/company/$clientId'];
    final normalizedCompanyId = companyId?.trim();
    if (normalizedCompanyId != null && normalizedCompanyId.isNotEmpty) {
      endpoints.addAll([
        '/api/v1/companies/$normalizedCompanyId',
        '/api/v1/company/$normalizedCompanyId',
        '/api/v1/verifactu/companies/$normalizedCompanyId',
      ]);
    }

    VerifactuApiException? lastError;

    for (final endpoint in endpoints) {
      final response = await _httpClient.get(Uri.parse('$_baseUrl$endpoint'), headers: _authHeaders);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return decodeJsonObject(response.body);
      }
      if (response.statusCode == 404) {
        continue;
      }
      lastError = VerifactuApiException(
        'No se pudo leer datos de company en backend',
        statusCode: response.statusCode,
        responseBody: response.body,
      );
    }

    if (lastError != null) {
      throw lastError;
    }

    return null;
  }

  Map<String, dynamic> _extractCompanyMap(Map<String, dynamic> payload) {
    final nested = payload['company'];
    if (nested is Map<String, dynamic>) {
      return nested;
    }
    if (nested is Map) {
      return Map<String, dynamic>.from(nested);
    }
    return payload;
  }

  String? _firstNonBlankString(Map<String, dynamic> source, List<String> keys) {
    for (final key in keys) {
      final value = source[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }
}
