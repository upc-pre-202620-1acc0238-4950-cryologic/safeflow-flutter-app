import '../../../core/models/safeflow_models.dart';
import '../../alerts/domain/alerts_repository.dart';
import '../../alerts/application/alert_service.dart';
import '../../iam/application/identity_service.dart';
import '../../iam/domain/identity_repository.dart';
import '../../inventory/domain/inventory_repository.dart';
import '../../inventory/application/inventory_service.dart';
import '../../logistics/domain/logistics_repository.dart';
import '../../logistics/application/logistics_service.dart';
import '../../monitoring/application/monitoring_service.dart';
import '../../monitoring/domain/monitoring_repository.dart';
import '../../reporting/application/reporting_service.dart';
import '../../reporting/domain/reporting_repository.dart';

/// Workspace facade that composes the six bounded-context repositories.
/// This keeps cross-module refresh and mutations in the application layer.
class SafeFlowRepository {
  SafeFlowRepository({
    required this.iam,
    required this.inventory,
    required this.monitoring,
    required this.alerts,
    required this.logistics,
    required this.reporting,
  });

  final IdentityRepositoryPort iam;
  final InventoryRepositoryPort inventory;
  final MonitoringRepositoryPort monitoring;
  final AlertsRepositoryPort alerts;
  final LogisticsRepositoryPort logistics;
  final ReportingRepositoryPort reporting;
  late final identityService = IdentityService(iam);
  late final inventoryService = InventoryService(inventory);
  late final logisticsService = LogisticsService(logistics);
  late final alertService = AlertService(alerts);
  late final monitoringService = MonitoringService(monitoring);
  late final reportingService = ReportingService(reporting);

  Future<({String token, DateTime expiresAt, SafeFlowUser user})> signIn(
    String email,
    String password,
  ) => identityService.signIn(email, password);
  Future<void> signUp(String email, String password) =>
      identityService.signUp(email, password);
  Future<void> requestRecovery(String email) =>
      identityService.requestRecovery(email);
  Future<void> signOut() => identityService.signOut();
  Future<SafeFlowUser> currentUser() => identityService.account();
  Future<List<JsonMap>> rolePermissions() => identityService.rolePermissions();
  Future<void> replaceRolePermissions(String role, Set<String> granted) =>
      identityService.replaceRolePermissions(role, granted);

  Future<List<SafeFlowProduct>> products() => inventory.products();
  Future<SafeFlowProduct> product(int id) => inventory.product(id);
  Future<SafeFlowProduct> createProduct({
    required String name,
    required String minimum,
    required String maximum,
  }) => inventoryService.createProduct(
    name: name,
    minimum: minimum,
    maximum: maximum,
  );
  Future<List<SafeFlowLot>> lotsForProducts(List<SafeFlowProduct> products) =>
      inventory.lotsForProducts(products);
  Future<void> createLot(int productId, String code) =>
      inventoryService.createLot(productId, code);
  Future<void> recordIncome(int lotId, String quantity) =>
      inventoryService.recordIncome(lotId, quantity);

  Future<List<SafeFlowSensor>> sensors() => monitoringService.sensors();
  Future<List<SafeFlowReading>> readings({
    int? productId,
    int? shipmentId,
    DateTime? from,
    DateTime? to,
  }) => monitoringService.readings(
    productId: productId,
    shipmentId: shipmentId,
    from: from,
    to: to,
  );
  Future<List<JsonMap>> rejectedReadings() =>
      monitoringService.rejectedReadings();
  Future<List<SafeFlowRisk>> risks() => monitoringService.risks();

  Future<List<SafeFlowIncident>> incidents() => alerts.incidents();
  Future<void> resolveIncident(int id, String action) =>
      alertService.resolveIncident(id, action);

  Future<List<SafeFlowShipment>> shipments() => logistics.shipments();
  Future<SafeFlowShipment> createShipment({
    required int productId,
    required int lotId,
    required int quantity,
    required String destination,
    required int sensorId,
  }) => logisticsService.createShipment(
    productId: productId,
    lotId: lotId,
    quantity: quantity,
    destination: destination,
    sensorId: sensorId,
  );
  Future<JsonMap> validateShipment(int id) => logistics.validateShipment(id);
  Future<void> departShipment(int id, {bool acceptRisk = false}) =>
      logistics.departShipment(id, acceptRisk: acceptRisk);
  Future<void> deliverShipment(int id) => logistics.deliverShipment(id);

  Future<SafeFlowSummary> summary() => reportingService.summary();
}
