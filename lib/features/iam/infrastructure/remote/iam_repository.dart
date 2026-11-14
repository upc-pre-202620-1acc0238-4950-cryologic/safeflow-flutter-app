import '../../../../core/models/safeflow_models.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/identity_repository.dart';

class IamRepository implements IdentityRepositoryPort {
  IamRepository(this.api);
  final ApiClient api;

  @override
  Future<({String token, DateTime expiresAt, SafeFlowUser user})> signIn(
    String email,
    String password,
  ) async {
    final session = asJsonMap(
      await api.post('auth/sign-in', {'email': email, 'password': password}),
    );
    final token = asString(session['token']);
    final expiry = asDateTime(session['expiresAt']);
    if (token.isEmpty || expiry == null) {
      throw const ApiException('La API devolvió una sesión incompleta.');
    }
    return (
      token: token,
      expiresAt: expiry,
      user: SafeFlowUser.fromJson(session),
    );
  }

  @override
  Future<void> signUp(String email, String password) async {
    await api.post('auth/sign-up', {
      'email': email,
      'password': password,
      'terms': true,
    });
  }

  @override
  Future<void> requestRecovery(String email) async {
    await api.post('recovery-requests', {'email': email});
  }

  @override
  Future<void> signOut() async {
    if (api.hasValidSession) await api.post('auth/sign-out');
    await api.clearSession();
  }

  @override
  Future<SafeFlowUser> currentUser() async =>
      SafeFlowUser.fromJson(asJsonMap(await api.get('users/me')));

  @override
  Future<List<JsonMap>> rolePermissions() async => asJsonList(
    await api.get('role-permissions'),
  ).map((item) => asJsonMap(item)).toList();

  @override
  Future<void> replaceRolePermissions(String role, Set<String> granted) async {
    await api.put('role-permissions/$role', {'granted': granted.toList()});
  }
}
