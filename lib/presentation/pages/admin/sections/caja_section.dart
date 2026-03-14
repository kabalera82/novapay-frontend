// lib/presentation/pages/admin/sections/caja_section.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../config/app_formats.dart';
import '../../../../config/theme.dart';
import '../../../controllers/expense_controller.dart';
import '../../../controllers/product_controller.dart';
import '../../../controllers/report_controller.dart';
import '../../../widgets/caja/expense_category_breakdown.dart';
import '../../../widgets/caja/expense_form_sheet.dart';
import '../../../widgets/caja/expense_row.dart';
import '../../../widgets/caja/report_row.dart';
import '../../../widgets/caja/summary_card.dart';
import '../../../widgets/caja/top_products_card.dart';
import '../../../widgets/common/section_header.dart';

class CajaSection extends StatefulWidget {
  const CajaSection({super.key});

  @override
  State<CajaSection> createState() => _CajaSectionState();
}

class _CajaSectionState extends State<CajaSection> {
  final _reportCtrl  = Get.find<ReportController>();
  final _expenseCtrl = Get.find<ExpenseController>();
  final _productCtrl = Get.find<ProductController>();
  final _fmt         = AppFormats.currency;
  final _dateFmt     = AppFormats.date;
  final _timeFmt     = AppFormats.time;

  void _showAddExpense() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => ExpenseFormSheet(
        products: _productCtrl.products.toList(),
        onSave: (expense) async {
          await _expenseCtrl.addExpense(expense);
          await _reportCtrl.refreshAfterExpense();
          await _productCtrl.loadAll();
        },
      ),
    );
  }

  Future<void> _closeDay() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cierre de jornada'),
        content: const Text(
          'Se generará el reporte del día con todos los tickets pagados. '
          '¿Continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cerrar jornada'),
          ),
        ],
      ),
    );
    if (ok == true) await _reportCtrl.closeDay();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title:     'Caja / Balance',
          onRefresh: () async {
            await _reportCtrl.loadAll();
            await _reportCtrl.loadToday();
            await _expenseCtrl.loadToday();
          },
        ),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hoy — ${_dateFmt.format(DateTime.now())}',
                  style: theme.textTheme.labelLarge
                      ?.copyWith(color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 10),

                Obx(() {
                  final ingresos  = _reportCtrl.todayTotal;
                  final gastos    = _expenseCtrl.todayTotal;
                  final beneficio = ingresos - gastos;

                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: SummaryCard(label: 'Ingresos',  value: _fmt.format(ingresos),  color: AppTheme.success,       icon: Icons.trending_up)),
                          const SizedBox(width: 10),
                          Expanded(child: SummaryCard(label: 'Gastos',    value: _fmt.format(gastos),    color: AppTheme.error,         icon: Icons.trending_down)),
                          const SizedBox(width: 10),
                          Expanded(child: SummaryCard(label: 'Beneficio', value: _fmt.format(beneficio), color: beneficio >= 0 ? AppTheme.primary : AppTheme.error, icon: Icons.account_balance_wallet_outlined)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(child: SummaryCard(label: 'Efectivo', value: _fmt.format(_reportCtrl.todayCash), color: AppTheme.warning,       icon: Icons.payments_outlined)),
                          const SizedBox(width: 10),
                          Expanded(child: SummaryCard(label: 'Tarjeta',  value: _fmt.format(_reportCtrl.todayCard), color: AppTheme.info,          icon: Icons.credit_card_outlined)),
                          const SizedBox(width: 10),
                          Expanded(child: SummaryCard(label: 'Tickets',  value: '${_reportCtrl.todayCount}',        color: AppTheme.textSecondary, icon: Icons.receipt_outlined)),
                        ],
                      ),
                    ],
                  );
                }),

                const SizedBox(height: 12),

                Obx(() {
                  if (_expenseCtrl.todayExpenses.isEmpty) return const SizedBox.shrink();
                  return ExpenseCategoryBreakdown(
                    expenseCtrl: _expenseCtrl,
                    fmt: _fmt,
                  );
                }),

                const SizedBox(height: 12),

                Obx(() {
                  final sold = _reportCtrl.todaySoldProducts;
                  if (sold.isEmpty) return const SizedBox.shrink();
                  return TopProductsCard(products: sold);
                }),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon:  const Icon(Icons.add),
                        label: const Text('Añadir gasto'),
                        onPressed: _showAddExpense,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Obx(() => ElevatedButton.icon(
                        icon: _reportCtrl.isClosing.value
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.lock_clock),
                        label: const Text('Cerrar jornada'),
                        onPressed: _reportCtrl.isClosing.value ? null : _closeDay,
                      )),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Obx(() {
                  final list = _expenseCtrl.todayExpenses.toList();
                  if (list.isEmpty) return const SizedBox.shrink();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Gastos de hoy', style: theme.textTheme.labelLarge),
                      const SizedBox(height: 6),
                      ...list.map((e) => ExpenseRow(
                            expense: e,
                            fmt:     _fmt,
                            timeFmt: _timeFmt,
                            onDelete: () async {
                              await _expenseCtrl.removeExpense(e.id);
                              await _productCtrl.loadAll();
                            },
                          )),
                    ],
                  );
                }),

                const Divider(height: 24),

                Text('Historial de cierres', style: theme.textTheme.labelLarge),
                const SizedBox(height: 6),
                Obx(() {
                  final list = _reportCtrl.reports.toList();
                  if (list.isEmpty) {
                    return Text(
                      'Sin cierres registrados',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: AppTheme.textSecondary),
                    );
                  }
                  return Column(
                    children: list
                        .map((r) => ReportRow(report: r, fmt: _fmt, dateFmt: _dateFmt))
                        .toList(),
                  );
                }),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
