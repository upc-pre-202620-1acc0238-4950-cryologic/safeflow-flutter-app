import '../../../core/domain/business_rule_exception.dart';
import '../domain/inventory_models.dart';
import '../domain/inventory_repository.dart';

class InventoryService {
  const InventoryService(this.repository);
  final InventoryRepositoryPort repository;

  Future<SafeFlowProduct> createProduct({
    required String name,
    required String minimum,
    required String maximum,
  }) async {
    final min = double.tryParse(minimum);
    final max = double.tryParse(maximum);
    if (name.trim().isEmpty || min == null || max == null || min > max) {
      throw const BusinessRuleException(
        'Completa un nombre y un rango de temperatura v?lido.',
      );
    }
    return repository.createProduct(
      name: name.trim(),
      minimum: min,
      maximum: max,
    );
  }

  Future<void> createLot(int productId, String code) async {
    if (code.trim().isEmpty) {
      throw const BusinessRuleException('Ingresa la identificaci?n del lote.');
    }
    await repository.createLot(productId, code.trim());
  }

  Future<void> recordIncome(int lotId, String quantity) async {
    final amount = int.tryParse(quantity);
    if (amount == null || amount <= 0) {
      throw const BusinessRuleException(
        'La cantidad debe ser un entero mayor que cero.',
      );
    }
    await repository.recordIncome(lotId, amount);
  }
}
