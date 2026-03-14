// lib/presentation/pages/admin/sections/sala_section.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../data/models/ticket.dart';
import '../../../controllers/admin_shell_controller.dart';
import '../../../controllers/ticket_controller.dart';
import '../../../widgets/sala/table_card_widget.dart';
import '../../../widgets/sala/ticket_panel_widget.dart';

class SalaSection extends StatefulWidget {
  const SalaSection({super.key});

  @override
  State<SalaSection> createState() => _SalaSectionState();
}

class _SalaSectionState extends State<SalaSection> {
  final _ticketCtrl = Get.find<TicketController>();
  final _shellCtrl  = Get.find<AdminShellController>();

  int? _selectedTable;

  // ── Helpers ───────────────────────────────────────────────────────────────

  Ticket? _ticketForTable(int tableNum, List<Ticket> tickets) =>
      tickets.firstWhereOrNull((t) => t.tableNumber == tableNum);

  Future<void> _onTableTap(int tableNum, Ticket? existing) async {
    // Toca la misma mesa enfocada → deseleccionar
    if (_selectedTable == tableNum) {
      _clearSelection();
      return;
    }

    // Cualquier otra mesa: crear ticket si está libre, o cambiar foco si está ocupada.
    // Múltiples mesas pueden tener tickets activos; el panel muestra la que está enfocada.
    await _ticketCtrl.selectOrCreateTicket(tableNumber: tableNum);
    if (!mounted) return;

    final isNarrow = MediaQuery.of(context).size.width < 600;

    if (!isNarrow) {
      setState(() => _selectedTable = tableNum);
      return;
    }

    // Móvil → bottom sheet
    setState(() => _selectedTable = tableNum);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetCtx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        minChildSize:     0.4,
        maxChildSize:     0.95,
        builder: (_, scrollCtrl) => TicketPanelWidget(
          tableNumber: tableNum,
          onClose:     () => Navigator.pop(sheetCtx),
        ),
      ),
    );

    if (mounted) _clearSelection();
  }

  void _clearSelection() {
    _ticketCtrl.clearActive();
    setState(() => _selectedTable = null);
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildToolbar(),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              if (w < 600) return _buildNarrowLayout();
              final panelFraction = w >= 900 ? 0.40 : 0.50;
              return _buildWideLayout(constraints.maxWidth * panelFraction);
            },
          ),
        ),
      ],
    );
  }

  // ── Toolbar ───────────────────────────────────────────────────────────────

  Widget _buildToolbar() {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text('Sala', style: theme.textTheme.headlineSmall),
        ],
      ),
    );
  }

  // ── Layout wide: grid izquierda + panel derecha ───────────────────────────

  Widget _buildWideLayout(double panelWidth) {
    return Obx(() {
      final tickets = _ticketCtrl.openTickets.toList();
      return Row(
        children: [
          Expanded(
            child: _buildGrid(tickets),
          ),
          if (_selectedTable != null) ...[
            const VerticalDivider(width: 1, thickness: 1),
            SizedBox(
              width: panelWidth,
              child: TicketPanelWidget(
                tableNumber: _selectedTable!,
                onClose:     _clearSelection,
              ),
            ),
          ],
        ],
      );
    });
  }

  // ── Layout narrow: solo grid ──────────────────────────────────────────────

  Widget _buildNarrowLayout() {
    return Obx(() => _buildGrid(_ticketCtrl.openTickets.toList()));
  }

  // ── Grid de mesas ─────────────────────────────────────────────────────────

  Widget _buildGrid(List<Ticket> tickets) {
    return Stack(
      children: [
        GridView.builder(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 64),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 120,
            mainAxisSpacing:    10,
            crossAxisSpacing:   10,
          ),
          itemCount: _shellCtrl.tableCount.value,
          itemBuilder: (_, i) {
            final tableNum = i + 1;
            final ticket   = _ticketForTable(tableNum, tickets);
            return TableCardWidget(
              tableNumber: tableNum,
              ticket:      ticket,
              isSelected:  _selectedTable == tableNum,
              onTap:       () => _onTableTap(tableNum, ticket),
            );
          },
        ),
        Positioned(
          bottom: 12,
          left:   12,
          child: Obx(() => _buildTableCounter()),
        ),
      ],
    );
  }

  Widget _buildTableCounter() {
    final theme = Theme.of(context);
    return Material(
      color:        theme.colorScheme.surface,
      elevation:    3,
      shadowColor:  Colors.black26,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              iconSize:  20,
              icon:      const Icon(Icons.remove),
              tooltip:   'Quitar mesa',
              onPressed: _shellCtrl.tableCount.value > 1
                  ? () => _shellCtrl.tableCount.value--
                  : null,
            ),
            Text(
              '${_shellCtrl.tableCount.value}',
              style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            IconButton(
              iconSize:  20,
              icon:      const Icon(Icons.add),
              tooltip:   'Añadir mesa',
              onPressed: () => _shellCtrl.tableCount.value++,
            ),
          ],
        ),
      ),
    );
  }
}
