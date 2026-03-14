// lib/presentation/widgets/common/ticket_status_badge.dart
import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../data/models/ticket.dart';

// ── Funciones de utilidad ─────────────────────────────────────────────────────

Color ticketStatusColor(TicketStatus status) => switch (status) {
      TicketStatus.abierto   => AppTheme.info,
      TicketStatus.pagado    => AppTheme.success,
      TicketStatus.cancelado => AppTheme.error,
    };

String ticketStatusLabel(TicketStatus status) => switch (status) {
      TicketStatus.abierto   => 'Abierto',
      TicketStatus.pagado    => 'Pagado',
      TicketStatus.cancelado => 'Cancelado',
    };

String paymentMethodLabel(PaymentMethod method) => switch (method) {
      PaymentMethod.efectivo => 'Efectivo',
      PaymentMethod.tarjeta  => 'Tarjeta',
      PaymentMethod.mixto    => 'Mixto',
    };

// ── Widget ────────────────────────────────────────────────────────────────────

/// Badge de color para mostrar el estado de un ticket.
/// Usa los parámetros opcionales para ajustar tamaño en lista vs. detalle.
class TicketStatusBadge extends StatelessWidget {
  final TicketStatus          status;
  final EdgeInsetsGeometry    padding;
  final double                fontSize;
  final double                borderRadius;
  final FontWeight            fontWeight;

  const TicketStatusBadge(
    this.status, {
    super.key,
    this.padding      = const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    this.fontSize     = 11,
    this.borderRadius = 8,
    this.fontWeight   = FontWeight.w600,
  });

  @override
  Widget build(BuildContext context) {
    final color = ticketStatusColor(status);
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color:        color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Text(
        ticketStatusLabel(status),
        style: TextStyle(
          fontSize:   fontSize,
          color:      color,
          fontWeight: fontWeight,
        ),
      ),
    );
  }
}
