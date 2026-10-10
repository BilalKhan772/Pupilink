
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'staff_auth_remote_data_source.dart';

final staffAuthRemoteDataSourceProvider =
    Provider<StaffAuthRemoteDataSource>((ref) {
  return StaffAuthRemoteDataSource();
});

final staffAuthRepositoryProvider = Provider<StaffAuthRepository>((ref) {
  return StaffAuthRepository(
    remoteDataSource: ref.watch(staffAuthRemoteDataSourceProvider),
  );
});

class StaffAuthRepository {
  StaffAuthRepository({
    required StaffAuthRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  final StaffAuthRemoteDataSource _remoteDataSource;

  Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  }) {
    return _remoteDataSource.signIn(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() => _remoteDataSource.signOut();
}
