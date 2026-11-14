import 'package:flutter/material.dart';

import '../../../core/models/safeflow_models.dart';
import '../application/workspace_controller.dart';

/// Explicit navigation and ephemeral form state shared by the workspace shell
/// and the active feature screen. Feature widgets do not reach into shell State.
class WorkspaceUiContext {
  WorkspaceUiContext({
    required this.controller,
    required this.screen,
    required this.update,
    required this.navigate,
    required this.field,
    required this.loadRole,
    required this.back,
    required this.isMounted,
  });

  final WorkspaceController controller;
  String screen;
  final void Function(VoidCallback) update;
  final void Function(String, {int? id, bool root}) navigate;
  final TextEditingController Function(String) field;
  String filter = 'Todos';
  String incidentFilter = 'Activas';
  String shipmentFilter = 'Todos';
  int? productId;
  int? lotId;
  int? sensorId;
  String? selectedRole;
  bool historyForShipment = false;
  final Set<String> selectedPermissions = {};
  final void Function(JsonMap) loadRole;
  final VoidCallback back;
  final bool Function() isMounted;
  BuildContext? buildContext;
}
