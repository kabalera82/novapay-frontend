// lib/presentation/widgets/caja/report_row.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../config/theme.dart';
import '../../../data/models/daily_report.dart';

class ReportRow extends StatelessWidget {
  final DailyReport  report;
  final NumberFormat fmt;
  final DateFormat   dateFmt;

  const ReportRow({
    super.key,
    required this.report,
    required this.fmt,
    required this.dateFmt,
  });

  @override
  Widget build(BuildContext context) {
    final theme     = Theme.of(context);
    final beneficio = report.grandTotal;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.receipt_long_outlined,
                size: 20, color: AppTheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    report.closedAt != null 
                      ? '${dateFmt.format(report.date)} - ${DateFormat('HH:mm').format(report.closedAt!)}'
                      : dateFmt.format(report.date),
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '${report.ticketCount} tickets  ·  '
                    'Ef: ${fmt.format(report.totalCash)}  '
                    'Tj: ${fmt.format(report.totalCard)}  '
                    'Gastos: ${fmt.format(report.totalExpenses)}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Text(
              fmt.format(beneficio),
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: beneficio >= 0 ? AppTheme.success : AppTheme.error,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
