// lib/presentation/widgets/profile/profile_form_widget.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../../../data/models/user.dart';
import '../../../data/models/business_config.dart';
import '../../../services/config_service.dart';
import '../../controllers/user_controller.dart';

/// Widget reutilizable de edición de perfil.
/// Usado en [PersonalAreaSection] (admin) y [ProfilePage] (usuario).
class ProfileFormWidget extends StatefulWidget {
  final User user;
  final bool isAdminContext;
  final VoidCallback? onOpenVerifactu;

  const ProfileFormWidget({super.key, required this.user, this.isAdminContext = false, this.onOpenVerifactu});

  @override
  State<ProfileFormWidget> createState() => _ProfileFormWidgetState();
}

class _ProfileFormWidgetState extends State<ProfileFormWidget> {
  late final TextEditingController _usernameCtrl;
  late final TextEditingController _lastNameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _passwordCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _ticketDisplayNameCtrl;
  late final TextEditingController _companyNameCtrl;
  late final TextEditingController _fiscalNameCtrl;
  late final TextEditingController _taxIdCtrl;
  late final TextEditingController _addressCtrl;
  late final ImagePicker _imagePicker;
  bool _saving = false;
  bool _showPassword = false;
  bool _hasLocalVerifactuLink = false;
  String? _logoPath;
  BusinessConfig? _businessConfig;

  @override
  void initState() {
    super.initState();
    _imagePicker = ImagePicker();
    _usernameCtrl = TextEditingController(text: widget.user.username ?? '');
    _lastNameCtrl = TextEditingController(text: widget.user.lastName ?? '');
    _phoneCtrl = TextEditingController(text: widget.user.phone ?? '');
    _emailCtrl = TextEditingController(text: widget.user.email ?? '');
    _passwordCtrl = TextEditingController();
    _ticketDisplayNameCtrl = TextEditingController(text: widget.user.ticketDisplayName ?? '');
    _companyNameCtrl = TextEditingController(text: widget.user.companyName ?? '');
    _fiscalNameCtrl = TextEditingController();
    _taxIdCtrl = TextEditingController(text: widget.user.taxId ?? '');
    _addressCtrl = TextEditingController(text: widget.user.address ?? '');
    _logoPath = widget.user.logoPath;
    _loadBusinessData();
    _loadLocalVerifactuLock();
  }

  Future<void> _loadBusinessData() async {
    if (!_showCompanyFields) {
      return;
    }

    try {
      final configService = Get.find<ConfigService>();
      _businessConfig = await configService.getBusinessConfig();
      final business = _businessConfig;
      if (business == null) {
        return;
      }

      if (business.businessName.trim().isNotEmpty) {
        _companyNameCtrl.text = business.businessName;
      }
      if (business.fiscalName.trim().isNotEmpty) {
        _fiscalNameCtrl.text = business.fiscalName;
      }
      if (business.cifNif.trim().isNotEmpty) {
        _taxIdCtrl.text = business.cifNif;
      }
      if (business.address.trim().isNotEmpty) {
        _addressCtrl.text = business.address;
      }
      if (business.logoPath != null && business.logoPath!.trim().isNotEmpty) {
        _logoPath = business.logoPath;
      }

      if (mounted) {
        setState(() {});
      }
    } catch (_) {
      // Si falla la carga, se mantienen valores del usuario admin como fallback.
    }
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _lastNameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _ticketDisplayNameCtrl.dispose();
    _companyNameCtrl.dispose();
    _fiscalNameCtrl.dispose();
    _taxIdCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  String get _initial {
    final name = widget.user.username ?? widget.user.email ?? 'U';
    return name[0].toUpperCase();
  }

  bool get _showCompanyFields => widget.isAdminContext || widget.user.role == 'admin';
  bool get _fiscalFieldsLocked => widget.user.backendEditable || _hasLocalVerifactuLink;

  Future<void> _loadLocalVerifactuLock() async {
    try {
      final cfg = await Get.find<ConfigService>().getConfig();
      final linkedToVerifactu =
          cfg.verifactuRegistered ||
          (cfg.verifactuClientId != null && cfg.verifactuClientId!.trim().isNotEmpty) ||
          cfg.verifactuLastAuthAt != null;
      if (!mounted) {
        return;
      }
      setState(() {
        _hasLocalVerifactuLink = linkedToVerifactu;
      });
    } catch (_) {
      // Si no se puede leer configuración, mantenemos el bloqueo backendEditable existente.
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);

    widget.user
      ..username = _usernameCtrl.text.trim()
      ..lastName = _lastNameCtrl.text.trim()
      ..phone = _phoneCtrl.text.trim()
      ..email = _emailCtrl.text.trim()
      ..ticketDisplayName = _ticketDisplayNameCtrl.text.trim();

    // Los datos de empresa se reflejan en ticket; CIF/NIF se bloquea al enlazar Verifactu.
    if (_showCompanyFields) {
      widget.user
        ..companyName = _companyNameCtrl.text.trim()
        ..taxId = _fiscalFieldsLocked ? widget.user.taxId : _taxIdCtrl.text.trim()
        ..address = _fiscalFieldsLocked ? widget.user.address : _addressCtrl.text.trim();

      final configService = Get.find<ConfigService>();
      final business = _businessConfig ?? (await configService.getBusinessConfig()) ?? BusinessConfig();
      business
        ..businessName = _companyNameCtrl.text.trim()
        ..fiscalName = _fiscalFieldsLocked ? business.fiscalName : _fiscalNameCtrl.text.trim()
        ..cifNif = _fiscalFieldsLocked ? business.cifNif : _taxIdCtrl.text.trim()
        ..address = _fiscalFieldsLocked ? business.address : _addressCtrl.text.trim()
        ..logoPath = _logoPath;
      await configService.saveBusinessConfig(business);
      _businessConfig = business;
    }
    if (_showCompanyFields) {
      widget.user.logoPath = _logoPath;
    }

    if (_passwordCtrl.text.isNotEmpty) {
      widget.user.password = _passwordCtrl.text;
    }

    await Get.find<UserController>().save(widget.user);

    if (!mounted) return;

    _passwordCtrl.clear();
    setState(() => _saving = false);

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Datos actualizados correctamente')));
  }

  Future<void> _pickLogo() async {
    final pickedFile = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;
    setState(() => _logoPath = pickedFile.path);
  }

  void _removeLogo() {
    setState(() => _logoPath = null);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ── Avatar ───────────────────────────────────────────────
                CircleAvatar(
                  radius: 48,
                  backgroundColor: theme.colorScheme.primary,
                  child: Text(
                    _initial,
                    style: const TextStyle(fontSize: 40, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 12),
                Text(widget.user.username ?? widget.user.email ?? '', style: theme.textTheme.headlineMedium),
                Text(
                  widget.user.email ?? '',
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 32),

                // ── Datos personales ─────────────────────────────────────
                _SectionLabel(label: 'Datos personales'),
                const SizedBox(height: 12),
                TextField(
                  controller: _usernameCtrl,
                  decoration: const InputDecoration(labelText: 'Nombre', prefixIcon: Icon(Icons.person_outline)),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _lastNameCtrl,
                  decoration: const InputDecoration(labelText: 'Apellidos', prefixIcon: Icon(Icons.person_outline)),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _phoneCtrl,
                  decoration: const InputDecoration(labelText: 'Teléfono', prefixIcon: Icon(Icons.phone_outlined)),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _ticketDisplayNameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nombre a mostrar en ticket',
                    prefixIcon: Icon(Icons.receipt_long_outlined),
                    helperText: 'Si lo dejas vacío se usará tu nombre y apellidos.',
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _emailCtrl,
                  readOnly: false,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: const Icon(Icons.email_outlined),
                    suffixIcon: const Icon(Icons.edit_outlined, size: 18),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 32),

                // ── Cambio de contraseña ──────────────────────────────────
                _SectionLabel(label: 'Cambiar contraseña'),
                const SizedBox(height: 12),
                TextField(
                  controller: _passwordCtrl,
                  obscureText: !_showPassword,
                  decoration: InputDecoration(
                    labelText: 'Nueva contraseña (opcional)',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      onPressed: () => setState(() => _showPassword = !_showPassword),
                      icon: Icon(_showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                      tooltip: _showPassword ? 'Ocultar contraseña' : 'Mostrar contraseña',
                    ),
                  ),
                ),

                // ── Datos de empresa (solo admin) ──────────────────────────
                if (_showCompanyFields) ...[
                  const SizedBox(height: 32),
                  _SectionLabel(label: 'Datos de empresa', theme: theme),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Estos campos se usan para imprimir el ticket.',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _companyNameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nombre del bar (título ticket)',
                      prefixIcon: const Icon(Icons.business_outlined),
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _fiscalNameCtrl,
                    readOnly: _fiscalFieldsLocked,
                    decoration: InputDecoration(
                      labelText: 'Nombre fiscal (debajo, pequeño)',
                      prefixIcon: const Icon(Icons.description_outlined),
                      filled: _fiscalFieldsLocked,
                      fillColor: _fiscalFieldsLocked ? theme.colorScheme.surfaceContainerHighest : null,
                      suffixIcon: _fiscalFieldsLocked ? const Icon(Icons.lock_outline, size: 18) : null,
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _taxIdCtrl,
                    readOnly: _fiscalFieldsLocked,
                    decoration: InputDecoration(
                      labelText: 'CIF/NIF',
                      prefixIcon: const Icon(Icons.badge_outlined),
                      filled: _fiscalFieldsLocked,
                      fillColor: _fiscalFieldsLocked ? theme.colorScheme.surfaceContainerHighest : null,
                      suffixIcon: _fiscalFieldsLocked ? const Icon(Icons.lock_outline, size: 18) : null,
                    ),
                    textCapitalization: TextCapitalization.characters,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _addressCtrl,
                    readOnly: _fiscalFieldsLocked,
                    decoration: InputDecoration(
                      labelText: 'Dirección fiscal',
                      prefixIcon: const Icon(Icons.location_on_outlined),
                      filled: _fiscalFieldsLocked,
                      fillColor: _fiscalFieldsLocked ? theme.colorScheme.surfaceContainerHighest : null,
                      suffixIcon: _fiscalFieldsLocked ? const Icon(Icons.lock_outline, size: 18) : null,
                    ),
                    textCapitalization: TextCapitalization.words,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  Text('Logo', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  if (_logoPath != null && _logoPath!.isNotEmpty)
                    Column(
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            border: Border.all(color: theme.colorScheme.outline),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(7),
                            child: Image.file(File(_logoPath!), fit: BoxFit.contain),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            OutlinedButton.icon(
                              onPressed: _pickLogo,
                              icon: const Icon(Icons.image_outlined),
                              label: const Text('Cambiar'),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton.icon(
                              onPressed: _removeLogo,
                              icon: const Icon(Icons.delete_outline),
                              label: const Text('Quitar'),
                            ),
                          ],
                        ),
                      ],
                    )
                  else
                    OutlinedButton.icon(
                      onPressed: _pickLogo,
                      icon: const Icon(Icons.upload_file_outlined),
                      label: const Text('Cargar logo'),
                    ),
                  if (_fiscalFieldsLocked)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Nombre fiscal, CIF/NIF y dirección fiscal bloqueados por cumplimiento legal al estar enlazado con Verifactu.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          if (widget.isAdminContext && widget.onOpenVerifactu != null) ...[
                            const SizedBox(height: 8),
                            OutlinedButton.icon(
                              onPressed: widget.onOpenVerifactu,
                              icon: const Icon(Icons.verified_user),
                              label: const Text('Abrir pestaña Verifactu'),
                            ),
                          ],
                        ],
                      ),
                    ),
                ],
                const SizedBox(height: 28),

                // ── Guardar ───────────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.save_outlined),
                    label: const Text('Guardar cambios'),
                    onPressed: _saving ? null : _save,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Widget auxiliar de cabecera de sección ────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  final ThemeData? theme;

  const _SectionLabel({required this.label, this.theme});

  @override
  Widget build(BuildContext context) {
    final resolvedTheme = theme ?? Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(label, style: resolvedTheme.textTheme.headlineSmall),
        ),
        const Divider(),
      ],
    );
  }
}
