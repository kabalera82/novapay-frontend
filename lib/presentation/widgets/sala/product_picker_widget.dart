// lib/presentation/widgets/sala/product_picker_widget.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../config/app_formats.dart';
import '../../../data/models/product.dart';
import '../../controllers/product_controller.dart';

/// Selector de productos reutilizable.
/// Usado en Sala (añadir a mesa) y en el TPV principal.
class ProductPickerWidget extends StatefulWidget {
  final void Function(Product) onProductSelected;

  const ProductPickerWidget({super.key, required this.onProductSelected});

  @override
  State<ProductPickerWidget> createState() => _ProductPickerWidgetState();
}

class _ProductPickerWidgetState extends State<ProductPickerWidget> {
  final _searchCtrl  = TextEditingController();
  final _productCtrl = Get.find<ProductController>();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        // ── Panel izquierdo: categorías ───────────────────────────────────
        Obx(() {
          final categories     = _productCtrl.categories.toList();
          final selectedCat    = _productCtrl.selectedCategory.value;

          return SizedBox(
            width: 100,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
              ),
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: categories.length,
                itemBuilder: (_, i) {
                  final cat      = categories[i];
                  final selected = cat == selectedCat;

                  return _CategoryButton(
                    label:    cat,
                    selected: selected,
                    onTap:    () => _productCtrl.applyFilter(cat),
                  );
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
                child: TextField(
                  controller: _searchCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Buscar…',
                    prefixIcon: Icon(Icons.search, size: 20),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 12,
                    ),
                  ),
                  onChanged: _productCtrl.search,
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
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    itemCount:        products.length,
                    separatorBuilder: (_, _) =>
                        const Divider(height: 1, indent: 12, endIndent: 12),
                    itemBuilder: (_, i) => _ProductRow(
                      product:   products[i],
                      onTap:     () => widget.onProductSelected(products[i]),
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
  final String       label;
  final bool         selected;
  final VoidCallback onTap;

  const _CategoryButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width:   double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primaryContainer
              : Colors.transparent,
          border: selected
              ? Border(
                  left: BorderSide(
                    color: theme.colorScheme.primary,
                    width: 3,
                  ),
                )
              : null,
        ),
        child: Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: selected
                ? theme.colorScheme.onPrimaryContainer
                : theme.colorScheme.onSurfaceVariant,
            fontWeight:
                selected ? FontWeight.w700 : FontWeight.normal,
          ),
          maxLines:  2,
          overflow:  TextOverflow.ellipsis,
          textAlign: TextAlign.left,
        ),
      ),
    );
  }
}

// ── Fila de producto (panel derecho) ─────────────────────────────────────────

class _ProductRow extends StatelessWidget {
  final Product      product;
  final VoidCallback onTap;

  const _ProductRow({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                product.name,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              AppFormats.currency.format(product.price),
              style: theme.textTheme.bodyLarge?.copyWith(
                color:      theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
