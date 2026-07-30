import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/user.dart';

final authRepositoryProvider = Provider<AuthRepositoryImpl>((ref) {
  return AuthRepositoryImpl(DioClient());
});

class AuthNotifier extends StateNotifier<AsyncValue<AppUser?>> {
  final AuthRepositoryImpl _repository;

  AuthNotifier(this._repository) : super(const AsyncValue.data(null)) {
    _restore();
  }

  Future<void> _restore() async {
    state = const AsyncValue.loading();
    try {
      final user = await _repository.restoreSession();
      state = AsyncValue.data(user);
    } catch (_) {
      state = const AsyncValue.data(null);
    }
  }

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final user = await _repository.login(email, password);
      state = AsyncValue.data(user);
    } on ServerException catch (e) {
      state = AsyncValue.error(e.message, StackTrace.current);
    }
  }

  Future<void> register(String email, String password, String firstName, String lastName) async {
    state = const AsyncValue.loading();
    try {
      final user = await _repository.register(email, password, firstName, lastName);
      state = AsyncValue.data(user);
    } on ServerException catch (e) {
      state = AsyncValue.error(e.message, StackTrace.current);
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    state = const AsyncValue.data(null);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AsyncValue<AppUser?>>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider));
});
