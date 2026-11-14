import '../../../../core/models/safeflow_models.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/alerts_repository.dart';

class AlertsRepository implements AlertsRepositoryPort {
  AlertsRepository(this.api);
  final ApiClient api;

  @override
  Future<List<SafeFlowIncident>> incidents() async => asJsonList(
    await api.get('incidents'),
  ).map((item) => SafeFlowIncident.fromJson(asJsonMap(item))).toList();

  @override
  Future<void> resolveIncident(int id, String action) async {
    await api.post('incidents/$id/resolution', {'action': action});
  }
}
