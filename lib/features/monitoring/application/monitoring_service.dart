import '../domain/monitoring_models.dart';
import '../domain/monitoring_repository.dart';

class MonitoringService {
  const MonitoringService(this.repository);
  final MonitoringRepositoryPort repository;

  Future<List<SafeFlowSensor>> sensors() => repository.sensors();
  Future<List<SafeFlowReading>> readings({
    int? productId,
    int? shipmentId,
    DateTime? from,
    DateTime? to,
  }) => repository.readings(
    productId: productId,
    shipmentId: shipmentId,
    from: from,
    to: to,
  );
  Future<List<Map<String, dynamic>>> rejectedReadings() =>
      repository.rejectedReadings();
  Future<List<SafeFlowRisk>> risks() => repository.risks();
}
