part of 'change_password_bloc.dart';

@immutable
sealed class ChangePasswordEvent {}

class ChangePassword extends ChangePasswordEvent {
  final String email;
  final String old_password;
  final String new_password;
  final String confirm_password;

  ChangePassword(
      {required this.email,
      required this.old_password,
      required this.new_password,
      required this.confirm_password});
}
