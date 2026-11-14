import 'package:flutter/material.dart';

import '../../../core/models/safeflow_models.dart';
import '../../workspace/application/workspace_controller.dart';
import '../../../core/widgets/safe_flow_widgets.dart';
import '../../workspace/presentation/workspace_ui_context.dart';
import 'thermal_chart.dart';

class MonitoringWorkspaceSection extends StatelessWidget {
  const MonitoringWorkspaceSection({super.key, required this.ui});
  final WorkspaceUiContext ui;
  BuildContext get context => ui.buildContext!;
  WorkspaceController get controller => ui.controller;
  void _open(String screen, {int? id, bool root = false}) =>
      ui.navigate(screen, id: id, root: root);
  bool get _historyForShipment => ui.historyForShipment;
  set _historyForShipment(bool value) => ui.historyForShipment = value;

  @override
  Widget build(BuildContext context) {
    ui.buildContext = context;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: switch (ui.screen) {
        'risks' => _risks(),
        'history' => _historyPage(),
        _ => const <Widget>[],
      },
    );
  }

  List<Widget> _risks() {
    final values = controller.risks;
    return [
      const SafeFlowSectionTitle('Productos en riesgo'),
      if (values.isEmpty)
        const SafeFlowCallout(
          title: 'Sin productos en riesgo',
          message: 'Los productos con lecturas fuera de rango aparecerán aquí.',
        ),
      ...values.map((risk) {
        final product = controller.products
            .where((item) => item.id == risk.productId)
            .firstOrNull;
        final sensor = controller.sensors
            .where((item) => item.id == risk.sensorId)
            .firstOrNull;
        return SafeFlowCard(
          title: product?.name ?? 'Producto ${risk.productId}',
          subtitle: sensor?.location ?? 'Sensor ${risk.sensorId}',
          value: risk.temperature == null
              ? readableStatus(risk.condition)
              : '${risk.temperature!.toStringAsFixed(1)} °C',
          detail:
              '${readableStatus(risk.condition)} · ${dateLabel(risk.recordedAt)}${product == null ? '' : ' · Rango ${product.minimum}–${product.maximum} °C'}',
          icon: Icons.warning_amber_rounded,
          tone: toneForStatus(risk.condition),
          onTap: () {
            _historyForShipment = false;
            _open('history', id: risk.productId);
          },
        );
      }),
      if (controller.products.isEmpty && controller.sensors.isEmpty)
        const SafeFlowCallout(
          title: 'Sin historial disponible',
          message: 'Todavía no hay productos con historial térmico.',
        ),
      OutlinedButton.icon(
        onPressed: () => _open('history', root: false),
        icon: const Icon(Icons.show_chart_rounded),
        label: const Text('Consultar historial de productos'),
      ),
    ];
  }

  List<Widget> _historyPage() {
    if (controller.selectedProductId == null && !_historyForShipment) {
      final products = controller.products;
      return [
        const SafeFlowSectionTitle('Historial de productos'),
        if (products.isEmpty)
          const SafeFlowCallout(
            title: 'Sin productos',
            message: 'Todavía no hay productos con historial térmico.',
          ),
        ...products.map(
          (product) => SafeFlowCard(
            title: product.name,
            subtitle: 'Producto ${product.id}',
            value: 'Consultar temperaturas',
            icon: Icons.show_chart_rounded,
            onTap: () {
              _historyForShipment = false;
              _open('history', id: product.id);
            },
          ),
        ),
      ];
    }
    final product = controller.products
        .where((item) => item.id == controller.selectedProductId)
        .firstOrNull;
    final values = [...controller.history]
      ..sort(
        (a, b) => (a.recordedAt ?? DateTime(0)).compareTo(
          b.recordedAt ?? DateTime(0),
        ),
      );
    final rejected = controller.rejections
        .where((item) => item['sensorId'] == values.firstOrNull?.sensorId)
        .toList();
    return [
      SafeFlowSectionTitle(product?.name ?? 'Historial de temperaturas'),
      const SafeFlowCallout(
        title: 'Últimos 7 días',
        message: 'Las mediciones se consultan directamente desde el backend.',
      ),
      if (values.isEmpty)
        const SafeFlowCallout(
          title: 'Sin lecturas',
          message: 'No hay mediciones en el periodo seleccionado.',
        ),
      if (values.isNotEmpty) ...[
        SafeFlowCard(
          title: 'Temperaturas registradas',
          subtitle:
              '${values.length} lecturas · ${dateLabel(values.first.recordedAt)} a ${dateLabel(values.last.recordedAt)}',
          child: SizedBox(
            height: 210,
            width: double.infinity,
            child: CustomPaint(
              painter: SafeFlowThermalChartPainter(
                values,
                minimum: product?.minimum,
                maximum: product?.maximum,
              ),
            ),
          ),
        ),
        const SafeFlowSectionTitle('Mediciones'),
        ...values.reversed
            .take(40)
            .map(
              (reading) => SafeFlowCard(
                title:
                    '${reading.temperature.toStringAsFixed(1)} °C · ${readableStatus(reading.condition)}',
                subtitle:
                    'Sensor ${reading.sensorId} · ${dateLabel(reading.recordedAt)}',
                icon: Icons.thermostat_outlined,
                tone: toneForStatus(reading.condition),
              ),
            ),
      ],
      if (rejected.isNotEmpty) ...[
        const SafeFlowSectionTitle('Lecturas rechazadas'),
        ...rejected.map(
          (item) => SafeFlowCallout(
            title: 'Medición rechazada',
            message:
                '${item['reason'] ?? 'Sin motivo'} · ${dateLabel(asDateTime(item['recordedAt']))}',
            tone: SafeFlowTone.warning,
          ),
        ),
      ],
    ];
  }
}
