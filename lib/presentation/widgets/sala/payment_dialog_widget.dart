// lib/presentation/widgets/sala/payment_dialog_widget.dart
import 'package:flutter/material.dart';

import '../../../config/app_formats.dart';
import '../../../data/models/ticket.dart';
import '../common/app_text_field.dart';

/// Diálogo de cobro simplificado.
/// Muestra el total, permite elegir método de pago y calcular el cambio en efectivo.
/// No permite pago parcial por líneas.
class PaymentDialogWidget extends StatefulWidget {
  final double total;
  final void Function(PaymentMethod method, double mixedCash, double mixedCard) onConfirm;

  const PaymentDialogWidget({super.key, required this.total, required this.onConfirm});

  static Future<void> show(
    BuildContext context, {
    required double total,
    required void Function(PaymentMethod method, double mixedCash, double mixedCard) onConfirm,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => PaymentDialogWidget(total: total, onConfirm: onConfirm),
    );
  }

  @override
  State<PaymentDialogWidget> createState() => _PaymentDialogWidgetState();
}

class _PaymentDialogWidgetState extends State<PaymentDialogWidget> {
  final _fmt = AppFormats.currency;
  final _cashCtrl = TextEditingController();
  final _mixedCashCtrl = TextEditingController();

  PaymentMethod _method = PaymentMethod.efectivo;
  double _cashGiven = 0;
  double _mixedCash = 0;

  @override
  void dispose() {
    _cashCtrl.dispose();
    _mixedCashCtrl.dispose();
    super.dispose();
  }

  double get _change => _method == PaymentMethod.efectivo ? (_cashGiven - widget.total).clamp(0, double.infinity) : 0;
  double get _mixedCard => (widget.total - _mixedCash).clamp(0, widget.total);

  bool get _canConfirm {
    if (_method == PaymentMethod.efectivo) return _cashGiven >= widget.total;
    if (_method == PaymentMethod.mixto) return _mixedCash > 0 && _mixedCash < widget.total;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Cobrar'),
      contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      content: SizedBox(
        width: 340,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Total ──────────────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Text(
                    'Total a cobrar',
                    style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onPrimaryContainer),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _fmt.format(widget.total),
                    style: theme.textTheme.displaySmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Método de pago ─────────────────────────────────────────────
            Text('Forma de pago', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Row(
              children: [
                _MethodButton(
                  label: 'Efectivo',
                  icon: Icons.payments_outlined,
                  selected: _method == PaymentMethod.efectivo,
                  onTap: () => setState(() {
                    _method = PaymentMethod.efectivo;
                    _cashGiven = 0;
                    _cashCtrl.clear();
                  }),
                ),
                const SizedBox(width: 8),
                _MethodButton(
                  label: 'Tarjeta',
                  icon: Icons.credit_card_outlined,
                  selected: _method == PaymentMethod.tarjeta,
                  onTap: () => setState(() => _method = PaymentMethod.tarjeta),
                ),
                const SizedBox(width: 8),
                _MethodButton(
                  label: 'Mixto',
                  icon: Icons.compare_arrows,
                  selected: _method == PaymentMethod.mixto,
                  onTap: () => setState(() {
                    _method = PaymentMethod.mixto;
                    _mixedCash = 0;
                    _mixedCashCtrl.clear();
                  }),
                ),
              ],
            ),

            // ── Efectivo: importe entregado y cambio ───────────────────────
            if (_method == PaymentMethod.efectivo) ...[
              const SizedBox(height: 14),
              AppTextField(
                controller: _cashCtrl,
                hintText: 'Cliente entrega (€)',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Cliente entrega (€)',
                  prefixIcon: Icon(Icons.euro),
                  isDense: true,
                ),
                onChanged: (v) => setState(() => _cashGiven = double.tryParse(v.replaceAll(',', '.')) ?? 0),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Cambio', style: theme.textTheme.bodyMedium),
                  Text(
                    _fmt.format(_change),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: _change >= 0 ? theme.colorScheme.primary : theme.colorScheme.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],

            // ── Mixto: Desglose manual ────────────────────────────────────
            if (_method == PaymentMethod.mixto) ...[
              const SizedBox(height: 14),
              AppTextField(
                controller: _mixedCashCtrl,
                hintText: 'Parte en Efectivo (€)',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Efectivo (€)',
                  prefixIcon: Icon(Icons.payments_outlined),
                  isDense: true,
                ),
                onChanged: (v) => setState(() => _mixedCash = double.tryParse(v.replaceAll(',', '.')) ?? 0),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Resto con Tarjeta', style: theme.textTheme.bodyMedium),
                  Text(
                    _fmt.format(_mixedCard),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: theme.colorScheme.secondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 8),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        ElevatedButton(
          onPressed: _canConfirm
              ? () {
                  Navigator.pop(context);
                  if (_method == PaymentMethod.mixto) {
                    widget.onConfirm(_method, _mixedCash, _mixedCard);
                  } else {
                    widget.onConfirm(_method, 0, 0);
                  }
                }
              : null,
          child: const Text('Cobrar'),
        ),
      ],
    );
  }
}

// ── Botón de método de pago ───────────────────────────────────────────────────

class _MethodButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _MethodButton({required this.label, required this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? theme.colorScheme.primaryContainer : theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
            border: selected ? Border.all(color: theme.colorScheme.primary, width: 1.5) : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: selected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant),
              const SizedBox(height: 2),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: selected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
