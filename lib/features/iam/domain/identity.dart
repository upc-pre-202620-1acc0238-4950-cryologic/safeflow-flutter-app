import '../../../core/serialization/json.dart';

class SafeFlowUser {
  const SafeFlowUser({
    required this.id,
    required this.email,
    required this.role,
    required this.permissions,
  });

  final int id;
  final String email;
  final String role;
  final Set<String> permissions;

  factory SafeFlowUser.fromJson(JsonMap json) => SafeFlowUser(
    id: asInt(json['id']),
    email: asString(json['email']),
    role: asString(json['role']),
    permissions: asJsonList(
      json['permissions'],
    ).map((value) => value.toString()).toSet(),
  );
}
