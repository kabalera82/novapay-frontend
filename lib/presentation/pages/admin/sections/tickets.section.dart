// lib/presentation/pages/admin/sections/tickets.section.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../config/theme.dart';
import '../../../../data/models/ticket.dart';
import '../../../controllers/ticket.controller.dart';

class TicketsSection extends StatefulWidget {
  const TicketsSection({super.key});

  @override
  State<TicketsSection> createState() => _TicketsSectionState();
}

class _TicketsSectionState extends State<TicketsSection> {
  final _ctrl = Get.find<TicketController>();
  final _fmt  = NumberFormat.currency(locale: 'es_ES', symbol: '€');
  final _dateFmt = DateFormat('dd/MM/yyyy HH:mm');

  // Filtros
  TicketStatus? _statusFilter;   // null = todos
  DateTime?     _dateFilter;     // null = todos los días

  @override
  void initState() {
    super.initState();
    _ctrl.loadAllTickets();
  }

  // ── Filtrado ──────────────────────────────────────────────────────────────

  List<Ticket> _filtered(List<Ticket> all) {
    return all.where((t) {
      if (_statusFilter != null && t.status != _statusFilter) return false;
      if (_dateFilter != null) {
        final d = _dateFilter!;
        final start = DateTime(d.year, d.month, d.day);
        final end   = start.add(const Duration(days: 1));
        if (t.createdAt.isBefore(start) || t.createdAt.isAfter(end)) return false;
      }
      return true;
    }).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _TicketDetailSheet(
        ticket:   ticket,
        fmt:      _fmt,
        dateFmt:  _dateFmt,
        onReopen: () async {
          Navigator.pop(context);
          await _ctrl.reopenTicketById(ticket);
          await _ctrl.loadAllTickets();
          setState(() {});
        },
        onDelete: () async {
          final ok = await _confirmDelete(ticket);
          if (!ok) return;
          if (!mounted) return;
          Navigator.pop(context);
          await _ctrl.deleteTicketById(ticket.id);
          await _ctrl.loadAllTickets();
          if (mounted) setState(() {});
        },
        onChangeMethod: (method) async {
          Navigator.pop(context);
          await _ctrl.changePaymentMethod(ticket, method);
          await _ctrl.loadAllTickets();
          setState(() {});
        },
      ),
    );
  }

  Future<bool> _confirmDelete(Ticket ticket) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Eliminar ticket'),
            content: Text(
              '¿Seguro que quieres eliminar el ticket #${ticket.id}? '
              'Esta acción no se puede deshacer.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.error,
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Eliminar'),
              ),
            ],
          ),
        ) ??
        false;
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Cabecera ────────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(
            children: [
              Text('Tickets', style: theme.textTheme.headlineMedium),
              const Spacer(),
              IconButton(
                icon:    const Icon(Icons.refresh),
                tooltip: 'Recargar',
                onPressed: () async {
                  await _ctrl.loadAllTickets();
                  setState(() {});
                },
              ),
            ],
          ),
        ),

        // ── Filtros ─────────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              // Estado
              _FilterChip(
                label: 'Todos',
                selected: _statusFilter == null,
                onTap: () => setState(() => _statusFilter = null),
              ),
              _FilterChip(
                label: 'Abiertos',
                color: AppTheme.info,
                selected: _statusFilter == TicketStatus.abierto,
                onTap: () => setState(
                  () => _statusFilter = _statusFilter == TicketStatus.abierto
                      ? null
                      : TicketStatus.abierto,
                ),
              ),
              _FilterChip(
                label: 'Pagados',
                color: AppTheme.success,
                selected: _statusFilter == TicketStatus.pagado,
                onTap: () => setState(
                  () => _statusFilter = _statusFilter == TicketStatus.pagado
                      ? null
                      : TicketStatus.pagado,
                ),
              ),
              _FilterChip(
                label: 'Cancelados',
                color: AppTheme.error,
                selected: _statusFilter == TicketStatus.cancelado,
                onTap: () => setState(
                  () => _statusFilter = _statusFilter == TicketStatus.cancelado
                      ? null
                      : TicketStatus.cancelado,
                ),
              ),
              // Fecha
              ActionChip(
                avatar: Icon(
                  _dateFilter != null ? Icons.event : Icons.calendar_today,
                  size: 16,
                  color: _dateFilter != null
                      ? AppTheme.primary
                      : AppTheme.textSecondary,
                ),
                label: Text(
                  _dateFilter != null
                      ? DateFormat('dd/MM/yyyy').format(_dateFilter!)
                      : 'Fecha',
                  style: TextStyle(
                    color: _dateFilter != null
                        ? AppTheme.primary
                        : AppTheme.textSecondary,
                    fontWeight: _dateFilter != null
                        ? FontWeight.w600
                        : FontWeight.normal,
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
                    Icon(Icons.receipt_long_outlined,
                        size: 48, color: AppTheme.textSecondary),
                    const SizedBox(height: 12),
                    Text(
                      'No hay tickets con estos filtros',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: list.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (_, i) => _TicketRow(
                ticket: list[i],
                fmt:    _fmt,
                dateFmt: _dateFmt,
                onTap: () => _showDetail(list[i]),
              ),
            );
          }),
        ),
      ],
    );
  }
}

// ── Fila de ticket ─────────────────────────────────────────────────────────────

class _TicketRow extends StatelessWidget {
  final Ticket      ticket;
  final NumberFormat fmt;
  final DateFormat   dateFmt;
  final VoidCallback onTap;

  const _TicketRow({
    required this.ticket,
    required this.fmt,
    required this.dateFmt,
    required this.onTap,
  });

  Color _statusColor() {
    return switch (ticket.status) {
      TicketStatus.abierto   => AppTheme.info,
      TicketStatus.pagado    => AppTheme.success,
      TicketStatus.cancelado => AppTheme.error,
    };
  }

  String _statusLabel() {
    return switch (ticket.status) {
      TicketStatus.abierto   => 'Abierto',
      TicketStatus.pagado    => 'Pagado',
      TicketStatus.cancelado => 'Cancelado',
    };
  }

  String _methodLabel() {
    return switch (ticket.paymentMethod) {
      PaymentMethod.efectivo => 'Efectivo',
      PaymentMethod.tarjeta  => 'Tarjeta',
      PaymentMethod.mixto    => 'Mixto',
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _statusColor();

    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 4,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      title: Row(
        children: [
          Text(
            ticket.tableOrLabel ?? 'Mesa ${ticket.tableNumber ?? '-'}',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _statusLabel(),
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      subtitle: Text(
        '${dateFmt.format(ticket.createdAt)}  ·  '
        '${ticket.lines.length} líneas  ·  ${_methodLabel()}',
        style: theme.textTheme.bodySmall,
      ),
      trailing: Text(
        fmt.format(ticket.totalAmount),
        style: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// ── Detalle del ticket (bottom sheet) ─────────────────────────────────────────

class _TicketDetailSheet extends StatelessWidget {
  final Ticket      ticket;
  final NumberFormat fmt;
  final DateFormat   dateFmt;
  final VoidCallback onReopen;
  final VoidCallback onDelete;
  final void Function(PaymentMethod) onChangeMethod;

  const _TicketDetailSheet({
    required this.ticket,
    required this.fmt,
    required this.dateFmt,
    required this.onReopen,
    required this.onDelete,
    required this.onChangeMethod,
  });

  String _statusLabel() => switch (ticket.status) {
        TicketStatus.abierto   => 'Abierto',
        TicketStatus.pagado    => 'Pagado',
        TicketStatus.cancelado => 'Cancelado',
      };

  Color _statusColor() => switch (ticket.status) {
        TicketStatus.abierto   => AppTheme.info,
        TicketStatus.pagado    => AppTheme.success,
        TicketStatus.cancelado => AppTheme.error,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _statusColor();

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize:     0.4,
      maxChildSize:     0.92,
      expand: false,
      builder: (_, scrollCtrl) => Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 4),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.border,
              borderRadius: BorderRadius.circular(2),
            ),
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
                    Text(
                      dateFmt.format(ticket.createdAt),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _statusLabel(),
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
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
                    child: Text(
                      'Sin líneas',
                      style: theme.textTheme.bodySmall,
                    ),
                  )
                else
                  ...ticket.lines.map(
                    (l) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Text(
                            '${l.quantity}×',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              l.productName,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                          Text(
                            fmt.format(l.totalLine),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
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
                        PaymentMethod.tarjeta  => 'Tarjeta',
                        PaymentMethod.mixto    => 'Mixto',
                      };
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              backgroundColor: selected
                                  ? AppTheme.primary.withValues(alpha: 0.1)
                                  : null,
                              foregroundColor: selected
                                  ? AppTheme.primary
                                  : AppTheme.textSecondary,
                              side: BorderSide(
                                color: selected
                                    ? AppTheme.primary
                                    : AppTheme.border,
                              ),
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
                    icon:  const Icon(Icons.lock_open_outlined),
                    label: const Text('Reabrir ticket'),
                    onPressed: onReopen,
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

// ── Chip de filtro ─────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String       label;
  final bool         selected;
  final VoidCallback onTap;
  final Color?       color;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppTheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? c.withValues(alpha: 0.12) : AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? c : AppTheme.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: selected ? c : AppTheme.textSecondary,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
