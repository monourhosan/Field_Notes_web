import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';

import '../../../domain/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;

  AuthBloc(this._authRepository) : super(AuthInitial()) {
    on<AuthEvent>((event, emit) async {
      if (event is AppStarted) {
        await _onAppStarted(event, emit);
      } else if (event is LoginSubmitted) {
        await _onLoginSubmitted(event, emit);
      } else if (event is RegisterSubmitted) {
        await _onRegisterSubmitted(event, emit);
      } else if (event is LogoutRequested) {
        await _onLogoutRequested(event, emit);
      }
    }, transformer: sequential());
  }

  Future<void> _onAppStarted(AppStarted event, Emitter<AuthState> emit) async {
    try {
      final user = await _authRepository.getCurrentUser();
      if (user != null) {
        emit(Authenticated(user));
      } else {
        emit(Unauthenticated());
      }
    } catch (_) {
      emit(Unauthenticated());
    }
  }

  Future<void> _onLoginSubmitted(
    LoginSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = await _authRepository.login(event.username, event.password);
      emit(Authenticated(user));
    } catch (e) {
      emit(AuthFailure(_formatError(e)));
    }
  }

  Future<void> _onRegisterSubmitted(
    RegisterSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = await _authRepository.register(
        event.username,
        event.email,
        event.password,
      );
      emit(Authenticated(user));
    } catch (e) {
      emit(AuthFailure(_formatError(e)));
    }
  }

  String _formatError(dynamic e) {
    final str = e.toString().replaceAll('Exception: ', '').replaceAll('ClientException: ', '');
    if (str.contains('Failed to fetch') || str.contains('localhost')) {
      return 'Cannot reach backend server. Tap the Settings (gear) icon in the top right to configure your live backend URL.';
    }
    return str;
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await _authRepository.logout();
      emit(Unauthenticated());
    } catch (e) {
      emit(AuthFailure('Sign out failed: $e'));
    }
  }
}
