import 'inventory_models.dart';

abstract interface class InventoryRepositoryPort {
  Future<List<SafeFlowProduct>> products();
  Future<SafeFlowProduct> product(int id);
  Future<SafeFlowProduct> createProduct({
    required String name,
    required double minimum,
    required double maximum,
  });
  Future<List<SafeFlowLot>> lotsForProducts(List<SafeFlowProduct> products);
  Future<SafeFlowLot> createLot(int productId, String code);
  Future<void> recordIncome(int lotId, int quantity);
}
