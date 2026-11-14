import 'package:flutter/material.dart';

import 'core/network/api_client.dart';
import 'core/theme/safeflow_theme.dart';
import 'features/iam/infrastructure/remote/iam_repository.dart';
import 'features/iam/presentation/auth_screen.dart';
import 'features/inventory/infrastructure/remote/inventory_repository.dart';
import 'features/monitoring/infrastructure/remote/monitoring_repository.dart';
import 'features/alerts/infrastructure/remote/alerts_repository.dart';
import 'features/logistics/infrastructure/remote/logistics_repository.dart';
import 'features/reporting/infrastructure/remote/reporting_repository.dart';
import 'features/workspace/application/workspace_controller.dart';
import 'features/workspace/application/safeflow_repository.dart';
import 'features/workspace/presentation/workspace_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SafeFlowApplication());
}

class SafeFlowApplication extends StatefulWidget {
  const SafeFlowApplication({super.key});

  @override
  State<SafeFlowApplication> createState() => _SafeFlowApplicationState();
}

class _SafeFlowApplicationState extends State<SafeFlowApplication> {
  late final ApiClient _api;
  late final WorkspaceController _controller;

  @override
  void initState() {
    super.initState();
    _api = ApiClient();
    _controller = WorkspaceController(
      _api,
      SafeFlowRepository(
        iam: IamRepository(_api),
        inventory: InventoryRepository(_api),
        monitoring: MonitoringRepository(_api),
        alerts: AlertsRepository(_api),
        logistics: LogisticsRepository(_api),
        reporting: ReportingRepository(_api),
      ),
    );
    _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'SafeFlow',
    debugShowCheckedModeBanner: false,
    theme: buildSafeFlowTheme(),
    home: ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        if (_controller.loading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return _controller.signedIn
            ? SafeFlowWorkspaceScreen(controller: _controller)
            : SafeFlowAuthScreen(controller: _controller);
      },
    ),
  );
}
