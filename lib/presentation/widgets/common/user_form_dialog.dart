// lib/presentation/widgets/common/user_form_dialog.dart
import 'package:flutter/material.dart';

import '../../../data/models/user.dart';
import '../../controllers/user_controller.dart';

/// Diálogo reutilizable para crear o editar un usuario.
///
/// Uso:
///   UserFormDialog.showCreate(context, userCtrl);
///   UserFormDialog.showEdit(context, userCtrl, user);
class UserFormDialog {
  UserFormDialog._();

  static Future<void> showCreate(
    BuildContext context,
    UserController userCtrl,
  ) {
    return _show(context, userCtrl, null);
  }

  static Future<void> showEdit(
    BuildContext context,
    UserController userCtrl,
    User user,
  ) {
    return _show(context, userCtrl, user);
  }

  static Future<void> _show(
    BuildContext context,
    UserController userCtrl,
    User? existing,
  ) {
    final isEdit       = existing != null;
    final emailCtrl    = TextEditingController(text: existing?.email    ?? '');
    final passCtrl     = TextEditingController();   // nunca pre-rellenar: evita rehashar el hash
    final usernameCtrl = TextEditingController(text: existing?.username ?? '');
    String selectedRole = existing?.role ?? 'user';

    return showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(isEdit ? 'Editar usuario' : 'Nuevo usuario'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: usernameCtrl,
                decoration: const InputDecoration(labelText: 'Nombre'),
              ),
              TextField(
                controller: emailCtrl,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              TextField(
                controller: passCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: isEdit ? 'Nueva contraseña (dejar vacío para no cambiar)' : 'Contraseña',
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: selectedRole,
                decoration: const InputDecoration(labelText: 'Rol'),
                items: const [
                  DropdownMenuItem(value: 'user',  child: Text('Usuario')),
                  DropdownMenuItem(value: 'admin', child: Text('Admin')),
                ],
                onChanged: (v) => setDialogState(() => selectedRole = v!),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (emailCtrl.text.isEmpty) return;
                if (!isEdit && passCtrl.text.isEmpty) return;
                if (isEdit) {
                  existing
                    ..username = usernameCtrl.text
                    ..email    = emailCtrl.text
                    ..role     = selectedRole;
                  // solo actualizar contraseña si el campo tiene contenido
                  if (passCtrl.text.isNotEmpty) {
                    existing.password = passCtrl.text;
                  }
                  await userCtrl.save(existing);
                } else {
                  final user = User()
                    ..username = usernameCtrl.text
                    ..email    = emailCtrl.text
                    ..password = passCtrl.text
                    ..role     = selectedRole;
                  await userCtrl.create(user);
                }
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
              },
              child: Text(isEdit ? 'Guardar' : 'Crear'),
            ),
          ],
        ),
      ),
    );
  }
}
