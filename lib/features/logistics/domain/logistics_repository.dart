import 'logistics_models.dart';

abstract interface class LogisticsRepositoryPort {
  Future<List<SafeFlowShipment>> shipments();
  Future<SafeFlowShipment> createShipment({
    required int productId,
    required int lotId,
    required int quantity,
    required String destination,
    required int sensorId,
  });
  Future<Map<String, dynamic>> validateShipment(int id);
  Future<void> departShipment(int id, {bool acceptRisk = false});
  Future<void> deliverShipment(int id);
}
