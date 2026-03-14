// lib/presentation/widgets/common/section_header.dart
import 'package:flutter/material.dart';

/// Cabecera estándar de sección: título + botón de recarga + widget extra opcional.
class SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onRefresh;
  final Widget? trailing;

  const SectionHeader({
    super.key,
    required this.title,
    this.onRefresh,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineMedium),
          const Spacer(),
          if (onRefresh != null)
            IconButton(
              icon:    const Icon(Icons.refresh),
              tooltip: 'Recargar',
              onPressed: onRefresh,
            ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
