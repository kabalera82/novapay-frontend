// lib/presentation/widgets/sala/product_picker_widget.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../config/app_formats.dart';
import '../../../data/models/product.dart';
import '../../controllers/product_controller.dart';
import '../common/app_text_field.dart';

/// Selector de productos reutilizable.
/// Usado en Sala (añadir a mesa) y en el TPV principal.
class ProductPickerWidget extends StatefulWidget {
  final void Function(Product) onProductSelected;

  const ProductPickerWidget({super.key, required this.onProductSelected});

  @override
  State<ProductPickerWidget> createState() => _ProductPickerWidgetState();
}

class _ProductPickerWidgetState extends State<ProductPickerWidget> {
  final _searchCtrl = TextEditingController();
  final _productCtrl = Get.find<ProductController>();
  final Set<int> _selectedProductIds = {};

  @override
  void initState() {
    super.initState();
    // Marca todos los productos como seleccionados por defecto
    _selectedProductIds.addAll(_productCtrl.filtered.map((p) => p.id));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _toggleProductSelection(Product product) {
    setState(() {
      if (_selectedProductIds.contains(product.id)) {
        _selectedProductIds.remove(product.id);
      } else {
        _selectedProductIds.add(product.id);
      }
    });
    // Ejecuta el callback para agregar el producto
    if (_selectedProductIds.contains(product.id)) {
      widget.onProductSelected(product);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        // ── Panel izquierdo: categorías ───────────────────────────────────
        Obx(() {
          final categories = _productCtrl.categories.toList();
          final selectedCat = _productCtrl.selectedCategory.value;

          return SizedBox(
            width: 100,
            child: DecoratedBox(
              decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHighest),
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: categories.length,
                itemBuilder: (_, i) {
                  final cat = categories[i];
                  final selected = cat == selectedCat;

                  return _CategoryButton(label: cat, selected: selected, onTap: () => _productCtrl.applyFilter(cat));
                },
              ),
            ),
          );
        }),

        const VerticalDivider(width: 1, thickness: 1),

        // ── Panel derecho: buscador + lista de productos ───────────────────
        Expanded(
          child: Column(
            children: [
              // Buscador
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
                child: AppTextField(
                  controller: _searchCtrl,
                  hintText: 'Buscar…',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  decoration: const InputDecoration(
                    hintText: 'Buscar…',
                    prefixIcon: Icon(Icons.search, size: 20),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  ),
                  onChanged: (value) {
                    _productCtrl.search(value);
                    // Actualizar selección por defecto cuando filtra
                    setState(() {
                      _selectedProductIds.clear();
                      _selectedProductIds.addAll(_productCtrl.filtered.map((p) => p.id));
                    });
                  },
                ),
              ),

              // Lista de productos
              Expanded(
                child: Obx(() {
                  final products = _productCtrl.filtered.toList();

                  if (products.isEmpty) {
                    return Center(
                      child: Text(
                        'Sin productos',
                        style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    );
                  }

                  return ListView.separated(
                    itemCount: products.length,
                    separatorBuilder: (_, _) => const Divider(height: 1, indent: 12, endIndent: 12),
                    itemBuilder: (_, i) => _ProductRow(
                      product: products[i],
                      isSelected: _selectedProductIds.contains(products[i].id),
                      onToggle: () => _toggleProductSelection(products[i]),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Botón de categoría (panel izquierdo) ──────────────────────────────────────

class _CategoryButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryButton({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? theme.colorScheme.primaryContainer : Colors.transparent,
          border: selected ? Border(left: BorderSide(color: theme.colorScheme.primary, width: 3)) : null,
        ),
        child: Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: selected ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSurfaceVariant,
            fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.left,
        ),
      ),
    );
  }
}

// ── Fila de producto (panel derecho) ─────────────────────────────────────────

class _ProductRow extends StatelessWidget {
  final Product product;
  final bool isSelected;
  final VoidCallback onToggle;

  const _ProductRow({required this.product, required this.isSelected, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onToggle,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            // Checkbox de selección
            Checkbox(
              value: isSelected,
              onChanged: (_) => onToggle(),
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            const SizedBox(width: 8),
            // Nombre del producto
            Expanded(
              child: Text(
                product.name,
                style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            // Precio
            Text(
              AppFormats.currency.format(product.price),
              style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
