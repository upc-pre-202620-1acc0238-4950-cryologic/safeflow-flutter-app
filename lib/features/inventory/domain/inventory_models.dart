import '../../../core/serialization/json.dart';

class SafeFlowProduct {
  const SafeFlowProduct({
    required this.id,
    required this.name,
    required this.type,
    required this.minimum,
    required this.maximum,
    required this.stock,
    required this.reserved,
    required this.available,
    required this.condition,
  });

  final int id;
  final String name;
  final String? type;
  final double minimum;
  final double maximum;
  final int stock;
  final int reserved;
  final int available;
  final String condition;

  factory SafeFlowProduct.fromJson(JsonMap json) => SafeFlowProduct(
    id: asInt(json['id']),
    name: asString(json['name'], 'Producto'),
    type: json['type']?.toString(),
    minimum: asDouble(json['minimum']),
    maximum: asDouble(json['maximum']),
    stock: asInt(json['stock']),
    reserved: asInt(json['reserved']),
    available: asInt(json['available']),
    condition: asString(json['condition'], 'UNKNOWN'),
  );
}

class SafeFlowLot {
  const SafeFlowLot({
    required this.id,
    required this.productId,
    required this.code,
    required this.stock,
    required this.reserved,
    required this.available,
  });

  final int id;
  final int productId;
  final String code;
  final int stock;
  final int reserved;
  final int available;

  factory SafeFlowLot.fromJson(JsonMap json) => SafeFlowLot(
    id: asInt(json['id']),
    productId: asInt(json['productId']),
    code: asString(json['code']),
    stock: asInt(json['stock']),
    reserved: asInt(json['reserved']),
    available: asInt(json['available']),
  );
}
