import 'package:flutter/material.dart';

import '../../../core/models/safeflow_models.dart';
import '../../workspace/application/workspace_controller.dart';
import '../../../core/widgets/safe_flow_widgets.dart';
import '../../workspace/presentation/workspace_ui_context.dart';

class ReportingWorkspaceSection extends StatelessWidget {
  const ReportingWorkspaceSection({super.key, required this.ui});
  final WorkspaceUiContext ui;
  BuildContext get context => ui.buildContext!;
  WorkspaceController get controller => ui.controller;
  void _open(String screen, {int? id, bool root = false}) =>
      ui.navigate(screen, id: id, root: root);

  @override
  Widget build(BuildContext context) {
    ui.buildContext = context;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: switch (ui.screen) {
        'summary' => _summary(),
        _ => const <Widget>[],
      },
    );
  }

  List<Widget> _summary() {
    final value = controller.summary;
    if (value == null) {
      return [
        const SafeFlowSectionTitle('Situación operativa'),
        const SafeFlowCallout(
          title: 'Sin actividad registrada',
          message:
              'Los indicadores se actualizarán al registrar productos, mediciones y despachos.',
        ),
      ];
    }
    return [
      const SafeFlowSectionTitle('Situación operativa'),
      if (controller.incidents.where((item) => item.active).isNotEmpty)
        _incidentNotice(controller.incidents.firstWhere((item) => item.active)),
      _summaryCard(
        'Productos registrados',
        'Información autorizada para ${controller.user?.role ?? ''}',
        '${value.products} productos',
        '${value.risks} requieren atención',
        Icons.inventory_2_outlined,
        SafeFlowTone.normal,
      ),
      _summaryCard(
        'Alertas activas',
        'Una alerta por anomalía; repeticiones agrupadas',
        '${value.activeIncidents} alertas',
        '${value.critical} críticas · ${value.warnings} advertencias',
        Icons.notifications_none_rounded,
        value.activeIncidents > 0 ? SafeFlowTone.warning : SafeFlowTone.normal,
      ),
      _summaryCard(
        'Despachos',
        'Información operativa autorizada',
        '${value.shipments} despachos',
        '${value.preparation} en preparación · ${value.inTransit} en tránsito · ${value.delivered} entregados',
        Icons.local_shipping_outlined,
        SafeFlowTone.normal,
      ),
      if (controller.can('RISKS'))
        OutlinedButton.icon(
          onPressed: () => _open('history'),
          icon: const Icon(Icons.show_chart_rounded),
          label: const Text('Consultar historial térmico'),
        ),
    ];
  }

  Widget _summaryCard(
    String title,
    String subtitle,
    String value,
    String detail,
    IconData icon,
    SafeFlowTone tone,
  ) => SafeFlowCard(
    title: title,
    subtitle: subtitle,
    value: value,
    detail: detail,
    icon: icon,
    tone: tone,
  );

  Widget _incidentNotice(SafeFlowIncident incident) => SafeFlowCallout(
    title: 'Aviso de anomalía térmica',
    message:
        '${incident.description} Consulta la incidencia para evaluar su atención.',
    tone: toneForStatus(incident.severity),
    onTap: () => _open('incident', id: incident.id),
  );
}
