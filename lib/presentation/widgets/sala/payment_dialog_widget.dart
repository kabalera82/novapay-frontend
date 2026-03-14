// lib/presentation/widgets/sala/payment_dialog_widget.dart
import 'package:flutter/material.dart';

import '../../../config/app_formats.dart';
import '../../../data/models/ticket.dart';
import '../../../data/models/ticket_line.dart';

/// Diálogo de cobro con selección de líneas y cálculo de cambio.
class PaymentDialogWidget extends StatefulWidget {
  final List<TicketLine> lines;
  final void Function(List<int> lineIndices, PaymentMethod method) onConfirm;

  const PaymentDialogWidget({
    super.key,
    required this.lines,
    required this.onConfirm,
  });

  /// Abre el diálogo y devuelve el resultado.
  static Future<void> show(
    BuildContext context, {
    required List<TicketLine> lines,
    required void Function(List<int> lineIndices, PaymentMethod method)
        onConfirm,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => PaymentDialogWidget(lines: lines, onConfirm: onConfirm),
    );
  }

  @override
  State<PaymentDialogWidget> createState() => _PaymentDialogWidgetState();
}

class _PaymentDialogWidgetState extends State<PaymentDialogWidget> {
  final _fmt      = AppFormats.currency;
  final _cashCtrl = TextEditingController();

  late final List<bool> _selected;
  PaymentMethod _method    = PaymentMethod.efectivo;
  double        _cashGiven = 0;

  @override
  void initState() {
    super.initState();
    _selected = List.filled(widget.lines.length, true);
  }

  @override
  void dispose() {
    _cashCtrl.dispose();
    super.dispose();
  }

  // ── Cálculos ──────────────────────────────────────────────────────────────

  double get _subtotal {
    double total = 0;
    for (int i = 0; i < widget.lines.length; i++) {
      if (_selected[i]) total += widget.lines[i].totalLine;
    }
    return total;
  }

  double get _change => _method == PaymentMethod.efectivo
      ? (_cashGiven - _subtotal).clamp(0, double.infinity)
      : 0;

  bool get _canConfirm {
    if (!_selected.contains(true)) return false;
    if (_method == PaymentMethod.efectivo) return _cashGiven >= _subtotal;
    return true;
  }

  List<int> get _selectedIndices =>
      [for (int i = 0; i < _selected.length; i++) if (_selected[i]) i];

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Cobrar'),
      contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Selección de líneas ──────────────────────────────────────
            Text('Selecciona qué se paga', style: theme.textTheme.labelLarge),
            const SizedBox(height: 4),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: widget.lines.length,
                itemBuilder: (_, i) {
                  final line = widget.lines[i];
                  return CheckboxListTile(
                    dense:         true,
                    value:         _selected[i],
                    controlAffinity: ListTileControlAffinity.leading,
                    title: Text(
                      '${line.productName} ×${line.quantity}',
                      style: theme.textTheme.bodyMedium,
                    ),
                    secondary: Text(
                      _fmt.format(line.totalLine),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onChanged: (v) =>
                        setState(() => _selected[i] = v ?? false),
                  );
                },
              ),
            ),

            const Divider(),

            // ── Total seleccionado ────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total a cobrar', style: theme.textTheme.labelLarge),
                Text(
                  _fmt.format(_subtotal),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ── Método de pago ────────────────────────────────────────────
            Text('Forma de pago', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Row(
              children: [
                _MethodButton(
                  label:    'Efectivo',
                  icon:     Icons.payments_outlined,
                  selected: _method == PaymentMethod.efectivo,
                  onTap:    () => setState(() {
                    _method    = PaymentMethod.efectivo;
                    _cashGiven = 0;
                    _cashCtrl.clear();
                  }),
                ),
                const SizedBox(width: 8),
                _MethodButton(
                  label:    'Tarjeta',
                  icon:     Icons.credit_card_outlined,
                  selected: _method == PaymentMethod.tarjeta,
                  onTap:    () => setState(() => _method = PaymentMethod.tarjeta),
                ),
                const SizedBox(width: 8),
                _MethodButton(
                  label:    'Mixto',
                  icon:     Icons.compare_arrows,
                  selected: _method == PaymentMethod.mixto,
                  onTap:    () => setState(() => _method = PaymentMethod.mixto),
                ),
              ],
            ),

            // ── Efectivo: importe dado y cambio ───────────────────────────
            if (_method == PaymentMethod.efectivo) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _cashCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText:   'Cliente entrega (€)',
                  prefixIcon:  Icon(Icons.euro),
                  isDense:     true,
                ),
                onChanged: (v) => setState(
                  () => _cashGiven = double.tryParse(v.replaceAll(',', '.')) ?? 0,
                ),
              ),
              const SizedBox(height: 8),
              _ChangeRow(
                label: 'Cambio',
                value: _fmt.format(_change),
                color: _change >= 0
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.error,
              ),
            ],

            const SizedBox(height: 8),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _canConfirm
              ? () {
                  Navigator.pop(context);
                  widget.onConfirm(_selectedIndices, _method);
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
  final String       label;
  final IconData     icon;
  final bool         selected;
  final VoidCallback onTap;

  const _MethodButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

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
            color: selected
                ? theme.colorScheme.primaryContainer
                : theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
            border: selected
                ? Border.all(color: theme.colorScheme.primary, width: 1.5)
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size:  20,
                color: selected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: selected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                  fontWeight:
                      selected ? FontWeight.w700 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Fila de cambio ────────────────────────────────────────────────────────────

class _ChangeRow extends StatelessWidget {
  final String label;
  final String value;
  final Color  color;

  const _ChangeRow({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: theme.textTheme.bodyMedium),
        Text(
          value,
          style: theme.textTheme.headlineSmall?.copyWith(
            color:      color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
