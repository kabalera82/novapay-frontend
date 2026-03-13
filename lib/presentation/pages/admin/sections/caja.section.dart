// lib/presentation/pages/admin/sections/caja.section.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../config/theme.dart';
import '../../../../data/models/daily.report.dart';
import '../../../../data/models/expense.dart';
import '../../../../data/models/product.dart';
import '../../../controllers/expense.controller.dart';
import '../../../controllers/product.controller.dart';
import '../../../controllers/report.controller.dart';

class CajaSection extends StatefulWidget {
  const CajaSection({super.key});

  @override
  State<CajaSection> createState() => _CajaSectionState();
}

class _CajaSectionState extends State<CajaSection> {
  final _reportCtrl  = Get.find<ReportController>();
  final _expenseCtrl = Get.find<ExpenseController>();
  final _productCtrl = Get.find<ProductController>();
  final _fmt         = NumberFormat.currency(locale: 'es_ES', symbol: '€');
  final _dateFmt     = DateFormat('dd/MM/yyyy');
  final _timeFmt     = DateFormat('HH:mm');

  @override
  void initState() {
    super.initState();
    _reportCtrl.loadAll();
    _reportCtrl.loadToday();
    _expenseCtrl.loadToday();
  }

  // ── Añadir gasto categorizado ─────────────────────────────────────────────

  void _showAddExpense() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ExpenseFormSheet(
        products: _productCtrl.products.toList(),
        onSave: (expense) async {
          await _expenseCtrl.addExpense(expense);
          // Sincronizar totalExpenses del reporte del día
          final total = _expenseCtrl.todayTotal;
          await _reportCtrl.addExpenseToday(
            total - (_reportCtrl.todayExpenses),
          );
          await _productCtrl.loadAll();
        },
      ),
    );
  }

  // ── Cierre de jornada ─────────────────────────────────────────────────────

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
        // ── Cabecera ────────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(
            children: [
              Text('Caja / Balance', style: theme.textTheme.headlineMedium),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () async {
                  await _reportCtrl.loadAll();
                  await _reportCtrl.loadToday();
                  await _expenseCtrl.loadToday();
                },
              ),
            ],
          ),
        ),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Panel de hoy ───────────────────────────────────────────
                Text(
                  'Hoy — ${_dateFmt.format(DateTime.now())}',
                  style: theme.textTheme.labelLarge
                      ?.copyWith(color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 10),

                // ── Tarjetas de ingresos ───────────────────────────────────
                Obx(() {
                  final ingresos  = _reportCtrl.todayTotal;
                  final gastos    = _expenseCtrl.todayTotal;
                  final beneficio = ingresos - gastos;

                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _SummaryCard(
                              label: 'Ingresos',
                              value: _fmt.format(ingresos),
                              color: AppTheme.success,
                              icon:  Icons.trending_up,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _SummaryCard(
                              label: 'Gastos',
                              value: _fmt.format(gastos),
                              color: AppTheme.error,
                              icon:  Icons.trending_down,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _SummaryCard(
                              label: 'Beneficio',
                              value: _fmt.format(beneficio),
                              color: beneficio >= 0
                                  ? AppTheme.primary
                                  : AppTheme.error,
                              icon: Icons.account_balance_wallet_outlined,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _SummaryCard(
                              label: 'Efectivo',
                              value: _fmt.format(_reportCtrl.todayCash),
                              color: AppTheme.warning,
                              icon:  Icons.payments_outlined,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _SummaryCard(
                              label: 'Tarjeta',
                              value: _fmt.format(_reportCtrl.todayCard),
                              color: AppTheme.info,
                              icon:  Icons.credit_card_outlined,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _SummaryCard(
                              label: 'Tickets',
                              value: '${_reportCtrl.todayCount}',
                              color: AppTheme.textSecondary,
                              icon:  Icons.receipt_outlined,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                }),

                const SizedBox(height: 12),

                // ── Desglose gastos por categoría ──────────────────────────
                Obx(() {
                  if (_expenseCtrl.todayExpenses.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return _ExpenseCategoryBreakdown(
                    expenseCtrl: _expenseCtrl,
                    fmt: _fmt,
                  );
                }),

                const SizedBox(height: 12),

                // ── Productos más vendidos ─────────────────────────────────
                Obx(() {
                  final sold = _reportCtrl.todaySoldProducts;
                  if (sold.isEmpty) return const SizedBox.shrink();
                  return _TopProductsCard(products: sold);
                }),

                const SizedBox(height: 12),

                // ── Acciones ──────────────────────────────────────────────
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
                            ? const SizedBox(
                                width: 16, height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.lock_clock),
                        label: const Text('Cerrar jornada'),
                        onPressed: _reportCtrl.isClosing.value
                            ? null
                            : _closeDay,
                      )),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // ── Gastos de hoy (lista) ──────────────────────────────────
                Obx(() {
                  final list = _expenseCtrl.todayExpenses.toList();
                  if (list.isEmpty) return const SizedBox.shrink();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Gastos de hoy', style: theme.textTheme.labelLarge),
                      const SizedBox(height: 6),
                      ...list.map((e) => _ExpenseRow(
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

                // ── Historial de cierres ───────────────────────────────────
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
                        .map((r) => _ReportRow(
                              report:  r,
                              fmt:     _fmt,
                              dateFmt: _dateFmt,
                            ))
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

// ── Desglose por categoría ─────────────────────────────────────────────────────

class _ExpenseCategoryBreakdown extends StatelessWidget {
  final ExpenseController expenseCtrl;
  final NumberFormat      fmt;
  const _ExpenseCategoryBreakdown({required this.expenseCtrl, required this.fmt});

  static const _colors = {
    ExpenseCategory.compras:  AppTheme.info,
    ExpenseCategory.facturas: AppTheme.warning,
    ExpenseCategory.personal: AppTheme.secondary,
    ExpenseCategory.otro:     AppTheme.textSecondary,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Gastos por categoría', style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          ...ExpenseCategory.values.map((cat) {
            final amount = expenseCtrl.totalByCategory(cat);
            if (amount == 0) return const SizedBox.shrink();
            final color = _colors[cat] ?? AppTheme.textSecondary;
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Container(
                    width: 10, height: 10,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(cat.label, style: theme.textTheme.bodySmall),
                  ),
                  Text(
                    fmt.format(amount),
                    style: theme.textTheme.labelMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ── Fila de gasto ─────────────────────────────────────────────────────────────

class _ExpenseRow extends StatelessWidget {
  final Expense      expense;
  final NumberFormat fmt;
  final DateFormat   timeFmt;
  final VoidCallback onDelete;

  const _ExpenseRow({
    required this.expense,
    required this.fmt,
    required this.timeFmt,
    required this.onDelete,
  });

  static const _catColors = {
    ExpenseCategory.compras:  AppTheme.info,
    ExpenseCategory.facturas: AppTheme.warning,
    ExpenseCategory.personal: AppTheme.secondary,
    ExpenseCategory.otro:     AppTheme.textSecondary,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _catColors[expense.category] ?? AppTheme.textSecondary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              expense.category.label,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expense.description.isNotEmpty
                      ? expense.description
                      : (expense.productName.isNotEmpty
                          ? expense.productName
                          : expense.category.label),
                  style: theme.textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
                if (expense.quantity > 0)
                  Text(
                    '${expense.quantity} uds',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: AppTheme.textSecondary),
                  ),
              ],
            ),
          ),
          Text(
            fmt.format(expense.amount),
            style: theme.textTheme.labelMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 4),
          Text(
            timeFmt.format(expense.date),
            style: theme.textTheme.bodySmall
                ?.copyWith(color: AppTheme.textSecondary),
          ),
          IconButton(
            icon:    const Icon(Icons.delete_outline, size: 18),
            color:   AppTheme.error,
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

// ── Formulario de gasto ───────────────────────────────────────────────────────

class _ExpenseFormSheet extends StatefulWidget {
  final List<Product>               products;
  final Future<void> Function(Expense) onSave;

  const _ExpenseFormSheet({required this.products, required this.onSave});

  @override
  State<_ExpenseFormSheet> createState() => _ExpenseFormSheetState();
}

class _ExpenseFormSheetState extends State<_ExpenseFormSheet> {
  ExpenseCategory _category     = ExpenseCategory.compras;
  final _descCtrl               = TextEditingController();
  final _amountCtrl             = TextEditingController();
  final _qtyCtrl                = TextEditingController(text: '1');
  Product?         _selectedProduct;
  bool             _saving       = false;

  @override
  void dispose() {
    _descCtrl.dispose();
    _amountCtrl.dispose();
    _qtyCtrl.dispose();
    super.dispose();
  }

  bool get _isCompras => _category == ExpenseCategory.compras;

  Future<void> _save() async {
    final amount = double.tryParse(_amountCtrl.text.replaceAll(',', '.')) ?? 0;
    if (amount <= 0) return;

    setState(() => _saving = true);

    final expense = Expense(
      id:          0,   // el service asigna el id real
      date:        DateTime.now(),
      amount:      amount,
      category:    _category,
      description: _descCtrl.text.trim(),
      productId:   (_isCompras && _selectedProduct != null)
          ? _selectedProduct!.id
          : 0,
      productName: (_isCompras && _selectedProduct != null)
          ? _selectedProduct!.name
          : '',
      quantity: (_isCompras)
          ? (int.tryParse(_qtyCtrl.text) ?? 1)
          : 0,
    );

    await widget.onSave(expense);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppTheme.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            Text('Nuevo gasto', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 16),

            // ── Selector de categoría ──────────────────────────────────
            Text('Categoría', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Row(
              children: ExpenseCategory.values.map((cat) {
                const colors = {
                  ExpenseCategory.compras:  AppTheme.info,
                  ExpenseCategory.facturas: AppTheme.warning,
                  ExpenseCategory.personal: AppTheme.secondary,
                  ExpenseCategory.otro:     AppTheme.textSecondary,
                };
                final color    = colors[cat] ?? AppTheme.textSecondary;
                final selected = _category == cat;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: GestureDetector(
                      onTap: () => setState(() => _category = cat),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: selected
                              ? color.withValues(alpha: 0.12)
                              : AppTheme.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: selected ? color : AppTheme.border,
                            width: selected ? 1.5 : 1,
                          ),
                        ),
                        child: Text(
                          cat.label,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color:      selected ? color : AppTheme.textSecondary,
                            fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 16),

            // ── Compras: selector de producto + cantidad ───────────────
            if (_isCompras) ...[
              Text('Producto', style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),
              DropdownButtonFormField<Product>(
                value: _selectedProduct,
                hint: const Text('Selecciona un producto'),
                decoration: const InputDecoration(isDense: true),
                items: widget.products
                    .map((p) => DropdownMenuItem(
                          value: p,
                          child: Text('${p.name}  (stock: ${p.stock})'),
                        ))
                    .toList(),
                onChanged: (p) {
                  setState(() => _selectedProduct = p);
                  // Rellenar precio automáticamente con el coste si existe
                  if (p?.costPrice != null) {
                    _amountCtrl.text =
                        ((p!.costPrice! * (int.tryParse(_qtyCtrl.text) ?? 1))
                                .toStringAsFixed(2));
                  }
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _qtyCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Cantidad *',
                        isDense: true,
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (v) {
                        // Actualizar importe si hay precio de coste
                        final qty  = int.tryParse(v) ?? 1;
                        final cost = _selectedProduct?.costPrice;
                        if (cost != null) {
                          _amountCtrl.text =
                              (cost * qty).toStringAsFixed(2);
                          setState(() {});
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _amountCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Importe total (€) *',
                        isDense: true,
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[\d,.]')),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descCtrl,
                decoration: const InputDecoration(
                  labelText: 'Descripción (opcional)',
                  isDense: true,
                ),
              ),
            ] else ...[
              // ── Otros: descripción + importe ─────────────────────────
              TextField(
                controller: _descCtrl,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountCtrl,
                decoration: const InputDecoration(
                  labelText: 'Importe (€) *',
                  prefixIcon: Icon(Icons.euro),
                  isDense: true,
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d,.]')),
                ],
              ),
            ],

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 20, width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white,
                        ),
                      )
                    : const Text('Registrar gasto'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Tarjeta de resumen ────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final String   label;
  final String   value;
  final Color    color;
  final IconData icon;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11, color: color, fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: AppTheme.textPrimary, fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ── Top productos vendidos ────────────────────────────────────────────────────

class _TopProductsCard extends StatelessWidget {
  final Map<String, int> products;
  const _TopProductsCard({required this.products});

  @override
  Widget build(BuildContext context) {
    final theme  = Theme.of(context);
    final sorted = products.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top    = sorted.take(5).toList();
    final maxVal = top.isEmpty ? 1 : top.first.value;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Más vendidos hoy', style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          ...top.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                SizedBox(
                  width: 100,
                  child: Text(e.key,
                      style: theme.textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: e.value / maxVal,
                      minHeight: 8,
                      backgroundColor: AppTheme.border,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text('${e.value}',
                    style: theme.textTheme.labelMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

// ── Fila de reporte histórico ─────────────────────────────────────────────────

class _ReportRow extends StatelessWidget {
  final DailyReport  report;
  final NumberFormat fmt;
  final DateFormat   dateFmt;

  const _ReportRow({
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
                    dateFmt.format(report.date),
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
