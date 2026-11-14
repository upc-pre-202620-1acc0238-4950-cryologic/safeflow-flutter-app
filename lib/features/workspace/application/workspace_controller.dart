import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/domain/business_rule_exception.dart';
import '../../../core/models/safeflow_models.dart';
import '../../../core/network/api_client.dart';
import 'safeflow_repository.dart';

class WorkspaceController extends ChangeNotifier {
  WorkspaceController(this.api, this.repository);

  final ApiClient api;
  final SafeFlowRepository repository;

  SafeFlowUser? user;
  List<SafeFlowProduct> products = [];
  List<SafeFlowLot> lots = [];
  List<SafeFlowSensor> sensors = [];
  List<SafeFlowReading> readings = [];
  List<JsonMap> rejections = [];
  List<SafeFlowRisk> risks = [];
  List<SafeFlowIncident> incidents = [];
  List<SafeFlowShipment> shipments = [];
  List<JsonMap> roles = [];
  SafeFlowSummary? summary;
  String? error;
  String? notice;
  bool loading = true;
  bool busy = false;
  Timer? _refreshTimer;

  Set<String> get permissions => user?.permissions ?? const {};
  bool can(String permission) => permissions.contains(permission);
  bool get isAdmin => user?.role == 'ADMIN';
  bool get signedIn => user != null && api.hasValidSession;

  Future<void> initialize() async {
    await api.initialize();
    if (api.hasValidSession) {
      try {
        user = await repository.currentUser();
        await refreshWorkspace();
      } on ApiException catch (exception) {
        error = exception.message;
        await api.clearSession();
        user = null;
      }
    }
    loading = false;
    notifyListeners();
    _refreshTimer?.cancel();
    if (signedIn) {
      _refreshTimer = Timer.periodic(
        const Duration(seconds: 30),
        (_) => refreshWorkspace(silent: true),
      );
    }
  }

  Future<void> signIn(String email, String password) => _perform(() async {
    final session = await repository.signIn(email.trim(), password);
    await api.saveSession(session.token, session.expiresAt);
    user = session.user;
    await _loadWorkspace();
    _startRefreshTimer();
    notice = null;
  });

  Future<void> signUp(String email, String password) => _perform(() async {
    await repository.signUp(email.trim(), password);
    notice =
        'Cuenta creada. El envío de correos está pendiente. Inicia sesión para continuar.';
  });

  Future<void> requestRecovery(String email) => _perform(() async {
    await repository.requestRecovery(email.trim());
    notice =
        'Solicitud registrada. El envío de correos está pendiente; tu contraseña no ha cambiado.';
  });

  Future<void> signOut() => _perform(() async {
    try {
      await repository.signOut();
    } finally {
      _stopRefreshTimer();
      user = null;
      _clearWorkspace();
    }
  });

  Future<void> refreshWorkspace({bool silent = false}) async {
    if (!signedIn) return;
    if (!silent) {
      busy = true;
      notifyListeners();
    }
    try {
      await _loadWorkspace();
      error = null;
    } on ApiException catch (exception) {
      error = exception.message;
      if (exception.statusCode == 401) {
        _stopRefreshTimer();
        user = null;
        _clearWorkspace();
      }
    } finally {
      if (!silent) busy = false;
      notifyListeners();
    }
  }

  Future<void> _loadWorkspace() async {
    if (user == null) return;
    user = await repository.currentUser();
    final access = permissions;
    final canInventory = _any(access, const {
      'READ_INVENTORY',
      'WRITE_INVENTORY',
      'CREATE_SHIPMENT',
    });
    final canMonitoring = _any(access, const {
      'READ_INVENTORY',
      'WRITE_INVENTORY',
      'CREATE_SHIPMENT',
      'READ_SHIPMENTS',
      'DELIVER',
      'RISKS',
    });
    final results = await Future.wait<dynamic>([
      canInventory || access.contains('RISKS')
          ? repository.products()
          : Future.value(<SafeFlowProduct>[]),
      Future.value(<SafeFlowLot>[]),
      canMonitoring ? repository.sensors() : Future.value(<SafeFlowSensor>[]),
      canMonitoring ? repository.readings() : Future.value(<SafeFlowReading>[]),
      _any(access, const {'READ_INVENTORY', 'RISKS'})
          ? repository.rejectedReadings()
          : Future.value(<JsonMap>[]),
      access.contains('RISKS')
          ? repository.risks()
          : Future.value(<SafeFlowRisk>[]),
      _any(access, const {'ALERTS', 'RESOLVE'})
          ? repository.incidents()
          : Future.value(<SafeFlowIncident>[]),
      _any(access, const {'READ_SHIPMENTS', 'CREATE_SHIPMENT', 'DELIVER'})
          ? repository.shipments()
          : Future.value(<SafeFlowShipment>[]),
      isAdmin ? repository.rolePermissions() : Future.value(<JsonMap>[]),
      access.contains('SUMMARY') ? repository.summary() : Future.value(null),
    ]);

    products = results[0] as List<SafeFlowProduct>;
    // Fetch lots against the newly refreshed products so a first refresh is complete.
    lots = canInventory
        ? await repository.lotsForProducts(products)
        : <SafeFlowLot>[];
    sensors = results[2] as List<SafeFlowSensor>;
    readings = results[3] as List<SafeFlowReading>;
    rejections = results[4] as List<JsonMap>;
    risks = results[5] as List<SafeFlowRisk>;
    incidents = results[6] as List<SafeFlowIncident>;
    shipments = results[7] as List<SafeFlowShipment>;
    roles = results[8] as List<JsonMap>;
    summary = results[9] as SafeFlowSummary?;
  }

  Future<void> createProduct({
    required String name,
    required String minimum,
    required String maximum,
  }) => _perform(() async {
    final result = await repository.createProduct(
      name: name,
      minimum: minimum,
      maximum: maximum,
    );
    await _loadWorkspace();
    notice = 'Producto registrado.';
    selectedProductId = result.id;
  });

  int? selectedProductId;
  int? selectedLotId;
  int? selectedIncidentId;
  int? selectedShipmentId;
  JsonMap? shipmentValidation;
  List<SafeFlowReading> history = [];

  Future<void> createLot(int productId, String code) => _perform(() async {
    await repository.createLot(productId, code);
    await _loadWorkspace();
    notice = 'Lote registrado.';
  });

  Future<void> recordIncome(int lotId, String quantity) => _perform(() async {
    await repository.recordIncome(lotId, quantity);
    await _loadWorkspace();
    notice = 'Ingreso registrado.';
  });

  Future<void> createShipment({
    required int productId,
    required int lotId,
    required int quantity,
    required String destination,
    required int sensorId,
  }) => _perform(() async {
    final shipment = await repository.createShipment(
      productId: productId,
      lotId: lotId,
      quantity: quantity,
      destination: destination,
      sensorId: sensorId,
    );
    await _loadWorkspace();
    selectedShipmentId = shipment.id;
    notice = 'Despacho registrado en preparación.';
  });

  Future<void> validateShipment(int id) async {
    selectedShipmentId = id;
    shipmentValidation = null;
    await _perform(() async {
      shipmentValidation = await repository.validateShipment(id);
    });
  }

  Future<void> departShipment(int id, {bool acceptRisk = false}) =>
      _perform(() async {
        await repository.departShipment(id, acceptRisk: acceptRisk);
        await _loadWorkspace();
        notice = 'Despacho en tránsito.';
      });

  Future<void> deliverShipment(int id) => _perform(() async {
    await repository.deliverShipment(id);
    await _loadWorkspace();
    notice = 'Entrega confirmada.';
  });

  Future<void> resolveIncident(int id, String action) => _perform(() async {
    await repository.resolveIncident(id, action);
    await _loadWorkspace();
    notice = 'Incidencia resuelta. Se conserva su historial.';
  });

  Future<void> loadHistory({int? productId, int? shipmentId}) async {
    final to = DateTime.now();
    try {
      history = await repository.readings(
        productId: productId,
        shipmentId: shipmentId,
        from: to.subtract(const Duration(days: 7)),
        to: to,
      );
      error = null;
    } on ApiException catch (exception) {
      error = exception.message;
    }
    notifyListeners();
  }

  Future<void> replacePermissions(String role, Set<String> granted) =>
      _perform(() async {
        await repository.replaceRolePermissions(role, granted);
        roles = await repository.rolePermissions();
        notice = 'Permisos guardados.';
      });

  Future<void> _perform(Future<void> Function() operation) async {
    if (busy) return;
    busy = true;
    error = null;
    notice = null;
    notifyListeners();
    try {
      await operation();
    } on ApiException catch (exception) {
      error = exception.message;
    } on BusinessRuleException catch (exception) {
      error = exception.message;
    } catch (_) {
      error = 'No se pudo completar la solicitud. Intenta nuevamente.';
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  static bool _any(Set<String> permissions, Set<String> required) =>
      required.any(permissions.contains);

  void _startRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => refreshWorkspace(silent: true),
    );
  }

  void _stopRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  void _clearWorkspace() {
    products = [];
    lots = [];
    sensors = [];
    readings = [];
    rejections = [];
    risks = [];
    incidents = [];
    shipments = [];
    roles = [];
    summary = null;
    history = [];
    selectedProductId = null;
    selectedLotId = null;
    selectedIncidentId = null;
    selectedShipmentId = null;
    shipmentValidation = null;
  }

  @override
  void dispose() {
    _stopRefreshTimer();
    super.dispose();
  }
}
