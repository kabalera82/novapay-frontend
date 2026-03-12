// lib/data/models/enums/tax_rate.enum.dart

enum TaxRate {
  exento,
  superReducido,
  reducido,
  general,
}

extension TaxRateValue on TaxRate {
  double get value {
    switch (this) {
      case TaxRate.exento:         return 0.00;
      case TaxRate.superReducido:  return 0.04;
      case TaxRate.reducido:       return 0.10;
      case TaxRate.general:        return 0.21;
    }
  }

  String get label {
    switch (this) {
      case TaxRate.exento:         return 'Exento (0%)';
      case TaxRate.superReducido:  return 'Superreducido (4%)';
      case TaxRate.reducido:       return 'Reducido (10%)';
      case TaxRate.general:        return 'General (21%)';
    }
  }
}