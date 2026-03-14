// lib/presentation/pages/admin/sections/inventario_section.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:isar/isar.dart';

import '../../../../config/theme.dart';
import '../../../../data/models/product.dart';
import '../../../controllers/product_controller.dart';
import '../../../widgets/common/confirm_delete_dialog.dart';
import '../../../widgets/common/filter_chip_button.dart';
import '../../../widgets/common/section_header.dart';
import '../../../widgets/inventario/product_form_sheet.dart';
import '../../../widgets/inventario/product_tile.dart';
import '../../../widgets/inventario/stat_badge.dart';

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
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => ProductFormSheet(
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
    final ok = await ConfirmDeleteDialog.show(
      context,
      title:   'Eliminar producto',
      message: '¿Eliminar "${p.name}"?',
    );
    if (ok) await _ctrl.remove(p.id);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title:     'Inventario',
          onRefresh: _ctrl.loadAll,
          trailing: ElevatedButton.icon(
            icon:      const Icon(Icons.add, size: 18),
            label:     const Text('Nuevo'),
            onPressed: () => _openForm(),
          ),
        ),

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
                return FilterChipButton(
                  label:    cat,
                  selected: selected,
                  onTap:    () => _ctrl.applyFilter(cat),
                );
              },
            ),
          );
        }),

        Obx(() {
          final all      = _ctrl.products.toList();
          final lowStock = all.where((p) => p.stock > 0 && p.stock < 5).length;
          final outStock = all.where((p) => p.stock == 0).length;
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
            child: Wrap(
              spacing: 8,
              children: [
                StatBadge('${all.length} productos', AppTheme.primary),
                if (lowStock > 0) StatBadge('$lowStock stock bajo', AppTheme.warning),
                if (outStock > 0) StatBadge('$outStock agotados',   AppTheme.error),
              ],
            ),
          );
        }),

        const Divider(height: 1),

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
                return ProductTile(
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
