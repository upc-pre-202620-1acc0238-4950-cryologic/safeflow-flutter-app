import '../../../../core/models/safeflow_models.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/inventory_repository.dart';

class InventoryRepository implements InventoryRepositoryPort {
  InventoryRepository(this.api);
  final ApiClient api;

  @override
  Future<List<SafeFlowProduct>> products() async => asJsonList(
    await api.get('products'),
  ).map((item) => SafeFlowProduct.fromJson(asJsonMap(item))).toList();

  @override
  Future<SafeFlowProduct> product(int id) async =>
      SafeFlowProduct.fromJson(asJsonMap(await api.get('products/$id')));

  @override
  Future<SafeFlowProduct> createProduct({
    required String name,
    required double minimum,
    required double maximum,
  }) async => SafeFlowProduct.fromJson(
    asJsonMap(
      await api.post('products', {
        'name': name,
        'type': null,
        'minimum': minimum,
        'maximum': maximum,
      }),
    ),
  );

  @override
  Future<List<SafeFlowLot>> lotsForProducts(
    List<SafeFlowProduct> products,
  ) async {
    final lots = <SafeFlowLot>[];
    for (final product in products) {
      final result = asJsonList(await api.get('products/${product.id}/lots'));
      lots.addAll(result.map((item) => SafeFlowLot.fromJson(asJsonMap(item))));
    }
    return lots;
  }

  @override
  Future<SafeFlowLot> createLot(int productId, String code) async =>
      SafeFlowLot.fromJson(
        asJsonMap(await api.post('products/$productId/lots', {'code': code})),
      );

  @override
  Future<void> recordIncome(int lotId, int quantity) async {
    await api.post('lots/$lotId/incomes', {'quantity': quantity});
  }
}
