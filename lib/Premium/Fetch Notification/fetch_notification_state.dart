part of 'fetch_notification_bloc.dart';

sealed class FetchNotificationState {}

final class FetchNotificationInitial extends FetchNotificationState {}

final class FetchNotificationLoading extends FetchNotificationState {}

final class FetchNotificationSuccess extends FetchNotificationState {
  final List<dynamic> notifications;

  FetchNotificationSuccess({required this.notifications});
}

final class FetchNotificationFailure extends FetchNotificationState {
  final String errorMessage;

  FetchNotificationFailure({required this.errorMessage});
}
