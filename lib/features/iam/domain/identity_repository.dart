import 'identity.dart';

abstract interface class IdentityRepositoryPort {
  Future<({String token, DateTime expiresAt, SafeFlowUser user})> signIn(
    String email,
    String password,
  );
  Future<void> signUp(String email, String password);
  Future<void> requestRecovery(String email);
  Future<void> signOut();
  Future<SafeFlowUser> currentUser();
  Future<List<Map<String, dynamic>>> rolePermissions();
  Future<void> replaceRolePermissions(String role, Set<String> granted);
}
