import '../../../../core/models/safeflow_models.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/logistics_repository.dart';

class LogisticsRepository implements LogisticsRepositoryPort {
  LogisticsRepository(this.api);
  final ApiClient api;

  @override
  Future<List<SafeFlowShipment>> shipments() async => asJsonList(
    await api.get('shipments'),
  ).map((item) => SafeFlowShipment.fromJson(asJsonMap(item))).toList();

  @override
  Future<SafeFlowShipment> createShipment({
    required int productId,
    required int lotId,
    required int quantity,
    required String destination,
    required int sensorId,
  }) async => SafeFlowShipment.fromJson(
    asJsonMap(
      await api.post('shipments', {
        'productId': productId,
        'lotId': lotId,
        'quantity': quantity,
        'destination': destination,
        'sensorId': sensorId,
      }),
    ),
  );

  @override
  Future<JsonMap> validateShipment(int id) async =>
      asJsonMap(await api.get('shipments/$id/validation'));

  @override
  Future<void> departShipment(int id, {bool acceptRisk = false}) async {
    await api.post('shipments/$id/departure', {'acceptRisk': acceptRisk});
  }

  @override
  Future<void> deliverShipment(int id) async {
    await api.post('shipments/$id/delivery');
  }
}
