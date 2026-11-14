import '../../../core/serialization/json.dart';

class SafeFlowSummary {
  const SafeFlowSummary({
    required this.products,
    required this.units,
    required this.risks,
    required this.activeIncidents,
    required this.inTransit,
    required this.critical,
    required this.warnings,
    required this.shipments,
    required this.preparation,
    required this.delivered,
  });

  final int products;
  final int units;
  final int risks;
  final int activeIncidents;
  final int inTransit;
  final int critical;
  final int warnings;
  final int shipments;
  final int preparation;
  final int delivered;

  factory SafeFlowSummary.fromJson(JsonMap json) => SafeFlowSummary(
    products: asInt(json['products']),
    units: asInt(json['units']),
    risks: asInt(json['risks']),
    activeIncidents: asInt(json['activeIncidents']),
    inTransit: asInt(json['inTransit']),
    critical: asInt(json['critical']),
    warnings: asInt(json['warnings']),
    shipments: asInt(json['shipments']),
    preparation: asInt(json['preparation']),
    delivered: asInt(json['delivered']),
  );
}
