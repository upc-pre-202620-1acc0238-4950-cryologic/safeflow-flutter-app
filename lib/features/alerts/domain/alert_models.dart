import '../../../core/serialization/json.dart';

class SafeFlowIncident {
  const SafeFlowIncident({
    required this.id,
    required this.sensorId,
    required this.productId,
    required this.location,
    required this.type,
    required this.severity,
    required this.description,
    required this.openedAt,
    required this.lastSeenAt,
    required this.repetitions,
    required this.action,
    required this.author,
    required this.resolvedAt,
  });

  final int id;
  final int sensorId;
  final int productId;
  final String location;
  final String type;
  final String severity;
  final String description;
  final DateTime? openedAt;
  final DateTime? lastSeenAt;
  final int repetitions;
  final String? action;
  final String? author;
  final DateTime? resolvedAt;
  bool get active => resolvedAt == null;

  factory SafeFlowIncident.fromJson(JsonMap json) => SafeFlowIncident(
    id: asInt(json['id']),
    sensorId: asInt(json['sensorId']),
    productId: asInt(json['productId']),
    location: asString(json['location']),
    type: asString(json['type']),
    severity: asString(json['severity'], 'UNKNOWN'),
    description: asString(json['description']),
    openedAt: asDateTime(json['openedAt']),
    lastSeenAt: asDateTime(json['lastSeenAt']),
    repetitions: asInt(json['repetitions'], 1),
    action: json['action']?.toString(),
    author: json['author']?.toString(),
    resolvedAt: asDateTime(json['resolvedAt']),
  );
}
