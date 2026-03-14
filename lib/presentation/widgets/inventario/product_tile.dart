// lib/presentation/widgets/inventario/product_tile.dart
import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../data/models/enums/tax_rate_enum.dart';
import '../../../data/models/product.dart';

class ProductTile extends StatelessWidget {
  final Product product;
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

  bool get _isUnlimited => product.stock > 100 || product.stock < 0;

  Color _stockColor() {
    if (_isUnlimited) return AppTheme.success;
    if (product.stock == 0) return AppTheme.error;
    if (product.stock < 5) return AppTheme.warning;
    return AppTheme.success;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
            style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ),
      ),
      title: Text(product.name, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
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
                style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!_isUnlimited)
                    InkWell(
                      onTap: () => onStockChange(-1),
                      child: Icon(Icons.remove_circle_outline, size: 18, color: AppTheme.error),
                    ),
                  if (!_isUnlimited) const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: stockColor.withValues(alpha: 0.12), // Mantenemos tu fondo sutil
                      borderRadius: BorderRadius.circular(8),
                    ),
                    // Evaluamos qué widget mostrar en lugar de qué texto pintar
                    child: _isUnlimited
                        ? Icon(
                            Icons.all_inclusive, // El icono de infinito de Material Design
                            size: 14, // Un tamaño fijo que cuadre bien con tu diseño
                            color: stockColor, // Usa exactamente el mismo verde de tu tema
                          )
                        : Text(
                            '${product.stock}',
                            style: TextStyle(
                              fontSize: 10, // Puedes ajustar esto para que los números se vean bien
                              color: stockColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                  if (!_isUnlimited) const SizedBox(width: 4),
                  if (!_isUnlimited)
                    InkWell(
                      onTap: () => onStockChange(1),
                      child: Icon(Icons.add_circle_outline, size: 18, color: AppTheme.success),
                    ),
                ],
              ),
            ],
          ),
          IconButton(icon: const Icon(Icons.delete_outline, size: 20), color: AppTheme.error, onPressed: onDelete),
        ],
      ),
    );
  }
}
