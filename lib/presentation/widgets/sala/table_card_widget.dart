// lib/presentation/widgets/sala/table_card_widget.dart
import 'package:flutter/material.dart';

import '../../../config/app_formats.dart';
import '../../../data/models/ticket.dart';

class TableCardWidget extends StatelessWidget {
  final int      tableNumber;
  final Ticket?  ticket;      // null = libre
  final bool     isSelected;
  final VoidCallback onTap;

  const TableCardWidget({
    super.key,
    required this.tableNumber,
    required this.onTap,
    this.ticket,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme      = Theme.of(context);
    final isOccupied = ticket != null;
    final isParked   = ticket?.isParked ?? false;

    final bgColor = isSelected
        ? theme.colorScheme.primaryContainer
        : isParked
            ? const Color(0xFFFEF3C7)   // ámbar claro — aparcada
            : isOccupied
                ? theme.colorScheme.primary
                : theme.colorScheme.surfaceContainerHighest;

    final fgColor = isSelected
        ? theme.colorScheme.onPrimaryContainer
        : isParked
            ? const Color(0xFF92400E)   // ámbar oscuro — texto sobre fondo ámbar
            : isOccupied
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurfaceVariant;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: theme.colorScheme.primary, width: 2.5)
              : null,
        ),
        padding: const EdgeInsets.all(6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.table_restaurant, size: 24, color: fgColor),
            const SizedBox(height: 2),
            Text(
              'Mesa $tableNumber',
              style: theme.textTheme.labelSmall?.copyWith(
                color: fgColor,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            if (isOccupied) ...[
              Text(
                AppFormats.currency.format(ticket!.totalAmount),
                style: TextStyle(
                  fontSize: 10,
                  color: fgColor,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              if (isParked)
                Text(
                  'Aparcada',
                  style: TextStyle(
                    fontSize: 9,
                    color: fgColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ] else
              Text(
                'Libre',
                style: TextStyle(fontSize: 10, color: fgColor),
              ),
          ],
        ),
      ),
    );
  }
}
