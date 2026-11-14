import '../../../core/domain/business_rule_exception.dart';
import '../domain/logistics_models.dart';
import '../domain/logistics_repository.dart';

class LogisticsService {
  const LogisticsService(this.repository);
  final LogisticsRepositoryPort repository;

  Future<SafeFlowShipment> createShipment({
    required int productId,
    required int lotId,
    required int quantity,
    required String destination,
    required int sensorId,
  }) async {
    if (quantity <= 0 || destination.trim().isEmpty) {
      throw const BusinessRuleException(
        'Completa el destino y una cantidad mayor que cero.',
      );
    }
    return repository.createShipment(
      productId: productId,
      lotId: lotId,
      quantity: quantity,
      destination: destination.trim(),
      sensorId: sensorId,
    );
  }
}
