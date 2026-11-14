import 'package:flutter/material.dart';

import '../../../core/models/safeflow_models.dart';
import '../../workspace/application/workspace_controller.dart';
import '../../../core/widgets/safe_flow_widgets.dart';
import '../../workspace/presentation/workspace_ui_context.dart';

class IamWorkspaceSection extends StatelessWidget {
  const IamWorkspaceSection({super.key, required this.ui});
  final WorkspaceUiContext ui;
  BuildContext get context => ui.buildContext!;
  WorkspaceController get controller => ui.controller;
  void setState(VoidCallback action) => ui.update(action);
  Set<String> get _selectedPermissions => ui.selectedPermissions;
  void _loadRole(JsonMap role) => ui.loadRole(role);
  static const _permissionLabels = <String, String>{
    'WRITE_INVENTORY': 'Registrar productos, lotes e ingresos',
    'READ_INVENTORY': 'Consultar inventario y temperaturas',
    'READ_SHIPMENTS': 'Consultar y validar despachos',
    'CREATE_SHIPMENT': 'Registrar despachos',
    'DELIVER': 'Confirmar entregas',
    'SUMMARY': 'Consultar resumen operativo',
    'RISKS': 'Consultar riesgos e historial t?rmico',
    'ALERTS': 'Recibir y consultar alertas',
    'RESOLVE': 'Registrar acciones correctivas',
  };

  String? get _selectedRole => ui.selectedRole;

  @override
  Widget build(BuildContext context) {
    ui.buildContext = context;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: switch (ui.screen) {
        'account' => _account(),
        'permissions' => _permissions(),
        _ => const <Widget>[],
      },
    );
  }

  List<Widget> _account() {
    final account = controller.user;
    if (account == null) {
      return [
        const SafeFlowCallout(
          title: 'SesiÃ³n no disponible',
          message: 'Inicia sesiÃ³n nuevamente.',
        ),
      ];
    }
    return [
      const SafeFlowSectionTitle('Tu sesiÃ³n'),
      SafeFlowCard(
        title: account.email,
        subtitle: 'Rol ${account.role}',
        value: '${account.permissions.length} permisos activos',
        detail: 'Identidad SafeFlow #${account.id}',
        icon: Icons.account_circle_outlined,
      ),
      const SafeFlowSectionTitle('Permisos habilitados'),
      ...account.permissions.map(
        (permission) => SafeFlowCard(
          title: _permissionLabels[permission] ?? permission,
          icon: Icons.verified_user_outlined,
          tone: SafeFlowTone.success,
        ),
      ),
      if (account.permissions.isEmpty)
        const SafeFlowCallout(
          title: 'Sin permisos asignados',
          message: 'Solicita acceso a un administrador de SafeFlow.',
        ),
      OutlinedButton.icon(
        onPressed: controller.busy ? null : controller.signOut,
        icon: const Icon(Icons.logout_rounded),
        label: const Text('Cerrar sesiÃ³n'),
      ),
    ];
  }

  List<Widget> _permissions() {
    if (controller.roles.isEmpty) {
      return [
        const SafeFlowCallout(
          title: 'Sin permisos por rol',
          message: 'No se encontraron roles configurados.',
        ),
      ];
    }
    final selected =
        controller.roles
            .where((item) => asString(item['role']) == _selectedRole)
            .firstOrNull ??
        controller.roles.first;
    if (_selectedRole == null) {
      _loadRole(selected);
    }
    return [
      const SafeFlowCallout(
        title: 'Control de acceso',
        message:
            'Los permisos disponibles dependen de las operaciones habilitadas por rol.',
      ),
      Text('Rol', style: Theme.of(context).textTheme.titleMedium),
      DropdownButtonFormField<String>(
        key: ValueKey('role-$_selectedRole'),
        initialValue: _selectedRole,
        items: controller.roles
            .map(
              (role) => DropdownMenuItem(
                value: asString(role['role']),
                child: Text(asString(role['role'])),
              ),
            )
            .toList(),
        onChanged: (value) {
          final role = controller.roles
              .where((item) => asString(item['role']) == value)
              .firstOrNull;
          if (role != null) setState(() => _loadRole(role));
        },
      ),
      const SafeFlowSectionTitle('Operaciones habilitadas'),
      ..._permissionLabels.entries.map(
        (entry) => Card(
          child: CheckboxListTile(
            value: _selectedPermissions.contains(entry.key),
            onChanged: controller.busy
                ? null
                : (value) => setState(() {
                    if (value == true) {
                      _selectedPermissions.add(entry.key);
                    } else {
                      _selectedPermissions.remove(entry.key);
                    }
                  }),
            controlAffinity: ListTileControlAffinity.leading,
            title: Text(entry.value),
            subtitle: Text(entry.key),
          ),
        ),
      ),
      FilledButton(
        onPressed: controller.busy || _selectedRole == null
            ? null
            : () => controller.replacePermissions(
                _selectedRole!,
                _selectedPermissions,
              ),
        child: controller.busy
            ? const CircularProgressIndicator()
            : const Text('Guardar permisos'),
      ),
    ];
  }
}
