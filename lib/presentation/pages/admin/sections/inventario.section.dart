// lib/presentation/pages/admin/sections/inventario.section.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:isar/isar.dart';

import '../../../../config/theme.dart';
import '../../../../data/models/enums/tax.rate.enum.dart';
import '../../../../data/models/product.dart';
import '../../../controllers/product.controller.dart';

class InventarioSection extends StatefulWidget {
  const InventarioSection({super.key});

  @override
  State<InventarioSection> createState() => _InventarioSectionState();
}

class _InventarioSectionState extends State<InventarioSection> {
  final _ctrl       = Get.find<ProductController>();
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _openForm({Product? product}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ProductFormSheet(
        product: product,
        onSave: (p) async {
          if (p.id == Isar.autoIncrement || p.id == 0) {
            await _ctrl.create(p);
          } else {
            await _ctrl.saveProduct(p);
          }
        },
      ),
    );
  }

  Future<void> _confirmDelete(Product p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar producto'),
        content: Text('¿Eliminar "${p.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (ok == true) await _ctrl.remove(p.id);
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
              Text('Inventario', style: theme.textTheme.headlineMedium),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Recargar',
                onPressed: _ctrl.loadAll,
              ),
              ElevatedButton.icon(
                icon:  const Icon(Icons.add, size: 18),
                label: const Text('Nuevo'),
                onPressed: () => _openForm(),
              ),
            ],
          ),
        ),

        // ── Búsqueda ─────────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: TextField(
            controller: _searchCtrl,
            decoration: const InputDecoration(
              hintText: 'Buscar producto…',
              prefixIcon: Icon(Icons.search),
              isDense: true,
            ),
            onChanged: _ctrl.search,
          ),
        ),

        // ── Categorías ───────────────────────────────────────────────────────
        Obx(() {
          final cats = _ctrl.categories.toList();
          return SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              itemCount: cats.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final cat      = cats[i];
                final selected = _ctrl.selectedCategory.value == cat ||
                    (cat == 'Todos' && _ctrl.selectedCategory.value.isEmpty);
                return GestureDetector(
                  onTap: () => _ctrl.applyFilter(cat),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppTheme.primary.withValues(alpha: 0.12)
                          : AppTheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected ? AppTheme.primary : AppTheme.border,
                        width: selected ? 1.5 : 1,
                      ),
                    ),
                    child: Text(
                      cat,
                      style: TextStyle(
                        fontSize: 12,
                        color: selected ? AppTheme.primary : AppTheme.textSecondary,
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        }),

        // ── Stats de stock ───────────────────────────────────────────────────
        Obx(() {
          final all      = _ctrl.products.toList();
          final lowStock = all.where((p) => p.stock > 0 && p.stock < 5).length;
          final outStock = all.where((p) => p.stock == 0).length;
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
            child: Wrap(
              spacing: 8,
              children: [
                _StatBadge('${all.length} productos', AppTheme.primary),
                if (lowStock > 0)
                  _StatBadge('$lowStock stock bajo', AppTheme.warning),
                if (outStock > 0)
                  _StatBadge('$outStock agotados', AppTheme.error),
              ],
            ),
          );
        }),

        const Divider(height: 1),

        // ── Lista ────────────────────────────────────────────────────────────
        Expanded(
          child: Obx(() {
            final list = _ctrl.filtered.toList();
            if (list.isEmpty) {
              return Center(
                child: Text(
                  'Sin productos',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: AppTheme.textSecondary),
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: list.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final p = list[i];
                return _ProductTile(
                  product:  p,
                  onTap:    () => _openForm(product: p),
                  onDelete: () => _confirmDelete(p),
                  onStockChange: (delta) async {
                    p.stock = (p.stock + delta).clamp(0, 999999);
                    await _ctrl.saveProduct(p);
                  },
                );
              },
            );
          }),
        ),
      ],
    );
  }
}

// ── Fila de producto ──────────────────────────────────────────────────────────

class _ProductTile extends StatelessWidget {
  final Product  product;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final void Function(int delta) onStockChange;

  const _ProductTile({
    required this.product,
    required this.onTap,
    required this.onDelete,
    required this.onStockChange,
  });

  Color _stockColor() {
    if (product.stock == 0) return AppTheme.error;
    if (product.stock < 5)  return AppTheme.warning;
    return AppTheme.success;
  }

  @override
  Widget build(BuildContext context) {
    final theme      = Theme.of(context);
    final stockColor = _stockColor();

    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppTheme.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            product.name.isNotEmpty ? product.name[0].toUpperCase() : '?',
            style: const TextStyle(
              color: AppTheme.primary,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
      ),
      title: Text(
        product.name,
        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        '${product.category ?? 'Sin categoría'}  ·  ${product.taxRate.label}',
        style: theme.textTheme.bodySmall,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${product.price.toStringAsFixed(2)} €',
                style: theme.textTheme.labelLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: () => onStockChange(-1),
                    child: Icon(Icons.remove_circle_outline,
                        size: 18, color: AppTheme.error),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: stockColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${product.stock}',
                      style: TextStyle(
                        fontSize: 12,
                        color: stockColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  InkWell(
                    onTap: () => onStockChange(1),
                    child: Icon(Icons.add_circle_outline,
                        size: 18, color: AppTheme.success),
                  ),
                ],
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20),
            color: AppTheme.error,
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

// ── Formulario de producto ────────────────────────────────────────────────────

class _ProductFormSheet extends StatefulWidget {
  final Product?                        product;
  final Future<void> Function(Product)  onSave;

  const _ProductFormSheet({this.product, required this.onSave});

  @override
  State<_ProductFormSheet> createState() => _ProductFormSheetState();
}

class _ProductFormSheetState extends State<_ProductFormSheet> {
  final _formKey     = GlobalKey<FormState>();
  final _namCtrl     = TextEditingController();
  final _catCtrl     = TextEditingController();
  final _priceCtrl   = TextEditingController();
  final _costCtrl    = TextEditingController();
  final _stockCtrl   = TextEditingController();
  final _barcodeCtrl = TextEditingController();
  TaxRate _taxRate   = TaxRate.general;
  bool    _saving    = false;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    if (p != null) {
      _namCtrl.text     = p.name;
      _catCtrl.text     = p.category ?? '';
      _priceCtrl.text   = p.price.toStringAsFixed(2);
      _costCtrl.text    = p.costPrice?.toStringAsFixed(2) ?? '';
      _stockCtrl.text   = '${p.stock}';
      _barcodeCtrl.text = p.barcode ?? '';
      _taxRate          = p.taxRate;
    }
  }

  @override
  void dispose() {
    _namCtrl.dispose();    _catCtrl.dispose();
    _priceCtrl.dispose();  _costCtrl.dispose();
    _stockCtrl.dispose();  _barcodeCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final p      = widget.product ?? Product();
    p.name       = _namCtrl.text.trim();
    p.category   = _catCtrl.text.trim().isEmpty ? null : _catCtrl.text.trim();
    p.price      = double.tryParse(_priceCtrl.text.replaceAll(',', '.')) ?? 0;
    p.costPrice  = _costCtrl.text.trim().isEmpty
        ? null
        : double.tryParse(_costCtrl.text.replaceAll(',', '.'));
    p.stock      = int.tryParse(_stockCtrl.text) ?? 0;
    p.barcode    = _barcodeCtrl.text.trim().isEmpty
        ? null
        : _barcodeCtrl.text.trim();
    p.taxRate    = _taxRate;

    await widget.onSave(p);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme  = Theme.of(context);
    final isEdit = widget.product != null;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              Text(
                isEdit ? 'Editar producto' : 'Nuevo producto',
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _namCtrl,
                decoration: const InputDecoration(labelText: 'Nombre *'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _catCtrl,
                      decoration: const InputDecoration(labelText: 'Categoría'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _priceCtrl,
                      decoration: const InputDecoration(labelText: 'PVP (€) *'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[\d,.]')),
                      ],
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Requerido';
                        if (double.tryParse(v.replaceAll(',', '.')) == null) {
                          return 'Inválido';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _costCtrl,
                      decoration: const InputDecoration(labelText: 'Coste (€)'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[\d,.]')),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _stockCtrl,
                      decoration: const InputDecoration(labelText: 'Stock'),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<TaxRate>(
                value: _taxRate,
                decoration: const InputDecoration(labelText: 'Tipo IVA'),
                items: TaxRate.values
                    .map((t) => DropdownMenuItem(value: t, child: Text(t.label)))
                    .toList(),
                onChanged: (v) => setState(() => _taxRate = v!),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _barcodeCtrl,
                decoration: const InputDecoration(
                  labelText: 'Código de barras',
                  prefixIcon: Icon(Icons.barcode_reader),
                ),
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          height: 20, width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(isEdit ? 'Guardar cambios' : 'Crear producto'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Badge estadística ─────────────────────────────────────────────────────────

class _StatBadge extends StatelessWidget {
  final String label;
  final Color  color;
  const _StatBadge(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color:  color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
