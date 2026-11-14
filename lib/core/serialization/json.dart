typedef JsonMap = Map<String, dynamic>;

JsonMap asJsonMap(dynamic value) =>
    value is Map<String, dynamic> ? value : <String, dynamic>{};

List<dynamic> asJsonList(dynamic value) =>
    value is List ? value : const <dynamic>[];

String asString(dynamic value, [String fallback = '']) =>
    value == null ? fallback : value.toString();

int asInt(dynamic value, [int fallback = 0]) =>
    value is num ? value.toInt() : int.tryParse('$value') ?? fallback;

double asDouble(dynamic value, [double fallback = 0]) =>
    value is num ? value.toDouble() : double.tryParse('$value') ?? fallback;

DateTime? asDateTime(dynamic value) =>
    value == null ? null : DateTime.tryParse(value.toString())?.toLocal();
