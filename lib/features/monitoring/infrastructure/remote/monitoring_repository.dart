import '../../../../core/models/safeflow_models.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/monitoring_repository.dart';

class MonitoringRepository implements MonitoringRepositoryPort {
  MonitoringRepository(this.api);
  final ApiClient api;

  @override
  Future<List<SafeFlowSensor>> sensors() async => asJsonList(
    await api.get('sensors'),
  ).map((item) => SafeFlowSensor.fromJson(asJsonMap(item))).toList();

  @override
  Future<List<SafeFlowReading>> readings({
    int? productId,
    int? shipmentId,
    DateTime? from,
    DateTime? to,
  }) async {
    final query = <String, String>{};
    if (productId != null) query['productId'] = '$productId';
    if (shipmentId != null) query['shipmentId'] = '$shipmentId';
    if (from != null) query['from'] = from.toUtc().toIso8601String();
    if (to != null) query['to'] = to.toUtc().toIso8601String();
    return asJsonList(
      await api.get('readings', query: query),
    ).map((item) => SafeFlowReading.fromJson(asJsonMap(item))).toList();
  }

  @override
  Future<List<JsonMap>> rejectedReadings() async => asJsonList(
    await api.get('rejected-readings'),
  ).map((item) => asJsonMap(item)).toList();

  @override
  Future<List<SafeFlowRisk>> risks() async => asJsonList(
    await api.get('risks'),
  ).map((item) => SafeFlowRisk.fromJson(asJsonMap(item))).toList();
}
