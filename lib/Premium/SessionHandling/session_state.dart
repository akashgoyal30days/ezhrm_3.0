part of 'session_bloc.dart';

sealed class SessionState {}

final class SessionInitial extends SessionState {}

class SessionExpiredState extends SessionState {}

class UserNotFoundState extends SessionState {}
