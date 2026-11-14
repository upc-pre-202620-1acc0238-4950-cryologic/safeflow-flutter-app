import 'package:flutter/material.dart';

import '../theme/safeflow_theme.dart';

class SafeFlowBrand extends StatelessWidget {
  const SafeFlowBrand({super.key, this.subtitle});

  final String? subtitle;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: SafeFlowColors.primaryContainer,
          borderRadius: BorderRadius.circular(15),
        ),
        child: const Icon(
          Icons.ac_unit_rounded,
          color: SafeFlowColors.primary,
          size: 29,
        ),
      ),
      const SizedBox(width: 12),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('SafeFlow', style: Theme.of(context).textTheme.titleLarge),
          if (subtitle != null)
            Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    ],
  );
}

class SafeFlowSectionTitle extends StatelessWidget {
  const SafeFlowSectionTitle(this.text, {super.key, this.trailing});
  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(text, style: Theme.of(context).textTheme.titleLarge),
      ),
      ?trailing,
    ],
  );
}

class SafeFlowCard extends StatelessWidget {
  const SafeFlowCard({
    super.key,
    required this.title,
    this.subtitle,
    this.value,
    this.detail,
    this.icon,
    this.tone = SafeFlowTone.normal,
    this.onTap,
    this.trailing,
    this.child,
  });

  final String title;
  final String? subtitle;
  final String? value;
  final String? detail;
  final IconData? icon;
  final SafeFlowTone tone;
  final VoidCallback? onTap;
  final Widget? trailing;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: tone.foreground, size: 20),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              ?trailing,
              if (onTap != null)
                const Icon(
                  Icons.chevron_right_rounded,
                  color: SafeFlowColors.textSecondary,
                ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
          ],
          if (value != null) ...[
            const SizedBox(height: 13),
            Text(
              value!,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: tone.foreground),
            ),
          ],
          if (detail != null) ...[
            const SizedBox(height: 4),
            Text(detail!, style: Theme.of(context).textTheme.bodySmall),
          ],
          if (child != null) ...[const SizedBox(height: 12), child!],
        ],
      ),
    );
    return Card(
      child: onTap == null
          ? content
          : InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(16),
              child: content,
            ),
    );
  }
}

class SafeFlowCallout extends StatelessWidget {
  const SafeFlowCallout({
    super.key,
    required this.title,
    required this.message,
    this.tone = SafeFlowTone.muted,
    this.onTap,
  });

  final String title;
  final String message;
  final SafeFlowTone tone;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: tone.background,
    borderRadius: BorderRadius.circular(14),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(tone.icon, color: tone.foreground, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: tone.foreground,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: TextStyle(
                      color: tone.foreground,
                      height: 1.4,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

enum SafeFlowTone { normal, warning, critical, success, muted }

extension on SafeFlowTone {
  Color get foreground => switch (this) {
    SafeFlowTone.warning => SafeFlowColors.warning,
    SafeFlowTone.critical => SafeFlowColors.critical,
    SafeFlowTone.success || SafeFlowTone.normal => SafeFlowColors.primary,
    SafeFlowTone.muted => SafeFlowColors.textSecondary,
  };

  Color get background => switch (this) {
    SafeFlowTone.warning => SafeFlowColors.warningContainer,
    SafeFlowTone.critical => SafeFlowColors.criticalContainer,
    SafeFlowTone.success ||
    SafeFlowTone.normal => SafeFlowColors.primaryContainer,
    SafeFlowTone.muted => const Color(0xFFF0F3F1),
  };

  IconData get icon => switch (this) {
    SafeFlowTone.warning => Icons.warning_amber_rounded,
    SafeFlowTone.critical => Icons.error_outline_rounded,
    SafeFlowTone.success ||
    SafeFlowTone.normal => Icons.check_circle_outline_rounded,
    SafeFlowTone.muted => Icons.info_outline_rounded,
  };
}

class SafeFlowInput extends StatelessWidget {
  const SafeFlowInput({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.helper,
    this.error,
    this.password = false,
    this.numeric = false,
    this.enabled = true,
    this.maxLines = 1,
    this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final String? helper;
  final String? error;
  final bool password;
  final bool numeric;
  final bool enabled;
  final int maxLines;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 7),
      TextField(
        controller: controller,
        obscureText: password,
        enabled: enabled,
        maxLines: password ? 1 : maxLines,
        onChanged: onChanged,
        keyboardType: numeric
            ? const TextInputType.numberWithOptions(decimal: true, signed: true)
            : TextInputType.text,
        decoration: InputDecoration(hintText: hint ?? 'Ingresa un valor'),
      ),
      if (error != null) ...[
        const SizedBox(height: 5),
        Text(
          error!,
          style: TextStyle(
            color: Theme.of(context).colorScheme.error,
            fontSize: 12,
          ),
        ),
      ] else if (helper != null) ...[
        const SizedBox(height: 5),
        Text(helper!, style: Theme.of(context).textTheme.bodySmall),
      ],
    ],
  );
}

class SafeFlowFilterChips extends StatelessWidget {
  const SafeFlowFilterChips({
    super.key,
    required this.values,
    required this.selected,
    required this.onSelected,
  });

  final List<String> values;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: values.map((value) {
        final active = value == selected;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            label: Text(value),
            selected: active,
            onSelected: (_) => onSelected(value),
            showCheckmark: false,
            backgroundColor: Colors.white,
            selectedColor: SafeFlowColors.primaryContainer,
            side: BorderSide(
              color: active
                  ? SafeFlowColors.primaryContainer
                  : SafeFlowColors.outline,
            ),
            labelStyle: TextStyle(
              color: active
                  ? SafeFlowColors.primary
                  : SafeFlowColors.textSecondary,
              fontWeight: active ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        );
      }).toList(),
    ),
  );
}

String dateLabel(DateTime? date) {
  if (date == null) return '—';
  final local = date.toLocal();
  String two(int value) => value.toString().padLeft(2, '0');
  return '${two(local.day)}/${two(local.month)}/${local.year} ${two(local.hour)}:${two(local.minute)}';
}

SafeFlowTone toneForStatus(String status) {
  final normalized = status.toUpperCase();
  if (normalized.contains('CRITICAL') || normalized.contains('CRÍTICO')) {
    return SafeFlowTone.critical;
  }
  if (normalized.contains('RISK') ||
      normalized.contains('WARNING') ||
      normalized.contains('ADVERTENCIA') ||
      normalized.contains('RIESGO') ||
      normalized.contains('DISCONNECTED')) {
    return SafeFlowTone.warning;
  }
  if (normalized.contains('NORMAL') || normalized.contains('OK')) {
    return SafeFlowTone.success;
  }
  return SafeFlowTone.muted;
}

String readableStatus(String value) => switch (value.toUpperCase()) {
  'NORMAL' => 'Normal',
  'WARNING' => 'Advertencia',
  'RISK' => 'Riesgo',
  'CRITICAL' => 'Crítico',
  'DISCONNECTED' => 'Desconectado',
  'UNKNOWN' => 'Sin lecturas',
  'PREPARATION' => 'En preparación',
  'TRANSIT' => 'En tránsito',
  'DELIVERED' => 'Entregado',
  _ => value,
};
