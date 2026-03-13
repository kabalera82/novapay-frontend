// lib/presentation/widgets/sala/ticket.panel.widget.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../data/models/product.dart';
import '../../../data/models/ticketLine.dart';
import '../../controllers/ticket.controller.dart';
import 'payment.dialog.widget.dart';
import 'product.picker.widget.dart';

/// Panel de gestión del ticket de una mesa.
/// Reutilizable en Sala y en el TPV principal.
class TicketPanelWidget extends StatefulWidget {
  final int          tableNumber;
  final VoidCallback onClose;

  const TicketPanelWidget({
    super.key,
    required this.tableNumber,
    required this.onClose,
  });

  @override
  State<TicketPanelWidget> createState() => _TicketPanelWidgetState();
}

class _TicketPanelWidgetState extends State<TicketPanelWidget> {
  final _ticketCtrl   = Get.find<TicketController>();
  final _fmt          = NumberFormat.currency(locale: 'es_ES', symbol: '€');
  bool  _showingPicker = false;

  // ── Añadir producto al ticket ─────────────────────────────────────────────

  Future<void> _addProduct(Product product) async {
    final line = TicketLine()
      ..productName   = product.name
      ..quantity      = 1
      ..priceAtMoment = product.price
      ..totalLine     = product.price;

    await _ticketCtrl.addLineToActive(line);
    if (mounted) setState(() => _showingPicker = false);
  }

  // ── Cobrar ────────────────────────────────────────────────────────────────

  void _showPayDialog() {
    final lines = _ticketCtrl.activeTicket.value?.lines ?? [];
    if (lines.isEmpty) return;

    PaymentDialogWidget.show(
      context,
      lines: List<TicketLine>.from(lines),
      onConfirm: (lineIndices, method) async {
        await _ticketCtrl.payLines(lineIndices, method);
        // Si el ticket quedó sin líneas (pagado) → cerrar panel
        if (_ticketCtrl.activeTicket.value == null) widget.onClose();
      },
    );
  }

  // ── Cancelar mesa ─────────────────────────────────────────────────────────

  Future<void> _cancel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancelar mesa'),
        content: const Text(
          '¿Seguro que quieres cancelar esta mesa? Se perderán todos los datos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancelar mesa'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _ticketCtrl.cancelActive();
      widget.onClose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // ── Cabecera ──────────────────────────────────────────────────────
        Container(
          color: theme.colorScheme.primaryContainer,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(
                Icons.table_restaurant,
                color: theme.colorScheme.onPrimaryContainer,
              ),
              const SizedBox(width: 8),
              Text(
                'Mesa ${widget.tableNumber}',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const Spacer(),
              Obx(
                () => Text(
                  _fmt.format(
                    _ticketCtrl.activeTicket.value?.totalAmount ?? 0,
                  ),
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                color: theme.colorScheme.onPrimaryContainer,
                tooltip: 'Cerrar panel',
                onPressed: widget.onClose,
              ),
            ],
          ),
        ),

        // ── Líneas del ticket ─────────────────────────────────────────────
        Expanded(
          child: Obx(() {
            final lines =
                _ticketCtrl.activeTicket.value?.lines ?? [];

            if (lines.isEmpty) {
              return Center(
                child: Text(
                  'Sin productos.\nPulsa Añadir para empezar.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              );
            }

            return ListView.separated(
              itemCount: lines.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (_, i) => _LineTile(
                line:       lines[i],
                fmt:        _fmt,
                onRemove:   () =>
                    _ticketCtrl.removeLineFromActive(lines[i].productName),
                onIncrease: () =>
                    _ticketCtrl.changeLineQuantity(lines[i].productName, 1),
                onDecrease: () =>
                    _ticketCtrl.changeLineQuantity(lines[i].productName, -1),
              ),
            );
          }),
        ),

        // ── Selector de productos (toggle inline) ─────────────────────────
        if (_showingPicker)
          SizedBox(
            height: 300,
            child: Column(
              children: [
                const Divider(height: 1),
                Expanded(
                  child: ProductPickerWidget(
                    onProductSelected: _addProduct,
                  ),
                ),
              ],
            ),
          ),

        // ── Acciones ──────────────────────────────────────────────────────
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(12),
          child: LayoutBuilder(
            builder: (_, constraints) {
              // Si el panel es estrecho (<200px) solo mostramos iconos
              final narrow = constraints.maxWidth < 200;
              final btnPadding = narrow
                  ? const EdgeInsets.symmetric(horizontal: 0, vertical: 14)
                  : const EdgeInsets.symmetric(horizontal: 8, vertical: 14);

              return Row(
                children: [
                  Expanded(
                    child: narrow
                        ? OutlinedButton(
                            style: OutlinedButton.styleFrom(padding: btnPadding),
                            onPressed: () =>
                                setState(() => _showingPicker = !_showingPicker),
                            child: Icon(_showingPicker
                                ? Icons.keyboard_arrow_down
                                : Icons.add),
                          )
                        : OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(padding: btnPadding),
                            icon: Icon(_showingPicker
                                ? Icons.keyboard_arrow_down
                                : Icons.add),
                            label: Text(_showingPicker ? 'Cerrar' : 'Añadir'),
                            onPressed: () =>
                                setState(() => _showingPicker = !_showingPicker),
                          ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: narrow
                        ? OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: btnPadding,
                              foregroundColor: theme.colorScheme.error,
                              side: BorderSide(color: theme.colorScheme.error),
                            ),
                            onPressed: _cancel,
                            child: const Icon(Icons.delete_outline),
                          )
                        : OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: btnPadding,
                              foregroundColor: theme.colorScheme.error,
                              side: BorderSide(color: theme.colorScheme.error),
                            ),
                            icon: const Icon(Icons.delete_outline),
                            label: const Text('Cancelar'),
                            onPressed: _cancel,
                          ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: narrow
                        ? ElevatedButton(
                            style: ElevatedButton.styleFrom(padding: btnPadding),
                            onPressed: _showPayDialog,
                            child: const Icon(Icons.payment),
                          )
                        : ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(padding: btnPadding),
                            icon: const Icon(Icons.payment),
                            label: const Text('Cobrar'),
                            onPressed: _showPayDialog,
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── Fila de línea ─────────────────────────────────────────────────────────────

class _LineTile extends StatelessWidget {
  final TicketLine   line;
  final NumberFormat fmt;
  final VoidCallback onRemove;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;

  const _LineTile({
    required this.line,
    required this.fmt,
    required this.onRemove,
    required this.onIncrease,
    required this.onDecrease,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      dense: true,
      title: Text(line.productName, style: theme.textTheme.bodyMedium),
      subtitle: Text(
        fmt.format(line.priceAtMoment),
        style: theme.textTheme.bodySmall,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Controles de cantidad ──────────────────────────────────
          IconButton(
            icon:    const Icon(Icons.remove_circle_outline, size: 20),
            color:   theme.colorScheme.error,
            tooltip: 'Reducir',
            onPressed: onDecrease,
          ),
          Text(
            '${line.quantity}',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            icon:    const Icon(Icons.add_circle_outline, size: 20),
            color:   theme.colorScheme.primary,
            tooltip: 'Añadir',
            onPressed: onIncrease,
          ),
          // ── Total línea ───────────────────────────────────────────
          SizedBox(
            width: 56,
            child: Text(
              fmt.format(line.totalLine),
              textAlign: TextAlign.right,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

