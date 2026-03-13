// lib/presentation/pages/admin/sections/sala.section.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../data/models/ticket.dart';
import '../../../controllers/ticket.controller.dart';
import '../../../widgets/sala/table.card.widget.dart';
import '../../../widgets/sala/ticket.panel.widget.dart';

class SalaSection extends StatefulWidget {
  const SalaSection({super.key});

  @override
  State<SalaSection> createState() => _SalaSectionState();
}

class _SalaSectionState extends State<SalaSection> {
  final _ticketCtrl = Get.find<TicketController>();

  int  _tableCount    = 12;
  int? _selectedTable;

  // ── Helpers ───────────────────────────────────────────────────────────────

  Ticket? _ticketForTable(int tableNum, List<Ticket> tickets) =>
      tickets.firstWhereOrNull((t) => t.tableNumber == tableNum);

  Future<void> _onTableTap(int tableNum, Ticket? existing) async {
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
        builder: (_, _) => TicketPanelWidget(
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
              final isWide = constraints.maxWidth >= 600;
              return isWide ? _buildWideLayout() : _buildNarrowLayout();
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
          const Spacer(),
          IconButton(
            icon:      const Icon(Icons.remove_circle_outline),
            tooltip:   'Quitar mesa',
            onPressed: _tableCount > 1
                ? () => setState(() => _tableCount--)
                : null,
          ),
          Text('$_tableCount', style: theme.textTheme.bodyLarge),
          IconButton(
            icon:      const Icon(Icons.add_circle_outline),
            tooltip:   'Añadir mesa',
            onPressed: () => setState(() => _tableCount++),
          ),
        ],
      ),
    );
  }

  // ── Layout wide: grid izquierda + panel derecha ───────────────────────────

  Widget _buildWideLayout() {
    return Obx(() {
      final tickets = _ticketCtrl.openTickets.toList();
      return Row(
        children: [
          Expanded(
            flex: 3,
            child: _buildGrid(tickets),
          ),
          if (_selectedTable != null) ...[
            const VerticalDivider(width: 1, thickness: 1),
            Expanded(
              flex: 2,
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
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 120,
        mainAxisSpacing:    10,
        crossAxisSpacing:   10,
      ),
      itemCount: _tableCount,
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
    );
  }
}
