// lib/presentation/widgets/inventario/product_form_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../config/theme.dart';
import '../../../data/models/enums/tax_rate_enum.dart';
import '../../../data/models/product.dart';

class ProductFormSheet extends StatefulWidget {
  final Product?                        product;
  final Future<void> Function(Product)  onSave;

  const ProductFormSheet({super.key, this.product, required this.onSave});

  @override
  State<ProductFormSheet> createState() => _ProductFormSheetState();
}

class _ProductFormSheetState extends State<ProductFormSheet> {
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
      _stockCtrl.text   = p.stock < 0 ? '' : '${p.stock}';
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
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
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
                      decoration:
                          const InputDecoration(labelText: 'Coste (€)'),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
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
                initialValue: _taxRate,
                decoration: const InputDecoration(labelText: 'Tipo IVA'),
                items: TaxRate.values
                    .map((t) =>
                        DropdownMenuItem(value: t, child: Text(t.label)))
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
                            strokeWidth: 2, color: Colors.white,
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
