import '../domain/identity.dart';
import '../domain/identity_repository.dart';

class IdentityService {
  const IdentityService(this.repository);
  final IdentityRepositoryPort repository;

  Future<({String token, DateTime expiresAt, SafeFlowUser user})> signIn(
    String email,
    String password,
  ) => repository.signIn(email, password);
  Future<void> signUp(String email, String password) =>
      repository.signUp(email, password);
  Future<void> requestRecovery(String email) =>
      repository.requestRecovery(email);
  Future<void> signOut() => repository.signOut();
  Future<SafeFlowUser> account() => repository.currentUser();
  Future<List<Map<String, dynamic>>> rolePermissions() =>
      repository.rolePermissions();
  Future<void> replaceRolePermissions(String role, Set<String> granted) =>
      repository.replaceRolePermissions(role, granted);
}
