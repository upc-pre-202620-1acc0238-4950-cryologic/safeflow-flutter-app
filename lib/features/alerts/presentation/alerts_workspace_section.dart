import 'package:flutter/material.dart';

import '../../workspace/application/workspace_controller.dart';
import '../../../core/widgets/safe_flow_widgets.dart';
import '../../workspace/presentation/workspace_ui_context.dart';

class AlertsWorkspaceSection extends StatelessWidget {
  const AlertsWorkspaceSection({super.key, required this.ui});
  final WorkspaceUiContext ui;
  BuildContext get context => ui.buildContext!;
  WorkspaceController get controller => ui.controller;
  void setState(VoidCallback action) => ui.update(action);
  TextEditingController _field(String key) => ui.field(key);
  void _open(String screen, {int? id, bool root = false}) =>
      ui.navigate(screen, id: id, root: root);
  String get _incidentFilter => ui.incidentFilter;
  set _incidentFilter(String value) => ui.incidentFilter = value;

  set _historyForShipment(bool value) => ui.historyForShipment = value;

  @override
  Widget build(BuildContext context) {
    ui.buildContext = context;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: switch (ui.screen) {
        'alerts' => _alerts(),
        'incident' => _incidentDetail(),
        _ => const <Widget>[],
      },
    );
  }

  List<Widget> _alerts() {
    final activeFilter = _incidentFilter == 'Activas';
    final incidents =
        controller.incidents
            .where((item) => item.active == activeFilter)
            .toList()
          ..sort(
            (a, b) => (b.openedAt ?? DateTime(0)).compareTo(
              a.openedAt ?? DateTime(0),
            ),
          );
    return [
      SafeFlowSectionTitle(
        activeFilter ? 'Incidencias pendientes' : 'Historial de incidencias',
      ),
      SafeFlowFilterChips(
        values: const ['Activas', 'Historial'],
        selected: _incidentFilter,
        onSelected: (value) => setState(() => _incidentFilter = value),
      ),
      if (incidents.isEmpty)
        SafeFlowCallout(
          title: 'Sin incidencias ${_incidentFilter.toLowerCase()}',
          message:
              'Puedes consultar las incidencias atendidas desde Historial.',
        ),
      ...incidents.map((incident) {
        final product = controller.products
            .where((item) => item.id == incident.productId)
            .firstOrNull;
        return SafeFlowCard(
          title:
              '${incident.type == 'connectivity' ? 'Desconexión del sensor' : 'Anomalía térmica'} · #${incident.id}',
          subtitle:
              '${product?.name ?? 'Producto ${incident.productId}'} · ${incident.location} · ${dateLabel(incident.openedAt)}',
          value: readableStatus(incident.severity),
          detail: incident.active
              ? 'Activa · ${incident.repetitions} avisos agrupados'
              : 'Resuelta',
          icon: Icons.notifications_active_outlined,
          tone: toneForStatus(incident.severity),
          onTap: () => _open('incident', id: incident.id),
        );
      }),
    ];
  }

  List<Widget> _incidentDetail() {
    final incident = controller.incidents
        .where((item) => item.id == controller.selectedIncidentId)
        .firstOrNull;
    final product = controller.products
        .where((item) => item.id == incident?.productId)
        .firstOrNull;
    final reading =
        controller.readings
            .where(
              (item) =>
                  item.sensorId == incident?.sensorId &&
                  (incident == null ||
                      item.recordedAt == null ||
                      incident.lastSeenAt == null ||
                      !item.recordedAt!.isAfter(incident.lastSeenAt!)),
            )
            .toList()
          ..sort(
            (a, b) => (b.recordedAt ?? DateTime(0)).compareTo(
              a.recordedAt ?? DateTime(0),
            ),
          );
    if (incident == null) {
      return [
        const SafeFlowCallout(
          title: 'Incidencia no disponible',
          message: 'Regresa a la lista de alertas.',
        ),
      ];
    }
    final action = _field('incident.action');
    return [
      SafeFlowCard(
        title:
            '${incident.type == 'connectivity' ? 'Desconexión del sensor' : 'Excursión térmica'} · #${incident.id}',
        subtitle: '${product?.name ?? 'Producto'} · ${incident.location}',
        value: incident.type == 'connectivity'
            ? 'Sensor desconectado'
            : '${reading.firstOrNull?.temperature.toStringAsFixed(1) ?? '—'} °C',
        detail:
            '${readableStatus(incident.severity)} · ${incident.active ? 'Activa' : 'Resuelta'} · ${dateLabel(incident.openedAt)}',
        icon: Icons.warning_amber_rounded,
        tone: toneForStatus(incident.severity),
      ),
      Text(
        'Sensor ${incident.sensorId} · Rango del producto: ${product?.minimum ?? '—'}–${product?.maximum ?? '—'} °C',
      ),
      SafeFlowCallout(
        title: 'Avisos de la misma anomalía',
        message:
            '${incident.repetitions} avisos agrupados. La anomalía conserva una única alerta activa.',
      ),
      if (incident.active && controller.can('RESOLVE')) ...[
        SafeFlowInput(
          label: 'Acción correctiva',
          controller: action,
          helper: 'Describe la acción realizada antes de resolver.',
          maxLines: 3,
          onChanged: (_) => setState(() {}),
        ),
        FilledButton(
          onPressed: controller.busy || action.text.trim().isEmpty
              ? null
              : () => controller.resolveIncident(incident.id, action.text),
          child: controller.busy
              ? const CircularProgressIndicator()
              : const Text('Resolver alerta'),
        ),
      ],
      if (!incident.active)
        SafeFlowCallout(
          title: 'Acción correctiva registrada',
          message:
              '${incident.action ?? '—'}\n${incident.author ?? ''} · ${dateLabel(incident.resolvedAt)}',
          tone: SafeFlowTone.success,
        ),
      if (controller.can('RISKS'))
        OutlinedButton(
          onPressed: () {
            _historyForShipment = false;
            _open('history', id: incident.productId);
          },
          child: const Text('Consultar historial térmico'),
        ),
    ];
  }
}
