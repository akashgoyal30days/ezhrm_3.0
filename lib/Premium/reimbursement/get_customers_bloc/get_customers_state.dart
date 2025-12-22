part of 'get_customers_bloc.dart';

@immutable
sealed class GetCustomersState {}

final class GetCustomersInitial extends GetCustomersState {}

final class GetCustomersLoading extends GetCustomersState {}

final class GetCustomersSuccess extends GetCustomersState {
  final List<Map<String, dynamic>> customers;

  GetCustomersSuccess({required this.customers});
}

final class GetCustomersFailure extends GetCustomersState {
  final String errorMessage;

  GetCustomersFailure({required this.errorMessage});
}
