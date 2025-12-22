part of 'add_comp_off_bloc.dart';

@immutable
sealed class AddCompOffState {}

final class AddCompOffInitial extends AddCompOffState {}

final class AddCompOffLoading extends AddCompOffInitial {}

final class AddCompOffSuccess extends AddCompOffInitial {
  final List<Map<String, dynamic>> response;

  AddCompOffSuccess({required this.response});
}

final class AddCompOffFailure extends AddCompOffInitial {
  final String errorMessage;

  AddCompOffFailure({required this.errorMessage});
}
