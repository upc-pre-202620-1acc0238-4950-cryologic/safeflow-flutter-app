import '../../../core/serialization/json.dart';

class SafeFlowReading {
  const SafeFlowReading({
    required this.id,
    required this.sensorId,
    required this.shipmentId,
    required this.recordedAt,
    required this.temperature,
    required this.condition,
  });

  final int id;
  final int sensorId;
  final int? shipmentId;
  final DateTime? recordedAt;
  final double temperature;
  final String condition;

  factory SafeFlowReading.fromJson(JsonMap json) => SafeFlowReading(
    id: asInt(json['id']),
    sensorId: asInt(json['sensorId']),
    shipmentId: json['shipmentId'] == null ? null : asInt(json['shipmentId']),
    recordedAt: asDateTime(json['recordedAt']),
    temperature: asDouble(json['temperature']),
    condition: asString(json['condition'], 'UNKNOWN'),
  );
}

class SafeFlowSensor {
  const SafeFlowSensor({
    required this.id,
    required this.productId,
    required this.location,
    required this.connected,
    required this.condition,
    required this.latestReading,
  });

  final int id;
  final int productId;
  final String location;
  final bool connected;
  final String condition;
  final SafeFlowReading? latestReading;

  factory SafeFlowSensor.fromJson(JsonMap json) => SafeFlowSensor(
    id: asInt(json['id']),
    productId: asInt(json['productId']),
    location: asString(json['location']),
    connected: json['connected'] == true,
    condition: asString(json['condition'], 'UNKNOWN'),
    latestReading: json['latestReading'] is Map
        ? SafeFlowReading.fromJson(asJsonMap(json['latestReading']))
        : null,
  );
}

class SafeFlowRisk {
  const SafeFlowRisk({
    required this.productId,
    required this.sensorId,
    required this.temperature,
    required this.condition,
    required this.recordedAt,
  });

  final int productId;
  final int sensorId;
  final double? temperature;
  final String condition;
  final DateTime? recordedAt;

  factory SafeFlowRisk.fromJson(JsonMap json) => SafeFlowRisk(
    productId: asInt(json['productId']),
    sensorId: asInt(json['sensorId']),
    temperature: json['temperature'] == null
        ? null
        : asDouble(json['temperature']),
    condition: asString(json['condition'], 'UNKNOWN'),
    recordedAt: asDateTime(json['recordedAt']),
  );
}
