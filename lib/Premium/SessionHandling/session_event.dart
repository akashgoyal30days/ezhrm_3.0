part of 'session_bloc.dart';

sealed class SessionEvent {}

class SessionExpired extends SessionEvent {}

class UserNotFound extends SessionEvent {}
