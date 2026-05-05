import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import 'package:medcare_crm/core/utils/ui_utils.dart';
import '../../data/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

// AuthBloc — BLoC (Business Logic Component) для управління авторизацією
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _repository;

  AuthBloc({AuthRepository? repository})
      : _repository = repository ?? AuthRepository(),
        super(AuthInitial()) {
    on<AuthCheckRequested>(_onCheckRequested);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
  }

  Future<void> _onCheckRequested(AuthCheckRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final user = await _repository.getCachedUser();
    if (user != null) {
      emit(AuthAuthenticated(user));
    } else {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onLoginRequested(AuthLoginRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      // POST /auth/login → NestJS AuthService → bcrypt.compare(rounds=12) → JWT
      final auth = await _repository.login(event.email, event.password);
      UiUtils.showSuccess('Ласкаво просимо, ${auth.user.firstName}!');
      emit(AuthAuthenticated(auth.user));
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Помилка з\'єднання з сервером';
      final errorMsg = msg is List ? msg.first : msg.toString();
      UiUtils.showError(errorMsg);
      emit(AuthError(errorMsg));
    } catch (e) {
      UiUtils.showError('Невідома помилка. Спробуйте ще раз.');
      emit(const AuthError('Невідома помилка. Спробуйте ще раз.'));
    }
  }

  Future<void> _onLogoutRequested(AuthLogoutRequested event, Emitter<AuthState> emit) async {
    await _repository.logout();
    emit(AuthUnauthenticated());
  }
}
