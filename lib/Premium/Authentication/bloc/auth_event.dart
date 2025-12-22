part of 'auth_bloc.dart';

@immutable
sealed class AuthEvent {}

final class LoginSubmitted extends AuthEvent {
  final String email;
  final String password;
  final String deviceId;

  LoginSubmitted(this.email, this.password, this.deviceId);
}

final class UpdatePassword extends AuthEvent {
  final String email;

  UpdatePassword({required this.email});
}

final class Logout extends AuthEvent {} // New Logout event
