import 'parent_auth_remote_data_source.dart';

class ParentAuthRepository {
  final ParentAuthRemoteDataSource remote;

  ParentAuthRepository(this.remote);

  Future<void> signup({
    required String name,
    required String email,
    required String password,
  }) {
    return remote.signup(
      name: name,
      email: email,
      password: password,
    );
  }

  Future<void> login({
    required String email,
    required String password,
  }) {
    return remote.login(
      email: email,
      password: password,
    );
  }

  Future<void> logout() {
    return remote.logout();
  }
}