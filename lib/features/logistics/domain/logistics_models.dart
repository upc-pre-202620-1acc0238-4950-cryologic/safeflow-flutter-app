import '../../../core/serialization/json.dart';

class SafeFlowShipment {
  const SafeFlowShipment({
    required this.id,
    required this.productId,
    required this.lotId,
    required this.sensorId,
    required this.quantity,
    required this.destination,
    required this.status,
    required this.createdAt,
    required this.riskAccepted,
    required this.temperature,
  });

  final int id;
  final int productId;
  final int lotId;
  final int sensorId;
  final int quantity;
  final String destination;
  final String status;
  final DateTime? createdAt;
  final bool riskAccepted;
  final double? temperature;

  factory SafeFlowShipment.fromJson(JsonMap json) => SafeFlowShipment(
    id: asInt(json['id']),
    productId: asInt(json['productId']),
    lotId: asInt(json['lotId']),
    sensorId: asInt(json['sensorId']),
    quantity: asInt(json['quantity']),
    destination: asString(json['destination']),
    status: asString(json['status'], 'PREPARATION'),
    createdAt: asDateTime(json['createdAt']),
    riskAccepted: json['riskAccepted'] == true,
    temperature: json['temperature'] == null
        ? null
        : asDouble(json['temperature']),
  );
}
