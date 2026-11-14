import 'monitoring_models.dart';

abstract interface class MonitoringRepositoryPort {
  Future<List<SafeFlowSensor>> sensors();
  Future<List<SafeFlowReading>> readings({
    int? productId,
    int? shipmentId,
    DateTime? from,
    DateTime? to,
  });
  Future<List<Map<String, dynamic>>> rejectedReadings();
  Future<List<SafeFlowRisk>> risks();
}
