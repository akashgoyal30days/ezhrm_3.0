part of 'work_from_home_bloc.dart';

@immutable
sealed class WorkFromHomeState {}

final class WorkFromHomeInitial extends WorkFromHomeState {}

final class RequestWorkFromHomeLoading extends WorkFromHomeInitial {}

final class RequestWorkFromHomeSuccess extends WorkFromHomeInitial {
  final List<Map<String, dynamic>> response;

  RequestWorkFromHomeSuccess({required this.response});
}

final class RequestWorkFromHomeFailure extends WorkFromHomeInitial {
  final String errorMessage;

  RequestWorkFromHomeFailure({required this.errorMessage});
}

final class GetWorkFromHomeSuccess extends WorkFromHomeInitial {
  final List<Map<String, dynamic>> response;
  GetWorkFromHomeSuccess({required this.response});
}

final class GetWorkFromHomeFailure extends WorkFromHomeInitial {
  final String errorMessage;

  GetWorkFromHomeFailure({required this.errorMessage});
}
