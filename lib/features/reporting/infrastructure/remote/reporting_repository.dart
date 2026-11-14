import '../../../../core/models/safeflow_models.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/reporting_repository.dart';

class ReportingRepository implements ReportingRepositoryPort {
  ReportingRepository(this.api);
  final ApiClient api;

  @override
  Future<SafeFlowSummary> summary() async =>
      SafeFlowSummary.fromJson(asJsonMap(await api.get('operational-summary')));
}
