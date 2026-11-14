import 'alert_models.dart';

abstract interface class AlertsRepositoryPort {
  Future<List<SafeFlowIncident>> incidents();
  Future<void> resolveIncident(int id, String action);
}
