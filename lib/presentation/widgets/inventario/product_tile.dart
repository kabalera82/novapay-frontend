// lib/presentation/widgets/inventario/product_tile.dart
import 'package:flutter/material.dart';
import '../../../config/app_formats.dart';
import '../../../config/theme.dart';
import '../../../data/models/enums/tax_rate_enum.dart';
import '../../../data/models/product.dart';

class ProductTile extends StatelessWidget {
  final Product  product;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final void Function(int delta) onStockChange;

  const ProductTile({
    super.key,
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
        width: 44, height: 44,
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
                AppFormats.currency.format(product.price),
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
