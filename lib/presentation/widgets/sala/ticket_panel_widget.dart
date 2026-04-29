// lib/presentation/widgets/sala/ticket_panel_widget.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../config/app_formats.dart';
import '../../../config/theme.dart';
import '../../../data/models/product.dart';
import '../../../data/models/ticket_line.dart';
import '../../controllers/product_controller.dart';
import '../../controllers/ticket_controller.dart';
import 'payment_dialog_widget.dart';

/// Panel de gestión del ticket de una mesa.
/// Catálogo de productos como protagonista (con categorías desplegables) y
/// barra lateral del ticket con checkboxes para cobro parcial.
class TicketPanelWidget extends StatelessWidget {
  final int          tableNumber;
  final VoidCallback onClose;

  const TicketPanelWidget({super.key, required this.tableNumber, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final ticketCtrl  = Get.find<TicketController>();
    final productCtrl = Get.find<ProductController>();
    final fmt         = AppFormats.currency;
    final theme       = Theme.of(context);

    return Column(
      children: [
        // ── Cabecera ──────────────────────────────────────────────────────────
        _PanelHeader(
          tableNumber: tableNumber,
          ticketCtrl:  ticketCtrl,
          fmt:         fmt,
          onClose:     onClose,
        ),

        // ── Cuerpo: catálogo + ticket ─────────────────────────────────────────
        Expanded(
          child: LayoutBuilder(
            builder: (_, constraints) {
              if (constraints.maxWidth < 420) {
                return _TabLayout(
                  tableNumber:  tableNumber,
                  ticketCtrl:   ticketCtrl,
                  productCtrl:  productCtrl,
                  fmt:          fmt,
                  theme:        theme,
                  onClose:      onClose,
                );
              }
              return _SideBySideLayout(
                tableNumber:  tableNumber,
                ticketCtrl:   ticketCtrl,
                productCtrl:  productCtrl,
                fmt:          fmt,
                theme:        theme,
                onClose:      onClose,
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── Cabecera ─────────────────────────────────────────────────────────────────

class _PanelHeader extends StatelessWidget {
  final int              tableNumber;
  final TicketController ticketCtrl;
  final NumberFormat     fmt;
  final VoidCallback     onClose;

  const _PanelHeader({
    required this.tableNumber,
    required this.ticketCtrl,
    required this.fmt,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color:   theme.colorScheme.primaryContainer,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(Icons.table_restaurant, color: theme.colorScheme.onPrimaryContainer),
          const SizedBox(width: 8),
          Text(
            'Mesa $tableNumber',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
          const Spacer(),
          Obx(() => Text(
            fmt.format(ticketCtrl.activeTicket.value?.totalAmount ?? 0),
            style: theme.textTheme.headlineMedium?.copyWith(
              color:      theme.colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
          )),
          IconButton(
            icon:    const Icon(Icons.close),
            color:   theme.colorScheme.onPrimaryContainer,
            tooltip: 'Cerrar panel',
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}

// ── Layout side by side (≥420 px) ────────────────────────────────────────────

class _SideBySideLayout extends StatelessWidget {
  final int               tableNumber;
  final TicketController  ticketCtrl;
  final ProductController productCtrl;
  final NumberFormat      fmt;
  final ThemeData         theme;
  final VoidCallback      onClose;

  const _SideBySideLayout({
    required this.tableNumber,
    required this.ticketCtrl,
    required this.productCtrl,
    required this.fmt,
    required this.theme,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) {
        // Sidebar: mínimo 42% del ancho disponible
        final sidebarWidth = (constraints.maxWidth * 0.42).clamp(300.0, 560.0);
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Catálogo (toma el espacio sobrante)
            Expanded(
              child: _ProductCatalog(
                productCtrl: productCtrl,
                ticketCtrl:  ticketCtrl,
                fmt:         fmt,
              ),
            ),

            const VerticalDivider(width: 1, thickness: 1),

            // Sidebar del ticket (42% del ancho, mín 300 px)
            SizedBox(
              width: sidebarWidth,
              child: _TicketSidebar(
                ticketCtrl:  ticketCtrl,
                fmt:         fmt,
                tableNumber: tableNumber,
                onClose:     onClose,
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── Layout en tabs (< 420 px) ─────────────────────────────────────────────────

class _TabLayout extends StatelessWidget {
  final int               tableNumber;
  final TicketController  ticketCtrl;
  final ProductController productCtrl;
  final NumberFormat      fmt;
  final ThemeData         theme;
  final VoidCallback      onClose;

  const _TabLayout({
    required this.tableNumber,
    required this.ticketCtrl,
    required this.productCtrl,
    required this.fmt,
    required this.theme,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            tabs: const [
              Tab(icon: Icon(Icons.grid_view, size: 18), text: 'Productos'),
              Tab(icon: Icon(Icons.receipt_long, size: 18), text: 'Ticket'),
            ],
            labelColor:     theme.colorScheme.primary,
            indicatorColor: theme.colorScheme.primary,
          ),
          Expanded(
            child: TabBarView(
              children: [
                _ProductCatalog(
                  productCtrl: productCtrl,
                  ticketCtrl:  ticketCtrl,
                  fmt:         fmt,
                ),
                _TicketSidebar(
                  ticketCtrl:  ticketCtrl,
                  fmt:         fmt,
                  tableNumber: tableNumber,
                  onClose:     onClose,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Catálogo de productos ─────────────────────────────────────────────────────

class _ProductCatalog extends StatelessWidget {
  final ProductController productCtrl;
  final TicketController  ticketCtrl;
  final NumberFormat      fmt;

  const _ProductCatalog({
    required this.productCtrl,
    required this.ticketCtrl,
    required this.fmt,
  });

  Future<void> _addProduct(Product product) async {
    final line = TicketLine()
      ..productName   = product.name
      ..productId     = product.id
      ..quantity      = 1
      ..priceAtMoment = product.price
      ..totalLine     = product.price;
    await ticketCtrl.addLineToActive(line);
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final allProducts = productCtrl.products.toList();

      if (allProducts.isEmpty) {
        return const Center(child: Text('Sin productos en el catálogo'));
      }

      final cats = allProducts
          .map((p) => p.category ?? 'Sin categoría')
          .toSet()
          .toList()
        ..sort();

      return ListView.builder(
        padding:   const EdgeInsets.only(bottom: 16),
        itemCount: cats.length,
        itemBuilder: (_, i) {
          final cat = cats[i];
          final catProducts =
              allProducts.where((p) => (p.category ?? 'Sin categoría') == cat).toList();
          return _CategorySection(
            category:     cat,
            products:     catProducts,
            onProductTap: _addProduct,
            fmt:          fmt,
          );
        },
      );
    });
  }
}

// ── Sección de categoría (desplegable) ───────────────────────────────────────

class _CategorySection extends StatefulWidget {
  final String                        category;
  final List<Product>                 products;
  final Future<void> Function(Product) onProductTap;
  final NumberFormat                  fmt;

  const _CategorySection({
    required this.category,
    required this.products,
    required this.onProductTap,
    required this.fmt,
  });

  @override
  State<_CategorySection> createState() => _CategorySectionState();
}

class _CategorySectionState extends State<_CategorySection> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: Row(
              children: [
                AnimatedRotation(
                  duration: const Duration(milliseconds: 150),
                  turns:    _expanded ? 0 : -0.25,
                  child: Icon(
                    Icons.expand_more,
                    size:  18,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  widget.category,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color:      AppTheme.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '(${widget.products.length})',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),

        if (_expanded)
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
            child: Wrap(
              spacing:    8,
              runSpacing: 8,
              children: widget.products
                  .map((p) => _ProductCard(
                        product: p,
                        fmt:     widget.fmt,
                        onTap:   () => widget.onProductTap(p),
                      ))
                  .toList(),
            ),
          ),

        const Divider(height: 1),
      ],
    );
  }
}

// ── Tarjeta de producto (mismo estilo visual que TableCardWidget) ─────────────

class _ProductCard extends StatelessWidget {
  final Product      product;
  final NumberFormat fmt;
  final VoidCallback onTap;

  const _ProductCard({
    required this.product,
    required this.fmt,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme      = Theme.of(context);
    final initial    = product.name.isNotEmpty ? product.name[0].toUpperCase() : '?';
    final outOfStock = product.stock == 0;

    return Opacity(
      opacity: outOfStock ? 0.4 : 1.0,
      child: GestureDetector(
        onTap: outOfStock ? null : onTap,
        child: AnimatedContainer(
          duration:   const Duration(milliseconds: 120),
          width:      80,
          padding:    const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color:        theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(10),
            border:       Border.all(color: AppTheme.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width:  40,
                height: 40,
                decoration: BoxDecoration(
                  color:        AppTheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    initial,
                    style: const TextStyle(
                      color:      AppTheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize:   18,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 4),

              Text(
                product.name,
                textAlign: TextAlign.center,
                maxLines:  2,
                overflow:  TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w500,
                  height:     1.2,
                ),
              ),

              const SizedBox(height: 2),

              Text(
                fmt.format(product.price),
                style: const TextStyle(
                  fontSize:   10,
                  color:      AppTheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Barra lateral del ticket (con selección para cobro parcial) ───────────────

class _TicketSidebar extends StatefulWidget {
  final TicketController ticketCtrl;
  final NumberFormat     fmt;
  final int              tableNumber;
  final VoidCallback     onClose;

  const _TicketSidebar({
    required this.ticketCtrl,
    required this.fmt,
    required this.tableNumber,
    required this.onClose,
  });

  @override
  State<_TicketSidebar> createState() => _TicketSidebarState();
}

class _TicketSidebarState extends State<_TicketSidebar> {
  /// Mapa de cantidad a cobrar por nombre de producto.
  /// 0 (o ausente) = línea no seleccionada.
  /// >0 = seleccionada, cobrar N unidades.
  final Map<String, int> _selectedQtyMap = {};

  bool _isSelected(String name) => (_selectedQtyMap[name] ?? 0) > 0;

  int _qtyFor(String name, int max) =>
      (_selectedQtyMap[name] ?? 0).clamp(0, max);

  double _selectedTotal(List<TicketLine> lines) {
    double total = 0;
    for (final line in lines) {
      final qty = _qtyFor(line.productName, line.quantity);
      if (qty > 0) total += line.priceAtMoment * qty;
    }
    return total;
  }

  List<int> _selectedIndices(List<TicketLine> lines) => [
    for (int i = 0; i < lines.length; i++)
      if (_isSelected(lines[i].productName)) i,
  ];

  Map<int, int> _partialQtys(List<TicketLine> lines) => {
    for (int i = 0; i < lines.length; i++)
      if (_isSelected(lines[i].productName))
        i: _qtyFor(lines[i].productName, lines[i].quantity),
  };

  void _showPayDialog(BuildContext context, List<TicketLine> lines) {
    final indices = _selectedIndices(lines);
    if (indices.isEmpty) return;

    final partials = _partialQtys(lines);

    PaymentDialogWidget.show(
      context,
      total:     _selectedTotal(lines),
      onConfirm: (method, mixedCash, mixedCard) async {
        // Capturar nombres antes de pagar (la lista cambiará)
        final paidNames = [for (final i in indices) lines[i].productName];

        await widget.ticketCtrl.payLines(
          indices,
          method,
          partialQtys: partials,
          mixedCashAmount: mixedCash,
          mixedCardAmount: mixedCard,
        );

        if (!mounted) return;

        if (widget.ticketCtrl.activeTicket.value == null) {
          widget.onClose();
        } else {
          // Desmarcar las líneas ya cobradas
          setState(() {
            for (final name in paidNames) {
              _selectedQtyMap.remove(name);
            }
          });
        }
      },
    );
  }

  Future<void> _confirmCancel(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title:   const Text('Cancelar mesa'),
        content: const Text(
          '¿Seguro que quieres cancelar esta mesa? Se perderán todos los datos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('Cancelar mesa'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await widget.ticketCtrl.cancelActive();
      widget.onClose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Obx cubre todo el widget: reacciona a cambios en activeTicket
    // setState cubre los cambios de checkbox
    return Obx(() {
      final ticket    = widget.ticketCtrl.activeTicket.value;
      final lines     = ticket?.lines ?? [];
      final selTotal  = _selectedTotal(lines);
      final hasSelect = selTotal > 0;

      return Column(
        children: [
          // ── Líneas del ticket ────────────────────────────────────────────
          Expanded(
            child: lines.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Ticket vacío.\nSelecciona productos.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  )
                : ListView.builder(
                    padding:   const EdgeInsets.symmetric(vertical: 4),
                    itemCount: lines.length,
                    itemBuilder: (_, i) {
                      final line = lines[i];
                      final selQty = _qtyFor(line.productName, line.quantity);
                      return _TicketLineRow(
                        line:        line,
                        fmt:         widget.fmt,
                        selectedQty: selQty,
                        onToggle: () => setState(() {
                          if (_isSelected(line.productName)) {
                            _selectedQtyMap.remove(line.productName);
                          } else {
                            // Por defecto todas las unidades: pago rápido habitual.
                            // El usuario reduce con el stepper si quiere pago parcial.
                            _selectedQtyMap[line.productName] = line.quantity;
                          }
                        }),
                        onPayQtyChange: (qty) => setState(
                          () => _selectedQtyMap[line.productName] =
                              qty.clamp(1, line.quantity),
                        ),
                        onIncrease: () => widget.ticketCtrl
                            .changeLineQuantity(line.productName, 1),
                        onDecrease: () => widget.ticketCtrl
                            .changeLineQuantity(line.productName, -1),
                        onRemove: () => widget.ticketCtrl
                            .removeLineFromActive(line.productName),
                      );
                    },
                  ),
          ),

          // ── Pie: total + botones ─────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(12, 14, 12, 18),
            decoration: BoxDecoration(
              color:  theme.colorScheme.surface,
              border: Border(top: BorderSide(color: AppTheme.border)),
            ),
            child: Column(
              children: [
                // Total general del ticket
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total', style: theme.textTheme.labelLarge),
                    Text(
                      widget.fmt.format(ticket?.totalAmount ?? 0),
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color:      AppTheme.primary,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Cobrar líneas seleccionadas
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon:  const Icon(Icons.payment, size: 18),
                    label: Text(
                      hasSelect
                          ? 'Cobrar ${widget.fmt.format(selTotal)}'
                          : 'Selecciona líneas',
                    ),
                    onPressed: hasSelect
                        ? () => _showPayDialog(context, lines)
                        : null,
                  ),
                ),

                const SizedBox(height: 6),

                // Cancelar mesa
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                      side:            BorderSide(color: theme.colorScheme.error),
                      padding:         const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onPressed: () => _confirmCancel(context),
                    child: const Text('Cancelar mesa'),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    });
  }
}

// ── Fila de línea del ticket ──────────────────────────────────────────────────
//
// Fila principal : [☐/☑] [−] N [+]  nombre  total  [×]
// Fila cobro     : (visible cuando seleccionada)
//   Cobrar: [−] M [+] de N   →  M × precio
//
class _TicketLineRow extends StatelessWidget {
  final TicketLine          line;
  final NumberFormat        fmt;
  /// 0 = no seleccionada; >0 = seleccionada, cobrar M unidades
  final int                 selectedQty;
  final VoidCallback        onToggle;
  final ValueChanged<int>   onPayQtyChange;
  final VoidCallback        onIncrease;
  final VoidCallback        onDecrease;
  final VoidCallback        onRemove;

  const _TicketLineRow({
    required this.line,
    required this.fmt,
    required this.selectedQty,
    required this.onToggle,
    required this.onPayQtyChange,
    required this.onIncrease,
    required this.onDecrease,
    required this.onRemove,
  });

  bool get _selected => selectedQty > 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final max   = line.quantity;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      color: _selected
          ? theme.colorScheme.primaryContainer.withValues(alpha: 0.4)
          : Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Fila principal ─────────────────────────────────────────────
          Row(
            children: [

              // Checkbox de selección para cobro
              SizedBox(
                width: 28, height: 28,
                child: Checkbox(
                  value:                 _selected,
                  onChanged:             (_) => onToggle(),
                  visualDensity:         VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),

              // Qty en ticket: − N +
              _SmallIconBtn(
                icon:    Icons.remove,
                color:   theme.colorScheme.error,
                onTap:   onDecrease,
                enabled: true,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Text(
                  '$max',
                  style: theme.textTheme.labelMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              _SmallIconBtn(
                icon:    Icons.add,
                color:   theme.colorScheme.primary,
                onTap:   onIncrease,
                enabled: true,
              ),

              const SizedBox(width: 5),

              // Nombre
              Expanded(
                child: Text(
                  line.productName,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              const SizedBox(width: 4),

              // Total de la línea completa
              Text(
                fmt.format(line.totalLine),
                style: theme.textTheme.bodySmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),

              // Eliminar línea
              _SmallIconBtn(
                icon:    Icons.close,
                color:   theme.colorScheme.error,
                onTap:   onRemove,
                enabled: true,
              ),
            ],
          ),

          // ── Sub-fila: cuántas unidades cobrar ahora ─────────────────────
          // Siempre visible cuando la línea está seleccionada.
          if (_selected)
            Padding(
              padding: const EdgeInsets.only(left: 30, top: 2, bottom: 4),
              child: Row(
                children: [
                  Text(
                    'Cobrar:',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color:      theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 6),

                  // − (desactivado cuando selectedQty == 1)
                  _SmallIconBtn(
                    icon:    Icons.remove_circle_outline,
                    color:   selectedQty > 1
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface.withValues(alpha: 0.25),
                    onTap:   () => onPayQtyChange(selectedQty - 1),
                    enabled: selectedQty > 1,
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Text(
                      '$selectedQty',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color:      theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  // + (desactivado cuando selectedQty == max)
                  _SmallIconBtn(
                    icon:    Icons.add_circle_outline,
                    color:   selectedQty < max
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface.withValues(alpha: 0.25),
                    onTap:   () => onPayQtyChange(selectedQty + 1),
                    enabled: selectedQty < max,
                  ),

                  const SizedBox(width: 4),
                  Text(
                    'de $max',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),

                  const Spacer(),

                  // Subtotal de lo que se va a cobrar
                  Text(
                    fmt.format(line.priceAtMoment * selectedQty),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color:      theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _SmallIconBtn extends StatelessWidget {
  final IconData     icon;
  final Color        color;
  final VoidCallback onTap;
  final bool         enabled;

  const _SmallIconBtn({
    required this.icon,
    required this.color,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap:        enabled ? onTap : null,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Icon(icon, size: 14, color: color),
      ),
    );
  }
}
