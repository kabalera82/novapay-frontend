// lib/presentation/pages/admin/sections/tickets_section.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../config/app_formats.dart';
import '../../../../config/theme.dart';
import '../../../../data/models/product.dart';
import '../../../../data/models/ticket.dart';
import '../../../../data/models/ticket_line.dart';
import '../../../controllers/ticket_controller.dart';
import '../../../controllers/ticket_history_controller.dart';
import '../../../widgets/common/confirm_delete_dialog.dart';
import '../../../widgets/common/filter_chip_button.dart';
import '../../../widgets/common/section_header.dart';
import '../../../widgets/common/ticket_status_badge.dart';
import '../../../widgets/sala/payment_dialog_widget.dart';
import '../../../widgets/sala/product_picker_widget.dart';

class TicketsSection extends StatefulWidget {
  const TicketsSection({super.key});

  @override
  State<TicketsSection> createState() => _TicketsSectionState();
}

class _TicketsSectionState extends State<TicketsSection> {
  final _ctrl = Get.find<TicketHistoryController>();
  final _fmt = AppFormats.currency;
  final _dateFmt = AppFormats.dateTime;

  // Filtros
  TicketStatus? _statusFilter; // null = todos
  DateTime? _dateFilter; // null = todos los días

  // ── Filtrado ──────────────────────────────────────────────────────────────

  List<Ticket> _filtered(List<Ticket> all) {
    return all.where((t) {
      if (_statusFilter != null && t.status != _statusFilter) return false;
      if (_dateFilter != null) {
        final d = _dateFilter!;
        final start = DateTime(d.year, d.month, d.day);
        final end = start.add(const Duration(days: 1));
        if (t.createdAt.isBefore(start) || t.createdAt.isAfter(end)) return false;
      }
      return true;
    }).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  // ── Seleccionar fecha ─────────────────────────────────────────────────────

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateFilter ?? DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _dateFilter = picked);
  }

  // ── Detalle del ticket ────────────────────────────────────────────────────

  void _showDetail(Ticket ticket) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _TicketDetailSheet(
        ticket: ticket,
        fmt: _fmt,
        dateFmt: _dateFmt,
        onCorrect: () {
          // Cierra el detalle y abre el panel de corrección
          Navigator.pop(context);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _showCorrection(ticket);
          });
        },
        onDelete: () async {
          final ok = await _confirmDelete(ticket);
          if (!ok) return;
          if (!mounted) return;
          Navigator.pop(context);
          await _ctrl.deleteById(ticket.id);
          await _ctrl.loadAll();
          if (mounted) setState(() {});
        },
        onChangeMethod: (method) async {
          Navigator.pop(context);
          await _ctrl.changePaymentMethod(ticket, method);
          await _ctrl.loadAll();
          setState(() {});
        },
        onReprint: () async {
          Navigator.pop(context);
          await Get.find<TicketController>().reprintTicket(ticket);
        },
      ),
    );
  }

  /// Abre el panel de corrección de cobro para un ticket cerrado.
  /// El ticket nunca vuelve a la sala: se edita y se vuelve a cerrar aquí mismo.
  Future<void> _showCorrection(Ticket ticket) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _TicketCorrectionSheet(initialTicket: ticket),
    );
    // Refresca el historial al cerrar el panel (completado o abandonado)
    if (!mounted) return;
    await _ctrl.loadAll();
    setState(() {});
  }

  Future<bool> _confirmDelete(Ticket ticket) async {
    return ConfirmDeleteDialog.show(
      context,
      title: 'Eliminar ticket',
      message:
          '¿Seguro que quieres eliminar el ticket #${ticket.id}? '
          'Esta acción no se puede deshacer.',
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Cabecera ────────────────────────────────────────────────────────
        SectionHeader(
          title: 'Tickets',
          onRefresh: () async {
            await _ctrl.loadAll();
            setState(() {});
          },
        ),

        // ── Filtros ─────────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              // Estado
              FilterChipButton(
                label: 'Todos',
                selected: _statusFilter == null,
                onTap: () => setState(() => _statusFilter = null),
              ),
              FilterChipButton(
                label: 'Abiertos',
                color: AppTheme.info,
                selected: _statusFilter == TicketStatus.abierto,
                onTap: () =>
                    setState(() => _statusFilter = _statusFilter == TicketStatus.abierto ? null : TicketStatus.abierto),
              ),
              FilterChipButton(
                label: 'Pagados',
                color: AppTheme.success,
                selected: _statusFilter == TicketStatus.pagado,
                onTap: () =>
                    setState(() => _statusFilter = _statusFilter == TicketStatus.pagado ? null : TicketStatus.pagado),
              ),
              FilterChipButton(
                label: 'Cancelados',
                color: AppTheme.error,
                selected: _statusFilter == TicketStatus.cancelado,
                onTap: () => setState(
                  () => _statusFilter = _statusFilter == TicketStatus.cancelado ? null : TicketStatus.cancelado,
                ),
              ),
              // Fecha
              ActionChip(
                avatar: Icon(
                  _dateFilter != null ? Icons.event : Icons.calendar_today,
                  size: 16,
                  color: _dateFilter != null ? AppTheme.primary : AppTheme.textSecondary,
                ),
                label: Text(
                  _dateFilter != null ? AppFormats.date.format(_dateFilter!) : 'Fecha',
                  style: TextStyle(
                    color: _dateFilter != null ? AppTheme.primary : AppTheme.textSecondary,
                    fontWeight: _dateFilter != null ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                onPressed: _pickDate,
              ),
              if (_dateFilter != null)
                ActionChip(
                  avatar: const Icon(Icons.close, size: 16),
                  label: const Text('Limpiar fecha'),
                  onPressed: () => setState(() => _dateFilter = null),
                ),
            ],
          ),
        ),

        const Divider(height: 1),

        // ── Lista ────────────────────────────────────────────────────────────
        Expanded(
          child: Obx(() {
            final list = _filtered(_ctrl.allTickets.toList());

            if (list.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.receipt_long_outlined, size: 48, color: AppTheme.textSecondary),
                    const SizedBox(height: 12),
                    Text(
                      'No hay tickets con estos filtros',
                      style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: list.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (_, i) =>
                  _TicketRow(ticket: list[i], fmt: _fmt, dateFmt: _dateFmt, onTap: () => _showDetail(list[i])),
            );
          }),
        ),
      ],
    );
  }
}

// ── Fila de ticket ─────────────────────────────────────────────────────────────

class _TicketRow extends StatelessWidget {
  final Ticket ticket;
  final NumberFormat fmt;
  final DateFormat dateFmt;
  final VoidCallback onTap;

  const _TicketRow({required this.ticket, required this.fmt, required this.dateFmt, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = ticketStatusColor(ticket.status);

    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 4,
        height: 40,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
      ),
      title: Row(
        children: [
          Text(
            ticket.tableOrLabel ?? 'Mesa ${ticket.tableNumber ?? '-'}',
            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 8),
          TicketStatusBadge(ticket.status),
        ],
      ),
      subtitle: Text(
        '${dateFmt.format(ticket.createdAt)}  ·  '
        '${ticket.lines.length} líneas  ·  ${paymentMethodLabel(ticket.paymentMethod)}',
        style: theme.textTheme.bodySmall,
      ),
      trailing: Text(
        fmt.format(ticket.totalAmount),
        style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }
}

// ── Detalle del ticket (bottom sheet) ─────────────────────────────────────────

class _TicketDetailSheet extends StatelessWidget {
  final Ticket ticket;
  final NumberFormat fmt;
  final DateFormat dateFmt;
  final VoidCallback onCorrect;
  final VoidCallback onDelete;
  final VoidCallback onReprint;
  final void Function(PaymentMethod) onChangeMethod;

  const _TicketDetailSheet({
    required this.ticket,
    required this.fmt,
    required this.dateFmt,
    required this.onCorrect,
    required this.onDelete,
    required this.onReprint,
    required this.onChangeMethod,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (_, scrollCtrl) => Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 4),
            width: 40,
            height: 4,
            decoration: BoxDecoration(color: AppTheme.border, borderRadius: BorderRadius.circular(2)),
          ),

          // Cabecera
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ticket.tableOrLabel ?? 'Mesa ${ticket.tableNumber ?? '-'}',
                      style: theme.textTheme.headlineSmall,
                    ),
                    Text(dateFmt.format(ticket.createdAt), style: theme.textTheme.bodySmall),
                  ],
                ),
                const Spacer(),
                TicketStatusBadge(
                  ticket.status,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  fontSize: 13,
                  borderRadius: 12,
                  fontWeight: FontWeight.bold,
                ),
              ],
            ),
          ),

          const Divider(),

          // Líneas
          Expanded(
            child: ListView(
              controller: scrollCtrl,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                // ── Líneas del ticket ──────────────────────────────────────
                Text('Líneas', style: theme.textTheme.labelLarge),
                const SizedBox(height: 4),
                if (ticket.lines.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text('Sin líneas', style: theme.textTheme.bodySmall),
                  )
                else
                  ...ticket.lines.map(
                    (l) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Text(
                            '${l.quantity}×',
                            style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Text(l.productName, style: theme.textTheme.bodyMedium)),
                          Text(
                            fmt.format(l.totalLine),
                            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),

                const Divider(),

                // ── Total ──────────────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total', style: theme.textTheme.labelLarge),
                    Text(
                      fmt.format(ticket.totalAmount),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // ── Cambiar método de pago (solo en tickets pagados) ───────
                if (ticket.status == TicketStatus.pagado) ...[
                  Text('Método de pago', style: theme.textTheme.labelLarge),
                  const SizedBox(height: 8),
                  Row(
                    children: PaymentMethod.values.map((m) {
                      final selected = ticket.paymentMethod == m;
                      final label = switch (m) {
                        PaymentMethod.efectivo => 'Efectivo',
                        PaymentMethod.tarjeta => 'Tarjeta',
                        PaymentMethod.mixto => 'Mixto',
                      };
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              backgroundColor: selected ? AppTheme.primary.withValues(alpha: 0.1) : null,
                              foregroundColor: selected ? AppTheme.primary : AppTheme.textSecondary,
                              side: BorderSide(color: selected ? AppTheme.primary : AppTheme.border),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            onPressed: selected ? null : () => onChangeMethod(m),
                            child: Text(label, style: const TextStyle(fontSize: 12)),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                ],

                // ── Acciones ───────────────────────────────────────────────
                if (ticket.status != TicketStatus.abierto)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.edit_note),
                    label: const Text('Corregir cobro'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.warning, foregroundColor: Colors.white),
                    onPressed: onCorrect,
                  ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  icon: const Icon(Icons.print),
                  label: const Text('Reimprimir ticket'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primary,
                    side: const BorderSide(color: AppTheme.primary),
                  ),
                  onPressed: onReprint,
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Eliminar ticket'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.error,
                    side: const BorderSide(color: AppTheme.error),
                  ),
                  onPressed: onDelete,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Panel de corrección de cobro ───────────────────────────────────────────────
//
// Permite editar las líneas de un ticket ya cerrado (pagado/cancelado) y
// volver a cobrarlo con el importe correcto.
// El ticket NUNCA vuelve a la sala: permanece en el historial.

class _TicketCorrectionSheet extends StatefulWidget {
  final Ticket initialTicket;

  const _TicketCorrectionSheet({required this.initialTicket});

  @override
  State<_TicketCorrectionSheet> createState() => _TicketCorrectionSheetState();
}

class _TicketCorrectionSheetState extends State<_TicketCorrectionSheet> {
  final _ctrl = Get.find<TicketHistoryController>();
  final _fmt = AppFormats.currency;
  bool _showingPicker = false;

  @override
  void initState() {
    super.initState();
    _ctrl.startEditing(widget.initialTicket);
  }

  @override
  void dispose() {
    _ctrl.stopEditing();
    super.dispose();
  }

  Future<void> _recharge() async {
    final ticket = _ctrl.editingTicket.value;
    if (ticket == null || ticket.lines.isEmpty) {
      Get.snackbar('Sin líneas', 'Añade al menos un producto antes de cobrar');
      return;
    }
    await PaymentDialogWidget.show(
      context,
      lines: ticket.lines,
      onConfirm: (lineIndices, method, cashGiven, change) async {
        await _ctrl.rechargeEditing(lineIndices, method);
        if (mounted) Navigator.of(context).pop();
      },
    );
  }

  Future<void> _cancelTicket() async {
    final ok = await ConfirmDeleteDialog.show(
      context,
      title: 'Cancelar ticket',
      message:
          '¿Marcar este ticket como cancelado? '
          'Esta acción actualiza el registro pero no vuelve a sala.',
    );
    if (!ok || !mounted) return;
    await _ctrl.cancelEditing();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollCtrl) => Column(
        children: [
          // ── Handle ──────────────────────────────────────────────────────
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 4),
            width: 40,
            height: 4,
            decoration: BoxDecoration(color: AppTheme.border, borderRadius: BorderRadius.circular(2)),
          ),

          // ── Cabecera ─────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.initialTicket.tableOrLabel ?? 'Mesa ${widget.initialTicket.tableNumber ?? '-'}',
                      style: theme.textTheme.headlineSmall,
                    ),
                    Text(
                      'Corrección de cobro',
                      style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.warning, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const Spacer(),
                // Total reactivo
                Obx(() {
                  final total = _ctrl.editingTicket.value?.totalAmount ?? 0;
                  return Text(
                    _fmt.format(total),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                }),
              ],
            ),
          ),

          const Divider(),

          // ── Líneas reactivas ─────────────────────────────────────────────
          Expanded(
            child: Obx(() {
              final lines = _ctrl.editingTicket.value?.lines ?? [];

              return ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                children: [
                  if (lines.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: Text(
                          'Sin líneas. Añade productos con el botón inferior.',
                          style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  else
                    ...lines.map(
                      (line) => _CorrectionLineTile(
                        line: line,
                        fmt: _fmt,
                        onIncrease: () => _ctrl.changeLineQtyInEditing(line.productName, 1),
                        onDecrease: () => _ctrl.changeLineQtyInEditing(line.productName, -1),
                        onDelete: () => _ctrl.removeLineFromEditing(line.productName),
                      ),
                    ),

                  // ── Picker de productos (toggle) ─────────────────────────
                  if (_showingPicker) ...[
                    const Divider(height: 24),
                    SizedBox(
                      height: 280,
                      child: ProductPickerWidget(
                        onProductSelected: (Product product) {
                          final line = TicketLine()
                            ..productName = product.name
                            ..productId = product.id
                            ..quantity = 1
                            ..priceAtMoment = product.price
                            ..totalLine = product.price;
                          _ctrl.addLineToEditing(line);
                        },
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),
                ],
              );
            }),
          ),

          // ── Barra de acciones ────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: const Border(top: BorderSide(color: AppTheme.border)),
            ),
            child: Row(
              children: [
                // Añadir / Cerrar picker
                Expanded(
                  child: OutlinedButton.icon(
                    icon: Icon(_showingPicker ? Icons.close : Icons.add),
                    label: Text(_showingPicker ? 'Cerrar' : 'Añadir'),
                    onPressed: () => setState(() => _showingPicker = !_showingPicker),
                  ),
                ),
                const SizedBox(width: 8),
                // Cancelar ticket
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.cancel_outlined),
                    label: const Text('Cancelar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.error,
                      side: const BorderSide(color: AppTheme.error),
                    ),
                    onPressed: _cancelTicket,
                  ),
                ),
                const SizedBox(width: 8),
                // Re-cobrar
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.payment),
                    label: const Text('Re-cobrar'),
                    onPressed: _recharge,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Fila de línea editable en corrección ──────────────────────────────────────

class _CorrectionLineTile extends StatelessWidget {
  final TicketLine line;
  final NumberFormat fmt;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;
  final VoidCallback onDelete;

  const _CorrectionLineTile({
    required this.line,
    required this.fmt,
    required this.onIncrease,
    required this.onDecrease,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          // Botón decrementar
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: onDecrease,
            iconSize: 20,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
          ),
          // Cantidad
          SizedBox(
            width: 28,
            child: Text(
              '${line.quantity}',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          // Botón incrementar
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: onIncrease,
            iconSize: 20,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
          ),
          const SizedBox(width: 8),
          // Nombre producto
          Expanded(child: Text(line.productName, style: theme.textTheme.bodyMedium)),
          // Importe línea
          Text(fmt.format(line.totalLine), style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(width: 4),
          // Eliminar línea
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: onDelete,
            iconSize: 18,
            color: AppTheme.error,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
          ),
        ],
      ),
    );
  }
}
