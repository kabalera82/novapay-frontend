// lib/presentation/pages/admin/sections/verifactu_section.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../config/app_formats.dart';
import '../../../../config/theme.dart';
import '../../../../data/models/verifactu_models.dart';
import '../../../controllers/verifactu_controller.dart';

class VerifactuSection extends StatefulWidget {
  const VerifactuSection({super.key});

  @override
  State<VerifactuSection> createState() => _VerifactuSectionState();
}

class _VerifactuSectionState extends State<VerifactuSection> {
  final _controller = Get.find<VerifactuController>();
  final _money = NumberFormat.currency(locale: 'es_ES', symbol: 'EUR ');
  final _passwordRegex = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&]).{12,}$');
  final _formKey = GlobalKey<FormState>();
  final _companyCtrl = TextEditingController();
  final _taxIdCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _passwordConfirmCtrl = TextEditingController();
  final _hashCtrl = TextEditingController();
  final _authEmailCtrl = TextEditingController();
  final _authPasswordCtrl = TextEditingController();
  String _selectedPlanCode = 'PLAN_5000';
  String _selectedBillingCycle = 'MONTHLY';
  bool _isNewSystem = false;
  bool _prefilledFromAdmin = false;
  bool _showRegisterPassword = false;
  bool _showRegisterPasswordConfirm = false;
  bool _showLoginPassword = false;
  bool _showRegisterAccessForm = false;
  bool _autoRequestedSummary = false;
  DateTime? _interactionDateFilter;

  @override
  void initState() {
    super.initState();
    final admin = _controller.adminUser.value;
    if (admin != null) {
      _companyCtrl.text = admin.companyName ?? '';
      _taxIdCtrl.text = admin.taxId ?? '';
      _addressCtrl.text = admin.address ?? '';
    }
  }

  @override
  void dispose() {
    _companyCtrl.dispose();
    _taxIdCtrl.dispose();
    _addressCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _passwordConfirmCtrl.dispose();
    _hashCtrl.dispose();
    _authEmailCtrl.dispose();
    _authPasswordCtrl.dispose();
    super.dispose();
  }

  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) {
      return '-';
    }
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) {
      return raw;
    }
    return DateFormat('dd/MM/yyyy HH:mm').format(parsed.toLocal());
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'ACEPTADO':
        return AppTheme.success;
      case 'RECHAZADO':
      case 'ERROR_PERMANENTE':
        return AppTheme.error;
      case 'PENDIENTE_ENVIO':
      case 'ENVIANDO':
      case 'REINTENTO':
        return AppTheme.warning;
      default:
        return AppTheme.info;
    }
  }

  bool _validateRegisterForm() {
    final formValid = _formKey.currentState?.validate() ?? false;
    if (!formValid) {
      return false;
    }

    if (!_isNewSystem && _hashCtrl.text.trim().isEmpty) {
      Get.snackbar('Verifactu', 'Debes indicar hash previo o marcar que es nuevo en sistema.');
      return false;
    }

    if (_passwordCtrl.text != _passwordConfirmCtrl.text) {
      Get.snackbar('Verifactu', 'La confirmación de contraseña no coincide.');
      return false;
    }

    return true;
  }

  bool _isRetryableStatus(String status) {
    return status == 'RECHAZADO' || status == 'ERROR_PERMANENTE';
  }

  InputDecoration _fieldDecoration(String label, {String? helperText, Widget? suffixIcon}) {
    return InputDecoration(
      labelText: label,
      helperText: helperText,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFFF1F3F5),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade400),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
      ),
    );
  }

  List<String> _missingPasswordRules(String value) {
    final missing = <String>[];
    if (!RegExp(r'[A-Z]').hasMatch(value)) missing.add('una mayúscula');
    if (!RegExp(r'[a-z]').hasMatch(value)) missing.add('una minúscula');
    if (!RegExp(r'\d').hasMatch(value)) missing.add('un número');
    if (!RegExp(r'[@$!%*?&]').hasMatch(value)) missing.add('un símbolo (@\$!%*?&)');
    if (value.length < 12) missing.add('mínimo 12 caracteres');
    return missing;
  }

  String? _passwordValidationMessage(String value) {
    final missing = _missingPasswordRules(value);
    if (missing.isEmpty) return null;
    return 'Te falta: ${missing.join(", ")}';
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

    final issueDate = DateTime.tryParse(item.issueDate);
    return issueDate;
  }

  List<FiscalInteraction> _filteredInteractions(List<FiscalInteraction> items) {
    final filtered = items.where((item) {
      if (_interactionDateFilter == null) {
        return true;
      }
      final parsedDate = _interactionTimestamp(item);
      if (parsedDate == null) {
        return false;
      }
      final filter = _interactionDateFilter!;
      return parsedDate.year == filter.year && parsedDate.month == filter.month && parsedDate.day == filter.day;
    }).toList();

    filtered.sort((a, b) {
      final timestampA = _interactionTimestamp(a) ?? DateTime.fromMillisecondsSinceEpoch(0);
      final timestampB = _interactionTimestamp(b) ?? DateTime.fromMillisecondsSinceEpoch(0);
      final comparison = timestampB.compareTo(timestampA);
      if (comparison != 0) {
        return comparison;
      }

      return b.invoiceNumber.compareTo(a.invoiceNumber);
    });

    return filtered;
  }

  Future<void> _pickInteractionDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _interactionDateFilter ?? DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _interactionDateFilter = picked);
    }
  }

  Widget _buildPasswordHint(ThemeData theme, String value) {
    final message = _passwordValidationMessage(value);
    if (message == null) {
      return Text(
        'Contraseña válida',
        style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.success, fontWeight: FontWeight.w600),
      );
    }
    return Text(
      message,
      style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.warning, fontWeight: FontWeight.w600),
    );
  }

  Widget _buildPlanCard({
    required String title,
    required String subtitle,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 220,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary.withValues(alpha: 0.10) : const Color(0xFFF1F3F5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? AppTheme.primary : Colors.grey.shade400, width: selected ? 1.8 : 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(subtitle),
          ],
        ),
      ),
    );
  }

  Widget _buildConsumptionCard(ThemeData theme) {
    final summary = _controller.subscriptionSummary.value;
    if (summary == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Text('No hay datos de consumo disponibles todavía.', style: theme.textTheme.bodyMedium),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Plan suscrito y consumo', style: theme.textTheme.titleMedium),
            const SizedBox(height: 10),
            Wrap(
              spacing: 14,
              runSpacing: 8,
              children: [
                Text('Plan: ${summary.planCode} (${summary.billingCycle})'),
                Text('Periodo: ${_formatDate(summary.periodStart)} - ${_formatDate(summary.periodEnd)}'),
                Text('Días de servicio restantes: ${summary.serviceDaysRemaining}'),
                Text('Estado de pago: ${summary.paymentStatus}'),
                Text('Incluidas: ${summary.includedInvoices}'),
                Text('Consumidas: ${summary.consumedInvoices}'),
                Text('Restantes: ${summary.remainingInvoices}'),
                Text('Exceso: ${summary.overageInvoices}'),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 14,
              runSpacing: 8,
              children: [
                Text('Cuota base: ${summary.baseAmount} EUR'),
                Text('Coste exceso/factura: ${summary.overagePerInvoice} EUR'),
                Text('Exceso estimado: ${summary.estimatedOverage} EUR'),
                Text('Total estimado: ${summary.estimatedTotal} EUR'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showChangePasswordDialog() async {
    final currentPasswordCtrl = TextEditingController();
    final newPasswordCtrl = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Cambiar contraseña backend'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentPasswordCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Contraseña actual'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: newPasswordCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Nueva contraseña',
                  helperText: '12+ caracteres, mayúscula, minúscula, número y símbolo',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
            FilledButton(
              onPressed: _controller.isSubmitting.value
                  ? null
                  : () {
                      if (!_passwordRegex.hasMatch(newPasswordCtrl.text)) {
                        Get.snackbar('Verifactu', 'La nueva contraseña no cumple la política de seguridad.');
                        return;
                      }
                      _controller.changePassword(
                        currentPassword: currentPasswordCtrl.text,
                        newPassword: newPasswordCtrl.text,
                      );
                      Navigator.of(context).pop();
                    },
              child: const Text('Actualizar'),
            ),
          ],
        );
      },
    );

    currentPasswordCtrl.dispose();
    newPasswordCtrl.dispose();
  }

  Future<void> _showConsumptionSummaryDialog(ThemeData theme) async {
    final summary = _controller.subscriptionSummary.value;
    if (summary == null) {
      Get.snackbar('Verifactu', 'No hay datos de consumo para mostrar todavía.');
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Resumen de consumo'),
          content: SizedBox(
            width: 520,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Plan: ${summary.planCode} (${summary.billingCycle})', style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                Text('Periodo: ${_formatDate(summary.periodStart)} - ${_formatDate(summary.periodEnd)}'),
                Text('Días de servicio restantes: ${summary.serviceDaysRemaining}'),
                Text('Estado de pago: ${summary.paymentStatus}'),
                Text('Consumidas: ${summary.consumedInvoices}'),
                Text('Incluidas: ${summary.includedInvoices}'),
                Text('Restantes: ${summary.remainingInvoices}'),
                Text('Exceso: ${summary.overageInvoices}'),
                const SizedBox(height: 10),
                Text(
                  'La baja se ejecuta en 3 días hábiles. El último día se enviará el último hash de encadenación '
                  'para migrar a otro operador, junto con copia de todos los registros efectuados de la empresa '
                  'al correo facilitado en el registro.',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cerrar')),
            OutlinedButton.icon(
              onPressed: () async {
                await Clipboard.setData(const ClipboardData(text: 'soporte@novapay.es'));
                if (!mounted) return;
                Get.snackbar('Verifactu', 'Email de soporte copiado: soporte@novapay.es');
              },
              icon: const Icon(Icons.copy),
              label: const Text('Copiar email soporte'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showPostResetOptionsDialog() async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Estado local reiniciado'),
          content: const Text(
            'Puedes volver a registrar desde cero o, si ya existes en backend, iniciar sesión / recuperar contraseña.',
          ),
          actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Entendido'))],
        );
      },
    );
  }

  Future<void> _showCancellationDialog() async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Darse de baja de Verifactu'),
          content: const Text(
            'La baja se tramita por soporte y se ejecuta en 3 días hábiles. '
            'El último día se facilita el hash final de encadenación y copia de registros al email registrado.\n\n'
            'Contacta con soporte@novapay.es para iniciar la baja.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cerrar')),
            OutlinedButton.icon(
              onPressed: () async {
                await Clipboard.setData(const ClipboardData(text: 'soporte@novapay.es'));
                if (!mounted) return;
                Get.snackbar('Verifactu', 'Email de soporte copiado: soporte@novapay.es');
              },
              icon: const Icon(Icons.copy),
              label: const Text('Copiar soporte'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _controller.resetLocalState();
                _hardResetAccessUi();
                await _showPostResetOptionsDialog();
              },
              child: const Text('Ya tramitada: limpiar estado local'),
            ),
          ],
        );
      },
    );
  }

  void _hardResetAccessUi() {
    setState(() {
      _companyCtrl.clear();
      _taxIdCtrl.clear();
      _addressCtrl.clear();
      _emailCtrl.clear();
      _passwordCtrl.clear();
      _passwordConfirmCtrl.clear();
      _hashCtrl.clear();
      _authEmailCtrl.clear();
      _authPasswordCtrl.clear();

      _selectedPlanCode = 'PLAN_5000';
      _selectedBillingCycle = 'MONTHLY';
      _isNewSystem = false;
      _showRegisterPassword = false;
      _showRegisterPasswordConfirm = false;
      _showLoginPassword = false;
      _showRegisterAccessForm = false;

      _prefilledFromAdmin = false;
    });
  }

  Widget _buildControlTab(ThemeData theme, bool registered, bool requiresAuth, bool canUseBackend) {
    final connected = canUseBackend || _controller.hasActiveJwtSession.value;
    final admin = _controller.adminUser.value;
    final summary = _controller.subscriptionSummary.value;

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  registered ? 'Administración Verifactu' : 'Registro Verifactu',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  !registered
                      ? 'Para empezar debes completar el registro, escoger plan y enviar los datos de empresa.'
                      : requiresAuth
                      ? 'Estado: registrado, requiere autenticación periódica.'
                      : 'Estado: backend activo.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                if (summary != null)
                  Text(
                    'Plan actual: ${summary.planCode} (${summary.billingCycle})',
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                if (summary != null) ...[
                  const SizedBox(height: 4),
                  Text('Periodo vigente: ${_formatDate(summary.periodStart)} - ${_formatDate(summary.periodEnd)}'),
                  Text('Facturas disponibles del plan: ${summary.remainingInvoices} de ${summary.includedInvoices}'),
                  Text('Facturas consumidas: ${summary.consumedInvoices}'),
                  const SizedBox(height: 8),
                ],
                if (connected && summary == null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      'Sincronizando plan y consumo...',
                      style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
                    ),
                  ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      onPressed: _controller.isSubmitting.value ? null : _controller.refreshStatus,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Actualizar estado'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _controller.isSubmitting.value
                          ? null
                          : () async {
                              await _controller.refreshSubscriptionSummary(showSnackbarOnError: true);
                              await _showConsumptionSummaryDialog(theme);
                            },
                      icon: const Icon(Icons.query_stats),
                      label: const Text('Actualizar consumo'),
                    ),
                    if (registered)
                      OutlinedButton.icon(
                        onPressed: _controller.isSubmitting.value ? null : _showCancellationDialog,
                        icon: const Icon(Icons.cancel_outlined),
                        label: const Text('Darse de baja'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (!registered) _buildRegisterCard(theme),
        if (registered)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Datos administrativos', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text('Empresa: ${admin?.companyName ?? '-'}'),
                  Text('CIF/NIF: ${admin?.taxId ?? '-'}'),
                  Text('Dirección: ${admin?.address ?? '-'}'),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.warning.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'El CIF queda bloqueado completamente tras la conexión/registro con backend. '
                      'Solo puede tramitarse cambio mediante soporte@novapay.es.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (registered)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Sesión backend', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  if (connected)
                    Text('Ya hay sesión activa con JWT. Puedes operar directamente o reconectar.')
                  else
                    const Text('Inicia sesión para activar backend fiscal y emitir con conexión real.'),
                  const SizedBox(height: 10),
                  if (!connected) ...[
                    TextFormField(
                      controller: _authEmailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(labelText: 'Email'),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _authPasswordCtrl,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Contraseña'),
                    ),
                    const SizedBox(height: 10),
                    FilledButton.icon(
                      onPressed: _controller.isSubmitting.value
                          ? null
                          : () => _controller.authenticateWithCredentials(
                              email: _authEmailCtrl.text.trim(),
                              password: _authPasswordCtrl.text,
                            ),
                      icon: const Icon(Icons.login),
                      label: const Text('Conectar backend'),
                    ),
                  ],
                  if (connected)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _controller.isSubmitting.value ? null : _showChangePasswordDialog,
                          icon: const Icon(Icons.password),
                          label: const Text('Cambiar contraseña'),
                        ),
                        OutlinedButton.icon(
                          onPressed: _controller.isSubmitting.value ? null : _controller.authenticateNow,
                          icon: const Icon(Icons.sync),
                          label: const Text('Reautenticar'),
                        ),
                        FilledButton.icon(
                          onPressed: _controller.isSubmitting.value ? null : _controller.disconnectBackend,
                          icon: const Icon(Icons.logout),
                          label: const Text('Cerrar sesión backend'),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        _buildConsumptionCard(theme),
      ],
    );
  }

  Widget _buildRegisterCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Registro backend Verifactu', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              TextFormField(
                controller: _companyCtrl,
                decoration: _fieldDecoration('Nombre empresa'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El nombre de empresa es obligatorio';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _taxIdCtrl,
                decoration: _fieldDecoration('Razón social (CIF/NIF)'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El CIF/NIF es obligatorio';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _addressCtrl,
                decoration: _fieldDecoration('Dirección'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'La direccion es obligatoria';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _emailCtrl,
                decoration: _fieldDecoration('Email de acceso'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El email es obligatorio';
                  }
                  final emailOk = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value.trim());
                  if (!emailOk) {
                    return 'Formato de email inválido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _passwordCtrl,
                obscureText: !_showRegisterPassword,
                onChanged: (_) => setState(() {}),
                decoration: _fieldDecoration(
                  'Contraseña',
                  helperText: '12+ caracteres, mayúscula, minúscula, número y símbolo',
                  suffixIcon: IconButton(
                    tooltip: _showRegisterPassword ? 'Ocultar contraseña' : 'Ver contraseña',
                    onPressed: () => setState(() => _showRegisterPassword = !_showRegisterPassword),
                    icon: Icon(_showRegisterPassword ? Icons.visibility_off : Icons.visibility),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'La contraseña es obligatoria';
                  }
                  final detail = _passwordValidationMessage(value);
                  if (detail != null) return detail;
                  return null;
                },
              ),
              const SizedBox(height: 4),
              _buildPasswordHint(theme, _passwordCtrl.text),
              const SizedBox(height: 8),
              TextFormField(
                controller: _passwordConfirmCtrl,
                obscureText: !_showRegisterPasswordConfirm,
                decoration: _fieldDecoration(
                  'Confirmar contraseña',
                  suffixIcon: IconButton(
                    tooltip: _showRegisterPasswordConfirm ? 'Ocultar contraseña' : 'Ver contraseña',
                    onPressed: () => setState(() => _showRegisterPasswordConfirm = !_showRegisterPasswordConfirm),
                    icon: Icon(_showRegisterPasswordConfirm ? Icons.visibility_off : Icons.visibility),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Debes confirmar la contraseña';
                  }
                  if (value != _passwordCtrl.text) {
                    return 'No coincide con la contraseña';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              Text('Volumen de plan', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _buildPlanCard(
                    title: 'Plan 5000',
                    subtitle: 'Hasta 5000 facturas',
                    selected: _selectedPlanCode == 'PLAN_5000',
                    onTap: () => setState(() => _selectedPlanCode = 'PLAN_5000'),
                  ),
                  _buildPlanCard(
                    title: 'Plan 8000',
                    subtitle: 'Hasta 8000 facturas',
                    selected: _selectedPlanCode == 'PLAN_8000',
                    onTap: () => setState(() => _selectedPlanCode = 'PLAN_8000'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('Plan de pago', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  ChoiceChip(
                    label: const Text('Mensual'),
                    selected: _selectedBillingCycle == 'MONTHLY',
                    onSelected: (_) => setState(() => _selectedBillingCycle = 'MONTHLY'),
                    selectedColor: AppTheme.primary.withValues(alpha: 0.18),
                    side: BorderSide(
                      color: _selectedBillingCycle == 'MONTHLY' ? AppTheme.primary : Colors.grey.shade400,
                    ),
                  ),
                  ChoiceChip(
                    label: const Text('Anual'),
                    selected: _selectedBillingCycle == 'YEARLY',
                    onSelected: (_) => setState(() => _selectedBillingCycle = 'YEARLY'),
                    selectedColor: AppTheme.primary.withValues(alpha: 0.18),
                    side: BorderSide(
                      color: _selectedBillingCycle == 'YEARLY' ? AppTheme.primary : Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _selectedPlanCode == 'PLAN_5000'
                    ? (_selectedBillingCycle == 'MONTHLY'
                          ? 'Cuota: 12 EUR/mes · Límite: 5000 · Exceso: 0,05 EUR/factura'
                          : 'Cuota: 110 EUR/año · Límite: 5000 · Exceso: 0,05 EUR/factura')
                    : (_selectedBillingCycle == 'MONTHLY'
                          ? 'Cuota: 15 EUR/mes · Límite: 8000 · Exceso: 0,05 EUR/factura'
                          : 'Cuota: 165 EUR/año · Límite: 8000 · Exceso: 0,05 EUR/factura'),
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Nuevo en sistema Verifactu'),
                value: _isNewSystem,
                onChanged: (v) => setState(() {
                  _isNewSystem = v ?? false;
                  if (_isNewSystem) {
                    _hashCtrl.clear();
                  }
                }),
              ),
              TextFormField(
                controller: _hashCtrl,
                enabled: !_isNewSystem,
                decoration: _fieldDecoration(
                  'Hash Verifactu',
                  helperText: 'Si es nuevo en Verifactu, deja este campo vacio marcando la casilla.',
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _controller.isSubmitting.value
                    ? null
                    : () {
                        if (!_validateRegisterForm()) {
                          return;
                        }
                        _authEmailCtrl.text = _emailCtrl.text.trim();
                        _authPasswordCtrl.text = _passwordCtrl.text;

                        _controller.registerBackend(
                          companyName: _companyCtrl.text.trim(),
                          taxId: _taxIdCtrl.text.trim(),
                          address: _addressCtrl.text.trim(),
                          email: _emailCtrl.text.trim(),
                          password: _passwordCtrl.text,
                          passwordConfirmation: _passwordConfirmCtrl.text,
                          planCode: _selectedPlanCode,
                          billingCycle: _selectedBillingCycle,
                          isNewSystem: _isNewSystem,
                          hash: _isNewSystem ? null : _hashCtrl.text.trim(),
                        );
                      },
                icon: const Icon(Icons.app_registration),
                label: const Text('Registrar backend'),
              ),
              const SizedBox(height: 8),
              Text(
                'Al completar este registro se bloquea la modificación del CIF por cumplimiento normativo.',
                style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Iniciar sesión backend', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            const Text('Introduce email y contraseña para conectar con backend Verifactu.'),
            const SizedBox(height: 10),
            TextFormField(
              controller: _authEmailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: _fieldDecoration('Email'),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _authPasswordCtrl,
              obscureText: !_showLoginPassword,
              decoration: _fieldDecoration(
                'Contraseña',
                suffixIcon: IconButton(
                  tooltip: _showLoginPassword ? 'Ocultar contraseña' : 'Ver contraseña',
                  onPressed: () => setState(() => _showLoginPassword = !_showLoginPassword),
                  icon: Icon(_showLoginPassword ? Icons.visibility_off : Icons.visibility),
                ),
              ),
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: _controller.isSubmitting.value
                  ? null
                  : () => _controller.authenticateWithCredentials(
                      email: _authEmailCtrl.text.trim(),
                      password: _authPasswordCtrl.text,
                    ),
              icon: const Icon(Icons.login),
              label: const Text('Conectar backend'),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _controller.isSubmitting.value
                  ? null
                  : () => _controller.requestPasswordRecovery(_authEmailCtrl.text.trim()),
              icon: const Icon(Icons.lock_reset),
              label: const Text('Recuperar contraseña'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreAccessView(ThemeData theme, bool registered) {
    final showingRegister = !registered && _showRegisterAccessForm;

    if (registered) {
      return ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Text(
            'Inicia sesión para acceder al panel de facturación, plan y consumo.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 10),
          _buildLoginCard(theme),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _controller.isSubmitting.value ? null : _showCancellationDialog,
              icon: const Icon(Icons.cancel_outlined),
              label: const Text('Solicitar baja'),
            ),
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Text(
          showingRegister
              ? 'Completa el registro para crear el acceso de backend.'
              : 'Inicia sesión para acceder al panel de facturación, plan y consumo.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 10),
        showingRegister ? _buildRegisterCard(theme) : _buildLoginCard(theme),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: _controller.isSubmitting.value
                  ? null
                  : () => setState(() {
                      _showRegisterAccessForm = false;
                    }),
              child: Text(
                'Login',
                style: TextStyle(fontWeight: !_showRegisterAccessForm ? FontWeight.w700 : FontWeight.w500),
              ),
            ),
            const Text(' · '),
            TextButton(
              onPressed: _controller.isSubmitting.value
                  ? null
                  : () => setState(() {
                      _showRegisterAccessForm = true;
                    }),
              child: Text(
                'Registrar',
                style: TextStyle(fontWeight: _showRegisterAccessForm ? FontWeight.w700 : FontWeight.w500),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTicketsTab(ThemeData theme, bool canUseBackend) {
    if (!canUseBackend) {
      return Center(
        child: Text(
          'Modo local activo: no se harán intentos de conexión al backend al emitir tickets.',
          style: theme.textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
      );
    }

    if (_controller.isLoading.value && _controller.interactions.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_controller.errorMessage.value != null && _controller.interactions.isEmpty) {
      return Center(child: Text(_controller.errorMessage.value!, style: theme.textTheme.bodyMedium));
    }

    if (_controller.interactions.isEmpty) {
      return Center(child: Text('Aún no hay interacciones enviadas al backend.', style: theme.textTheme.bodyMedium));
    }

    final interactions = _filteredInteractions(_controller.interactions.toList());
    final retryableCount = interactions.where((item) => _isRetryableStatus(item.status)).length;

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ActionChip(
              avatar: Icon(
                _interactionDateFilter != null ? Icons.event : Icons.calendar_today,
                size: 16,
                color: _interactionDateFilter != null ? AppTheme.primary : AppTheme.textSecondary,
              ),
              label: Text(
                _interactionDateFilter != null ? AppFormats.date.format(_interactionDateFilter!) : 'Filtrar por fecha',
                style: TextStyle(
                  color: _interactionDateFilter != null ? AppTheme.primary : AppTheme.textSecondary,
                  fontWeight: _interactionDateFilter != null ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              onPressed: _pickInteractionDate,
            ),
            if (_interactionDateFilter != null)
              ActionChip(
                avatar: const Icon(Icons.close, size: 16),
                label: const Text('Limpiar fecha'),
                onPressed: () => setState(() => _interactionDateFilter = null),
              ),
            ActionChip(
              avatar: Icon(
                Icons.refresh,
                size: 16,
                color: retryableCount > 0 ? AppTheme.error : AppTheme.textSecondary,
              ),
              label: Text('Reenviar rechazados ($retryableCount)'),
              onPressed: (_controller.isSubmitting.value || retryableCount == 0)
                  ? null
                  : () => _controller.retryRejectedInteractions(interactions),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (interactions.isEmpty)
          Center(child: Text('No hay facturas para estos filtros.', style: theme.textTheme.bodyMedium))
        else
          ...interactions.map((item) {
            final color = _statusColor(item.status);
            return Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: AppTheme.border),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Factura ${item.invoiceSeries}-${item.invoiceNumber}',
                            style: theme.textTheme.titleMedium,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            item.status,
                            style: theme.textTheme.labelMedium?.copyWith(color: color, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 16,
                      runSpacing: 6,
                      children: [
                        Text('Importe: ${_money.format(item.totalAmount)}'),
                        Text('Issue date: ${item.issueDate}'),
                        Text('Reintentos: ${item.retryCount}'),
                        Text('Enviado: ${_formatDate(item.sentAt)}'),
                        Text('Respuesta: ${_formatDate(item.respondedAt)}'),
                      ],
                    ),
                    if (item.secureVerificationCode != null && !_isRetryableStatus(item.status)) ...[
                      const SizedBox(height: 8),
                      Text(
                        'CSV: ${item.secureVerificationCode}',
                        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                    if (item.responseDescription != null && item.responseDescription!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        _isRetryableStatus(item.status)
                            ? 'Motivo rechazo: ${item.responseDescription!}'
                            : item.responseDescription!,
                        style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
                      ),
                    ],
                    if (item.responseCode != null && item.responseCode!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        _isRetryableStatus(item.status)
                            ? 'Código rechazo: ${item.responseCode}'
                            : 'Código AEAT: ${item.responseCode}',
                        style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                    if (_isRetryableStatus(item.status)) ...[
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton.icon(
                          onPressed: _controller.isSubmitting.value ? null : () => _controller.retryInteraction(item),
                          icon: const Icon(Icons.restart_alt),
                          label: const Text('Reenviar ticket'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Obx(() {
      final state = _controller.backendState.value;
      final admin = _controller.adminUser.value;
      if (!_prefilledFromAdmin && admin != null) {
        _companyCtrl.text = admin.companyName ?? _companyCtrl.text;
        _taxIdCtrl.text = admin.taxId ?? _taxIdCtrl.text;
        _addressCtrl.text = admin.address ?? _addressCtrl.text;
        _prefilledFromAdmin = true;
      }
      final canUseBackend = state?.canUseBackend ?? false;
      final canOperateBackend = canUseBackend || _controller.hasActiveJwtSession.value;
      final requiresAuth = state?.requiresAuth ?? false;
      final registered = state?.registered ?? false;
      final effectiveRegistered = registered || _controller.hasActiveJwtSession.value;

      if (!canOperateBackend) {
        _autoRequestedSummary = false;
      } else if (_controller.subscriptionSummary.value == null && !_autoRequestedSummary) {
        _autoRequestedSummary = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _controller.refreshSubscriptionSummary(showSnackbarOnError: false);
        });
      }

      if (!canOperateBackend) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text('Acceso Verifactu', style: theme.textTheme.headlineSmall),
            ),
            const Divider(height: 1),
            Expanded(child: _buildPreAccessView(theme, registered)),
          ],
        );
      }

      return DefaultTabController(
        length: 2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text('Panel Verifactu', style: theme.textTheme.headlineSmall),
            ),
            TabBar(
              tabs: [
                Tab(icon: const Icon(Icons.business), text: effectiveRegistered ? 'Administración' : 'Registro'),
                const Tab(icon: Icon(Icons.receipt_long), text: 'Facturas/Tickets'),
              ],
            ),
            const Divider(height: 1),
            Expanded(
              child: TabBarView(
                children: [
                  _buildControlTab(theme, effectiveRegistered, requiresAuth, canOperateBackend),
                  _buildTicketsTab(theme, canOperateBackend),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}
