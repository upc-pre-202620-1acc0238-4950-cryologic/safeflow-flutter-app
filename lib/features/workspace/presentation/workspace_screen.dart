import 'package:flutter/material.dart';

import '../../../core/models/safeflow_models.dart';
import '../../../core/widgets/safe_flow_widgets.dart';
import '../../alerts/presentation/alerts_workspace_section.dart';
import '../../iam/presentation/iam_workspace_section.dart';
import '../../inventory/presentation/inventory_workspace_section.dart';
import '../../logistics/presentation/logistics_workspace_section.dart';
import '../../monitoring/presentation/monitoring_workspace_section.dart';
import '../../reporting/presentation/reporting_workspace_section.dart';
import '../application/workspace_controller.dart';
import 'workspace_ui_context.dart';

class _Operation {
  const _Operation(this.id, this.label, this.icon, this.permission);
  final String id;
  final String label;
  final IconData icon;
  final String? permission;
}

const _operations = [
  _Operation('summary', 'Resumen', Icons.dashboard_outlined, 'SUMMARY'),
  _Operation(
    'inventory',
    'Inventario',
    Icons.inventory_2_outlined,
    'READ_INVENTORY',
  ),
  _Operation('risks', 'Riesgos', Icons.warning_amber_rounded, 'RISKS'),
  _Operation('alerts', 'Alertas', Icons.notifications_none_rounded, 'ALERTS'),
  _Operation(
    'shipments',
    'Despachos',
    Icons.local_shipping_outlined,
    'READ_SHIPMENTS',
  ),
  _Operation('permissions', 'Permisos', Icons.manage_accounts_outlined, null),
];

class SafeFlowWorkspaceScreen extends StatefulWidget {
  const SafeFlowWorkspaceScreen({super.key, required this.controller});
  final WorkspaceController controller;

  @override
  State<SafeFlowWorkspaceScreen> createState() =>
      _SafeFlowWorkspaceScreenState();
}

class _SafeFlowWorkspaceScreenState extends State<SafeFlowWorkspaceScreen> {
  final List<(String, int?)> _history = [];
  final Map<String, TextEditingController> _fields = {};

  WorkspaceController get controller => widget.controller;
  late final WorkspaceUiContext _ui = WorkspaceUiContext(
    controller: controller,
    screen: 'summary',
    update: (action) => setState(action),
    navigate: _open,
    field: _field,
    loadRole: _loadRole,
    back: _back,
    isMounted: () => mounted,
  );

  TextEditingController _field(String key) =>
      _fields.putIfAbsent(key, TextEditingController.new);

  @override
  void initState() {
    super.initState();
    _ui.screen = _homeFor(controller.user?.role, controller.permissions);
  }

  @override
  void dispose() {
    for (final field in _fields.values) {
      field.dispose();
    }
    super.dispose();
  }

  String _homeFor(String? role, Set<String> permissions) {
    if (role == 'ADMIN') return 'permissions';
    if (permissions.contains('SUMMARY')) return 'summary';
    if (permissions.contains('READ_INVENTORY') ||
        permissions.contains('WRITE_INVENTORY')) {
      return 'inventory';
    }
    if (permissions.contains('RISKS')) return 'risks';
    if (permissions.contains('ALERTS') || permissions.contains('RESOLVE')) {
      return 'alerts';
    }
    if (permissions.contains('READ_SHIPMENTS') ||
        permissions.contains('CREATE_SHIPMENT') ||
        permissions.contains('DELIVER')) {
      return 'shipments';
    }
    return 'account';
  }

  List<_Operation> get _availableOperations => _operations.where((operation) {
    if (operation.id == 'permissions') return controller.isAdmin;
    final permission = operation.permission;
    if (permission != null && controller.can(permission)) return true;
    return switch (operation.id) {
      'inventory' => controller.can('WRITE_INVENTORY'),
      'alerts' => controller.can('RESOLVE'),
      'shipments' =>
        controller.can('CREATE_SHIPMENT') || controller.can('DELIVER'),
      _ => false,
    };
  }).toList();

  List<_Operation> get _navOperations => _availableOperations.take(3).toList();

  String get _title => switch (_ui.screen) {
    'summary' => 'Resumen',
    'inventory' => 'Inventario',
    'product-form' => 'Registrar producto',
    'product' => 'Detalle de producto',
    'lot-form' => 'Registrar lote',
    'lot' => 'Lote',
    'income-form' => 'Registrar ingreso',
    'risks' => 'Productos en riesgo',
    'history' => 'Historial térmico',
    'alerts' => 'Alertas',
    'incident' => 'Detalle de incidente',
    'shipments' => 'Despachos',
    'shipment-form' => 'Registrar despacho',
    'shipment' => 'Detalle de despacho',
    'validation' => 'Validación del despacho',
    'account' => 'Cuenta',
    'permissions' => 'Permisos por rol',
    _ => 'SafeFlow',
  };

  bool get _isRoot =>
      _availableOperations.any((item) => item.id == _ui.screen) ||
      _ui.screen == 'account' ||
      _ui.screen == 'permissions';

  void _open(String screen, {int? id, bool root = false}) {
    if (root) _history.clear();
    if (!root) _history.add((_ui.screen, controller.selectedProductId));
    setState(() {
      _ui.screen = screen;
      _ui.filter = 'Todos';
    });
    if (screen == 'history') {
      controller.selectedProductId = _ui.historyForShipment
          ? controller.shipments
                .where((item) => item.id == id)
                .firstOrNull
                ?.productId
          : id;
      controller.loadHistory(
        productId: _ui.historyForShipment ? null : id,
        shipmentId: _ui.historyForShipment ? id : null,
      );
    }
    if (screen == 'product') {
      controller.selectedProductId = id;
      _ui.historyForShipment = false;
    }
    if (screen == 'incident') controller.selectedIncidentId = id;
    if (screen == 'shipment') controller.selectedShipmentId = id;
    if (screen == 'validation' && id != null) controller.validateShipment(id);
    if (screen == 'permissions' && controller.roles.isNotEmpty) {
      _loadRole(controller.roles.first);
    }
  }

  void _back() {
    if (_history.isEmpty) {
      _open(
        _homeFor(controller.user?.role, controller.permissions),
        root: true,
      );
      return;
    }
    final previous = _history.removeLast();
    setState(() => _ui.screen = previous.$1);
    controller.selectedProductId = previous.$2;
  }

  void _loadRole(JsonMap role) {
    _ui.selectedRole = asString(role['role']);
    _ui.selectedPermissions
      ..clear()
      ..addAll(asJsonList(role['granted']).map((value) => value.toString()));
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) => Scaffold(
      appBar: AppBar(
        leading: !_isRoot
            ? IconButton(
                onPressed: _back,
                tooltip: 'Volver',
                icon: const Icon(Icons.arrow_back_rounded),
              )
            : null,
        title: Text(_title),
        actions: [
          if (_ui.screen != 'account')
            IconButton(
              onPressed: () => _open('account'),
              tooltip: 'Cuenta',
              icon: const Icon(Icons.account_circle_outlined),
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: controller.loading
          ? const Center(child: CircularProgressIndicator())
          : _content(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedNavIndex(),
        onDestinationSelected: (index) {
          final nav = [
            ..._navOperations,
            const _Operation(
              'account',
              'Cuenta',
              Icons.account_circle_outlined,
              null,
            ),
          ];
          _open(nav[index].id, root: true);
        },
        destinations: [
          for (final operation in _navOperations)
            NavigationDestination(
              icon: Icon(operation.icon),
              selectedIcon: Icon(operation.icon),
              label: operation.label,
            ),
          const NavigationDestination(
            icon: Icon(Icons.account_circle_outlined),
            selectedIcon: Icon(Icons.account_circle_rounded),
            label: 'Cuenta',
          ),
        ],
      ),
    ),
  );

  int _selectedNavIndex() {
    final nav = _navOperations;
    final parent = switch (_ui.screen) {
      'product' ||
      'product-form' ||
      'lot' ||
      'lot-form' ||
      'income-form' => 'inventory',
      'incident' => 'alerts',
      'shipment' || 'shipment-form' || 'validation' => 'shipments',
      'history' =>
        controller.user?.role == 'SUPERVISOR' ? 'risks' : 'inventory',
      _ => _ui.screen,
    };
    final index = nav.indexWhere((item) => item.id == parent);
    return index < 0 ? nav.length : index;
  }

  Widget _content() {
    final children = <Widget>[];
    if (controller.error != null) {
      children.add(
        SafeFlowCallout(
          title: 'Información de la operación',
          message: controller.error!,
          tone: SafeFlowTone.critical,
        ),
      );
    }
    if (controller.notice != null) {
      children.add(
        SafeFlowCallout(
          title: 'Operación completada',
          message: controller.notice!,
          tone: SafeFlowTone.success,
        ),
      );
    }
    children.add(_screenContent());
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: children.length,
          separatorBuilder: (_, _) => const SizedBox(height: 16),
          itemBuilder: (_, index) => children[index],
        ),
      ),
    );
  }

  Widget _screenContent() => switch (_ui.screen) {
    'summary' => ReportingWorkspaceSection(ui: _ui),
    'inventory' ||
    'product-form' ||
    'product' ||
    'lot-form' ||
    'lot' ||
    'income-form' => InventoryWorkspaceSection(ui: _ui),
    'risks' || 'history' => MonitoringWorkspaceSection(ui: _ui),
    'alerts' || 'incident' => AlertsWorkspaceSection(ui: _ui),
    'shipments' ||
    'shipment-form' ||
    'shipment' ||
    'validation' => LogisticsWorkspaceSection(ui: _ui),
    'account' || 'permissions' => IamWorkspaceSection(ui: _ui),
    _ => const SafeFlowCallout(
      title: 'Pantalla no disponible',
      message: 'Regresa al módulo anterior.',
    ),
  };
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
