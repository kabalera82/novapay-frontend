// lib/config/app_formats.dart
import 'package:intl/intl.dart';

/// Formatos de presentación reutilizables para toda la app.
/// Centralizar aquí evita crear instancias de NumberFormat/DateFormat
/// dispersas por el código y garantiza coherencia de locale.
abstract class AppFormats {
  /// Moneda española: 1.234,56 €
  static final currency = NumberFormat.currency(locale: 'es_ES', symbol: '€');

  /// Fecha corta: 14/03/2026
  static final date = DateFormat('dd/MM/yyyy');

  /// Fecha y hora: 14/03/2026 08:30
  static final dateTime = DateFormat('dd/MM/yyyy HH:mm');

  /// Solo hora: 08:30
  static final time = DateFormat('HH:mm');
}
