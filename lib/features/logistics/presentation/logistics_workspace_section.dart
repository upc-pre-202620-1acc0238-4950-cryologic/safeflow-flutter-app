import 'package:flutter/material.dart';

import '../../../core/models/safeflow_models.dart';
import '../../workspace/application/workspace_controller.dart';
import '../../../core/widgets/safe_flow_widgets.dart';
import '../../workspace/presentation/workspace_ui_context.dart';

class LogisticsWorkspaceSection extends StatelessWidget {
  const LogisticsWorkspaceSection({super.key, required this.ui});
  final WorkspaceUiContext ui;
  BuildContext get context => ui.buildContext!;
  WorkspaceController get controller => ui.controller;
  void setState(VoidCallback action) => ui.update(action);
  TextEditingController _field(String key) => ui.field(key);
  void _open(String screen, {int? id, bool root = false}) =>
      ui.navigate(screen, id: id, root: root);
  String get _shipmentFilter => ui.shipmentFilter;
  set _shipmentFilter(String value) => ui.shipmentFilter = value;
  int? get _productId => ui.productId;
  set _productId(int? value) => ui.productId = value;
  int? get _lotId => ui.lotId;
  set _lotId(int? value) => ui.lotId = value;
  int? get _sensorId => ui.sensorId;
  set _sensorId(int? value) => ui.sensorId = value;
  void _back() => ui.back();
  bool get mounted => ui.isMounted();

  set _historyForShipment(bool value) => ui.historyForShipment = value;

  @override
  Widget build(BuildContext context) {
    ui.buildContext = context;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: switch (ui.screen) {
        'shipments' => _shipments(),
        'shipment-form' => _shipmentForm(),
        'shipment' => _shipmentDetail(),
        'validation' => _validation(),
        _ => const <Widget>[],
      },
    );
  }

  List<Widget> _shipments() {
    final visible =
        controller.shipments
            .where(
              (shipment) =>
                  _shipmentFilter == 'Todos' ||
                  (_shipmentFilter == 'En preparación' &&
                      shipment.status == 'PREPARATION') ||
                  (_shipmentFilter == 'En tránsito' &&
                      shipment.status == 'TRANSIT') ||
                  (_shipmentFilter == 'Entregados' &&
                      shipment.status == 'DELIVERED'),
            )
            .toList()
          ..sort(
            (a, b) => (b.createdAt ?? DateTime(0)).compareTo(
              a.createdAt ?? DateTime(0),
            ),
          );
    return [
      const SafeFlowSectionTitle('Despachos registrados'),
      SafeFlowFilterChips(
        values: const ['Todos', 'En preparación', 'En tránsito', 'Entregados'],
        selected: _shipmentFilter,
        onSelected: (value) => setState(() => _shipmentFilter = value),
      ),
      if (controller.can('CREATE_SHIPMENT'))
        FilledButton.icon(
          onPressed: () {
            _productId = null;
            _lotId = null;
            _sensorId = null;
            _open('shipment-form');
          },
          icon: const Icon(Icons.add_rounded),
          label: const Text('Registrar despacho'),
        ),
      if (visible.isEmpty)
        const SafeFlowCallout(
          title: 'Sin despachos',
          message: 'Los despachos registrados aparecerán aquí.',
        ),
      ...visible.map((shipment) {
        final product = controller.products
            .where((item) => item.id == shipment.productId)
            .firstOrNull;
        final lot = controller.lots
            .where((item) => item.id == shipment.lotId)
            .firstOrNull;
        final sensor = controller.sensors
            .where((item) => item.id == shipment.sensorId)
            .firstOrNull;
        final temperature =
            sensor?.latestReading?.temperature ?? shipment.temperature;
        return SafeFlowCard(
          title: product?.name ?? 'Producto ${shipment.productId}',
          subtitle:
              '${shipment.destination} · Lote ${lot?.code ?? shipment.lotId} · ${shipment.quantity} unidades',
          value: temperature == null
              ? readableStatus(shipment.status)
              : '${temperature.toStringAsFixed(1)} °C',
          detail:
              '${readableStatus(shipment.status)} · ${dateLabel(shipment.createdAt)}',
          icon: Icons.local_shipping_outlined,
          tone: toneForStatus(shipment.status),
          onTap: () => _open('shipment', id: shipment.id),
        );
      }),
    ];
  }

  List<Widget> _shipmentForm() {
    final destination = _field('shipment.destination');
    final quantity = _field('shipment.quantity');
    final product = controller.products
        .where((item) => item.id == _productId)
        .firstOrNull;
    final availableLots = controller.lots
        .where((lot) => lot.productId == _productId && lot.available > 0)
        .toList();
    final lot = availableLots.where((item) => item.id == _lotId).firstOrNull;
    final availableSensors = controller.sensors
        .where((item) => item.productId == _productId)
        .toList();
    final sensor = availableSensors
        .where((item) => item.id == _sensorId)
        .firstOrNull;
    final amount = int.tryParse(quantity.text);
    return [
      const SafeFlowSectionTitle('Datos del despacho'),
      Text('Producto', style: Theme.of(context).textTheme.titleMedium),
      DropdownButtonFormField<int>(
        key: ValueKey('shipment-product-$_productId'),
        initialValue: _productId,
        decoration: const InputDecoration(hintText: 'Selecciona un producto'),
        items: controller.products
            .map(
              (item) =>
                  DropdownMenuItem(value: item.id, child: Text(item.name)),
            )
            .toList(),
        onChanged: (value) => setState(() {
          _productId = value;
          _lotId = null;
          _sensorId = null;
        }),
      ),
      if (_productId != null) ...[
        Text('Lote', style: Theme.of(context).textTheme.titleMedium),
        DropdownButtonFormField<int>(
          key: ValueKey('shipment-lot-$_productId-$_lotId'),
          initialValue: _lotId,
          decoration: const InputDecoration(hintText: 'Selecciona un lote'),
          items: availableLots
              .map(
                (item) => DropdownMenuItem(
                  value: item.id,
                  child: Text(
                    'Lote ${item.code} · ${item.available} disponibles',
                  ),
                ),
              )
              .toList(),
          onChanged: (value) => setState(() => _lotId = value),
        ),
        if (availableLots.isEmpty)
          const SafeFlowCallout(
            title: 'Sin lotes disponibles',
            message:
                'Registra un lote e ingresa unidades antes de crear un despacho.',
          ),
        Text('Sensor', style: Theme.of(context).textTheme.titleMedium),
        DropdownButtonFormField<int>(
          key: ValueKey('shipment-sensor-$_productId-$_sensorId'),
          initialValue: _sensorId,
          decoration: const InputDecoration(hintText: 'Selecciona un sensor'),
          items: availableSensors
              .map(
                (item) => DropdownMenuItem(
                  value: item.id,
                  child: Text('Sensor ${item.id} · ${item.location}'),
                ),
              )
              .toList(),
          onChanged: (value) => setState(() => _sensorId = value),
        ),
        if (availableSensors.isEmpty)
          const SafeFlowCallout(
            title: 'Sin sensores',
            message: 'No hay sensores vinculados al producto.',
            tone: SafeFlowTone.warning,
          ),
      ],
      SafeFlowInput(
        label: 'Cantidad de unidades',
        controller: quantity,
        numeric: true,
        helper: lot == null
            ? 'Selecciona el lote antes de elegir una cantidad.'
            : '${lot.available} unidades disponibles en el lote.',
        onChanged: (_) => setState(() {}),
      ),
      SafeFlowInput(
        label: 'Destino',
        controller: destination,
        hint: 'Almacén o dirección de entrega',
        onChanged: (_) => setState(() {}),
      ),
      FilledButton(
        onPressed:
            controller.busy ||
                product == null ||
                lot == null ||
                sensor == null ||
                amount == null ||
                amount <= 0 ||
                amount > lot.available ||
                destination.text.trim().isEmpty
            ? null
            : () async {
                await controller.createShipment(
                  productId: product.id,
                  lotId: lot.id,
                  quantity: amount,
                  destination: destination.text,
                  sensorId: sensor.id,
                );
                if (mounted &&
                    controller.error == null &&
                    controller.selectedShipmentId != null) {
                  destination.clear();
                  quantity.clear();
                  _open(
                    'shipment',
                    id: controller.selectedShipmentId,
                    root: true,
                  );
                }
              },
        child: controller.busy
            ? const CircularProgressIndicator()
            : const Text('Registrar despacho'),
      ),
      OutlinedButton(onPressed: _back, child: const Text('Cancelar')),
    ];
  }

  List<Widget> _shipmentDetail() {
    final shipment = controller.shipments
        .where((item) => item.id == controller.selectedShipmentId)
        .firstOrNull;
    if (shipment == null) {
      return [
        const SafeFlowCallout(
          title: 'Despacho no disponible',
          message: 'Regresa a la lista de despachos.',
        ),
      ];
    }
    final product = controller.products
        .where((item) => item.id == shipment.productId)
        .firstOrNull;
    final lot = controller.lots
        .where((item) => item.id == shipment.lotId)
        .firstOrNull;
    final sensor = controller.sensors
        .where((item) => item.id == shipment.sensorId)
        .firstOrNull;
    return [
      SafeFlowCard(
        title: product?.name ?? 'Producto ${shipment.productId}',
        subtitle:
            '${shipment.destination} · Lote ${lot?.code ?? shipment.lotId}',
        value: '${shipment.quantity} unidades',
        detail:
            '${readableStatus(shipment.status)} · Sensor ${shipment.sensorId} · ${dateLabel(shipment.createdAt)}',
        icon: Icons.local_shipping_outlined,
        tone: toneForStatus(shipment.status),
      ),
      SafeFlowCard(
        title: 'Temperatura del sensor',
        value: sensor?.latestReading == null
            ? 'Sin lecturas'
            : '${sensor!.latestReading!.temperature.toStringAsFixed(1)} °C',
        detail:
            '${sensor?.location ?? 'Sensor ${shipment.sensorId}'} · ${readableStatus(sensor?.condition ?? 'UNKNOWN')}',
        icon: Icons.thermostat_outlined,
        tone: toneForStatus(sensor?.condition ?? 'UNKNOWN'),
      ),
      if (shipment.status == 'PREPARATION' && controller.can('READ_SHIPMENTS'))
        FilledButton(
          onPressed: () => _open('validation', id: shipment.id),
          child: const Text('Consultar validación del despacho'),
        ),
      if (shipment.status == 'TRANSIT' && controller.can('DELIVER'))
        FilledButton(
          onPressed: () => _confirmDelivery(shipment),
          child: const Text('Confirmar entrega'),
        ),
      OutlinedButton(
        onPressed: () {
          _historyForShipment = true;
          _open('history', id: shipment.id);
        },
        child: const Text('Consultar historial térmico del despacho'),
      ),
    ];
  }

  Future<void> _confirmDelivery(SafeFlowShipment shipment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar entrega'),
        content: Text(
          '¿Confirmas la entrega del despacho a ${shipment.destination}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    if (confirmed == true) await controller.deliverShipment(shipment.id);
  }

  List<Widget> _validation() {
    final shipment = controller.shipments
        .where((item) => item.id == controller.selectedShipmentId)
        .firstOrNull;
    final validation = controller.shipmentValidation;
    if (shipment == null) {
      return [
        const SafeFlowCallout(
          title: 'Despacho no disponible',
          message: 'Regresa a la lista de despachos.',
        ),
      ];
    }
    if (validation == null) {
      return [
        const SafeFlowCallout(
          title: 'Validando despacho',
          message: 'Consultando sensor y rango térmico.',
        ),
        const Center(child: CircularProgressIndicator()),
      ];
    }
    final latest = validation['latestValidReading'] == null
        ? null
        : SafeFlowReading.fromJson(asJsonMap(validation['latestValidReading']));
    final canDepart = validation['canDepart'] == true;
    final requiresRiskConfirmation =
        validation['requiresRiskConfirmation'] == true;
    final connected = validation['sensorConnected'] == true;
    return [
      SafeFlowCard(
        title: 'Estado del sensor',
        value: connected ? 'Conectado' : 'Desconectado',
        detail: latest == null
            ? 'No hay una medición válida reciente.'
            : '${latest.temperature.toStringAsFixed(1)} °C · ${dateLabel(latest.recordedAt)}',
        icon: Icons.sensors_outlined,
        tone: connected
            ? toneForStatus(validation['condition']?.toString() ?? '')
            : SafeFlowTone.critical,
      ),
      if (validation['blockedReason'] != null)
        SafeFlowCallout(
          title: 'Despacho bloqueado',
          message: validation['blockedReason'].toString(),
          tone: SafeFlowTone.critical,
        ),
      if (!canDepart && requiresRiskConfirmation)
        SafeFlowCallout(
          title: 'Confirmación de riesgo requerida',
          message:
              'La lectura térmica está fuera del rango. Confirma que deseas asumir el riesgo antes de iniciar el tránsito.',
          tone: SafeFlowTone.warning,
        ),
      if (canDepart && controller.can('READ_SHIPMENTS'))
        FilledButton(
          onPressed: controller.busy
              ? null
              : () async {
                  await controller.departShipment(shipment.id);
                  if (mounted && controller.error == null) {
                    _open('shipment', id: shipment.id, root: true);
                  }
                },
          child: const Text('Iniciar tránsito'),
        ),
      if (requiresRiskConfirmation && controller.can('READ_SHIPMENTS'))
        FilledButton.tonal(
          onPressed: controller.busy
              ? null
              : () async {
                  await controller.departShipment(
                    shipment.id,
                    acceptRisk: true,
                  );
                  if (mounted && controller.error == null) {
                    _open('shipment', id: shipment.id, root: true);
                  }
                },
          child: const Text('Confirmar riesgo e iniciar tránsito'),
        ),
      OutlinedButton(onPressed: _back, child: const Text('Volver al despacho')),
    ];
  }
}
