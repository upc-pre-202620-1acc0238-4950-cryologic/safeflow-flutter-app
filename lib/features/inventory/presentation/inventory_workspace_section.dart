import 'package:flutter/material.dart';

import '../../workspace/application/workspace_controller.dart';
import '../../../core/widgets/safe_flow_widgets.dart';
import '../../workspace/presentation/workspace_ui_context.dart';

class InventoryWorkspaceSection extends StatelessWidget {
  const InventoryWorkspaceSection({super.key, required this.ui});
  final WorkspaceUiContext ui;
  BuildContext get context => ui.buildContext!;
  WorkspaceController get controller => ui.controller;
  void setState(VoidCallback action) => ui.update(action);
  TextEditingController _field(String key) => ui.field(key);
  void _open(String screen, {int? id, bool root = false}) =>
      ui.navigate(screen, id: id, root: root);
  String get _filter => ui.filter;
  set _filter(String value) => ui.filter = value;
  int? get _lotId => ui.lotId;
  set _lotId(int? value) => ui.lotId = value;
  void _back() => ui.back();
  bool get mounted => ui.isMounted();

  set _historyForShipment(bool value) => ui.historyForShipment = value;

  @override
  Widget build(BuildContext context) {
    ui.buildContext = context;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: switch (ui.screen) {
        'inventory' => _inventory(),
        'product-form' => _productForm(),
        'product' => _productDetail(),
        'lot-form' => _lotForm(),
        'lot' => _lotDetail(),
        'income-form' => _incomeForm(),
        _ => const <Widget>[],
      },
    );
  }

  List<Widget> _inventory() {
    final write = controller.can('WRITE_INVENTORY');
    final products = controller.products.where((product) {
      final sensor = controller.sensors
          .where((item) => item.productId == product.id)
          .firstOrNull;
      final status = sensor?.condition ?? 'UNKNOWN';
      if (_filter == 'Normal') {
        return status == 'NORMAL';
      }
      if (_filter == 'En riesgo') {
        return {'WARNING', 'RISK', 'CRITICAL', 'DISCONNECTED'}.contains(status);
      }
      return true;
    }).toList();
    return [
      const SafeFlowSectionTitle('Productos registrados'),
      SafeFlowFilterChips(
        values: const ['Todos', 'Normal', 'En riesgo'],
        selected: _filter,
        onSelected: (value) => setState(() => _filter = value),
      ),
      if (write)
        FilledButton.icon(
          onPressed: () => _open('product-form'),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Registrar producto'),
        ),
      if (products.isEmpty)
        SafeFlowCallout(
          title: 'Sin productos',
          message: controller.products.isEmpty
              ? 'Registra un producto para comenzar a controlar tu inventario.'
              : 'No hay productos que coincidan con el estado seleccionado.',
        ),
      ...products.map((product) {
        final productLots = controller.lots.where(
          (lot) => lot.productId == product.id,
        );
        final sensor = controller.sensors
            .where((item) => item.productId == product.id)
            .firstOrNull;
        final temperature = sensor?.latestReading?.temperature;
        return SafeFlowCard(
          title: product.name,
          subtitle:
              'Producto ${product.id} · ${productLots.fold<int>(0, (sum, lot) => sum + lot.stock)} unidades',
          value: temperature == null
              ? 'Sin temperatura'
              : '${temperature.toStringAsFixed(1)} °C',
          detail:
              '${readableStatus(sensor?.condition ?? 'UNKNOWN')} · Rango del producto: ${product.minimum}–${product.maximum} °C',
          icon: Icons.inventory_2_outlined,
          tone: toneForStatus(sensor?.condition ?? 'UNKNOWN'),
          onTap: () => _open('product', id: product.id),
        );
      }),
    ];
  }

  List<Widget> _productForm() {
    final name = _field('product.name');
    final minimum = _field('product.minimum');
    final maximum = _field('product.maximum');
    final min = double.tryParse(minimum.text);
    final max = double.tryParse(maximum.text);
    return [
      const SafeFlowSectionTitle('Datos del producto'),
      SafeFlowInput(
        label: 'Nombre del producto',
        controller: name,
        hint: 'Ej. Vacunas',
        helper: 'Requerido',
        onChanged: (_) => setState(() {}),
      ),
      SafeFlowInput(
        label: 'Temperatura mínima (°C)',
        controller: minimum,
        numeric: true,
        hint: '-2',
        helper: 'Requerido',
        onChanged: (_) => setState(() {}),
      ),
      SafeFlowInput(
        label: 'Temperatura máxima (°C)',
        controller: maximum,
        numeric: true,
        hint: '8',
        helper: 'Requerido',
        onChanged: (_) => setState(() {}),
      ),
      FilledButton(
        onPressed:
            controller.busy ||
                name.text.trim().isEmpty ||
                min == null ||
                max == null ||
                min > max
            ? null
            : () async {
                await controller.createProduct(
                  name: name.text,
                  minimum: minimum.text,
                  maximum: maximum.text,
                );
                if (mounted && controller.selectedProductId != null) {
                  final id = controller.selectedProductId;
                  name.clear();
                  minimum.clear();
                  maximum.clear();
                  _open('product', id: id, root: true);
                }
              },
        child: controller.busy
            ? const CircularProgressIndicator()
            : const Text('Registrar producto'),
      ),
      OutlinedButton(onPressed: _back, child: const Text('Cancelar')),
    ];
  }

  List<Widget> _productDetail() {
    final product = controller.products
        .where((item) => item.id == controller.selectedProductId)
        .firstOrNull;
    if (product == null) {
      return [
        const SafeFlowCallout(
          title: 'Producto no disponible',
          message: 'Regresa al inventario.',
        ),
      ];
    }
    final productLots = controller.lots
        .where((lot) => lot.productId == product.id)
        .toList();
    final productSensors = controller.sensors
        .where((sensor) => sensor.productId == product.id)
        .toList();
    final sensorIds = productSensors.map((sensor) => sensor.id).toSet();
    final productReadings =
        controller.readings
            .where((reading) => sensorIds.contains(reading.sensorId))
            .toList()
          ..sort(
            (a, b) => (b.recordedAt ?? DateTime(0)).compareTo(
              a.recordedAt ?? DateTime(0),
            ),
          );
    final latest = productReadings.firstOrNull;
    final condition =
        productSensors.map((sensor) => sensor.condition).firstOrNull ??
        'UNKNOWN';
    return [
      SafeFlowCard(
        title: product.name,
        subtitle:
            '${product.id} · ${product.stock} unidades · ${product.available} disponibles · ${product.reserved} reservadas · Rango: ${product.minimum}–${product.maximum} °C',
        value: latest == null
            ? 'Sin temperatura'
            : '${latest.temperature.toStringAsFixed(1)} °C',
        detail:
            '${readableStatus(condition)} · ${dateLabel(latest?.recordedAt)}',
        icon: Icons.inventory_2_outlined,
        tone: toneForStatus(condition),
      ),
      if (productSensors.isNotEmpty)
        const SafeFlowCallout(
          title: 'Lectura actualizada',
          message:
              'La temperatura se recibe automáticamente del sensor. No requiere transcripción manual.',
          tone: SafeFlowTone.success,
        )
      else
        const SafeFlowCallout(
          title: 'Sin sensor vinculado',
          message: 'No hay lecturas de temperatura para este producto.',
        ),
      if (controller.can('WRITE_INVENTORY')) ...[
        OutlinedButton.icon(
          onPressed: () => _open('lot-form'),
          icon: const Icon(Icons.add_box_outlined),
          label: const Text('Registrar lote'),
        ),
        OutlinedButton.icon(
          onPressed: () => _open('income-form'),
          icon: const Icon(Icons.add_shopping_cart_outlined),
          label: const Text('Registrar ingreso'),
        ),
      ],
      const SafeFlowSectionTitle('Lotes del producto'),
      if (productLots.isEmpty)
        const SafeFlowCallout(
          title: 'Sin lotes',
          message:
              'Registra un lote para identificar los productos que despacharás.',
        ),
      ...productLots.map(
        (lot) => SafeFlowCard(
          title: 'Lote ${lot.code}',
          subtitle: '${lot.stock} unidades',
          value: '${lot.available} disponibles',
          detail: '${lot.reserved} reservadas',
          icon: Icons.inventory_2_outlined,
          onTap: () {
            controller.selectedLotId = lot.id;
            _open('lot', id: lot.id);
          },
        ),
      ),
      OutlinedButton.icon(
        onPressed: () {
          _historyForShipment = false;
          _open('history', id: product.id);
        },
        icon: const Icon(Icons.show_chart_rounded),
        label: const Text('Consultar historial térmico'),
      ),
    ];
  }

  List<Widget> _lotForm() {
    final product = controller.products
        .where((item) => item.id == controller.selectedProductId)
        .firstOrNull;
    final code = _field('lot.code');
    final exists = controller.lots
        .where(
          (lot) =>
              lot.productId == product?.id &&
              lot.code.toLowerCase() == code.text.trim().toLowerCase(),
        )
        .firstOrNull;
    return [
      if (product != null)
        SafeFlowCard(
          title: product.name,
          subtitle: 'Producto ${product.id}',
          value: '${product.minimum}–${product.maximum} °C',
          detail: 'Producto asociado',
          icon: Icons.inventory_2_outlined,
        ),
      SafeFlowInput(
        label: 'Identificación del lote',
        controller: code,
        helper: 'Requerido',
        hint: 'Ej. LOT-2026-001',
        onChanged: (_) => setState(() {}),
      ),
      if (exists != null) ...[
        SafeFlowCard(
          title: 'Lote ${exists.code}',
          subtitle: '${exists.stock} unidades',
          value: '${exists.available} disponibles',
          detail: '${exists.reserved} reservadas',
          icon: Icons.inventory_2_outlined,
        ),
        OutlinedButton(
          onPressed: () {
            controller.selectedLotId = exists.id;
            _open('lot', id: exists.id);
          },
          child: const Text('Consultar lote existente'),
        ),
      ],
      FilledButton(
        onPressed:
            controller.busy ||
                product == null ||
                code.text.trim().isEmpty ||
                exists != null
            ? null
            : () async {
                await controller.createLot(product.id, code.text);
                if (mounted && controller.error == null) {
                  code.clear();
                  await controller.refreshWorkspace();
                  _back();
                }
              },
        child: controller.busy
            ? const CircularProgressIndicator()
            : const Text('Registrar lote'),
      ),
      OutlinedButton(onPressed: _back, child: const Text('Cancelar')),
    ];
  }

  List<Widget> _lotDetail() {
    final lot = controller.lots
        .where((item) => item.id == controller.selectedLotId)
        .firstOrNull;
    final product = controller.products
        .where((item) => item.id == lot?.productId)
        .firstOrNull;
    if (lot == null || product == null) {
      return [
        const SafeFlowCallout(
          title: 'Lote no disponible',
          message: 'Regresa al producto asociado.',
        ),
      ];
    }
    return [
      SafeFlowCard(
        title: 'Lote ${lot.code}',
        subtitle: product.name,
        value: '${lot.stock} unidades',
        detail: '${lot.available} disponibles · ${lot.reserved} reservadas',
        icon: Icons.inventory_2_outlined,
      ),
      Text('Rango del producto: ${product.minimum}–${product.maximum} °C'),
      if (controller.can('WRITE_INVENTORY'))
        FilledButton(
          onPressed: () => _open('income-form'),
          child: const Text('Registrar ingreso'),
        ),
      OutlinedButton(onPressed: _back, child: const Text('Volver al producto')),
    ];
  }

  List<Widget> _incomeForm() {
    final product = controller.products
        .where((item) => item.id == controller.selectedProductId)
        .firstOrNull;
    final productLots = controller.lots
        .where((lot) => lot.productId == product?.id)
        .toList();
    final quantity = _field('income.quantity');
    _lotId ??= productLots.isNotEmpty ? productLots.first.id : null;
    final selectedLot = productLots
        .where((lot) => lot.id == _lotId)
        .firstOrNull;
    final amount = int.tryParse(quantity.text);
    return [
      if (product != null)
        SafeFlowCard(
          title: product.name,
          subtitle: 'Producto ${product.id}',
          value: '${product.stock} unidades',
          detail: 'Stock total del producto',
          icon: Icons.inventory_2_outlined,
        ),
      if (productLots.isEmpty)
        const SafeFlowCallout(
          title: 'Sin lotes',
          message: 'Registra un lote antes de registrar un ingreso.',
        ),
      if (productLots.isNotEmpty) ...[
        Text(
          'Lote del ingreso',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        DropdownButtonFormField<int>(
          key: ValueKey('income-lot-$_lotId'),
          initialValue: _lotId,
          decoration: const InputDecoration(),
          items: productLots
              .map(
                (lot) => DropdownMenuItem(
                  value: lot.id,
                  child: Text('Lote ${lot.code}'),
                ),
              )
              .toList(),
          onChanged: (value) => setState(() => _lotId = value),
        ),
      ],
      if (selectedLot != null)
        SafeFlowCard(
          title: 'Lote ${selectedLot.code}',
          subtitle: 'Stock antes del ingreso',
          value: '${selectedLot.stock} unidades',
          detail:
              '${selectedLot.available} disponibles · ${selectedLot.reserved} reservadas',
          icon: Icons.inventory_2_outlined,
        ),
      SafeFlowInput(
        label: 'Cantidad de unidades',
        controller: quantity,
        numeric: true,
        helper: 'Ingresa una cantidad positiva.',
        onChanged: (_) => setState(() {}),
      ),
      FilledButton(
        onPressed:
            controller.busy ||
                selectedLot == null ||
                amount == null ||
                amount <= 0
            ? null
            : () async {
                await controller.recordIncome(selectedLot.id, quantity.text);
                if (mounted && controller.error == null) {
                  quantity.clear();
                  _back();
                }
              },
        child: controller.busy
            ? const CircularProgressIndicator()
            : const Text('Registrar ingreso'),
      ),
      OutlinedButton(onPressed: _back, child: const Text('Cancelar')),
    ];
  }
}
