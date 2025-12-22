part of 'auth_bloc.dart';

@immutable
sealed class AuthState {}

final class AuthInitial extends AuthState {}

final class AuthLoading extends AuthState {}

final class AuthSuccess extends AuthState {}

final class AuthLoaded extends AuthState {
  final AppUser user; // Store AppUser instead of raw userData and token
  AuthLoaded(this.user);
}

final class AuthFailure extends AuthState {
  final String message;

  AuthFailure(this.message);
}

// New logout-specific states
final class LogoutSuccess extends AuthState {}

final class LogoutFailure extends AuthState {
  final String message;

  LogoutFailure(this.message);
}

final class UpdatePasswordSuccess extends AuthState {
  final String message;
  UpdatePasswordSuccess(this.message);
}

final class UpdatePasswordFailure extends AuthState {
  final String message;

  UpdatePasswordFailure(this.message);
}
