part of 'show_comp_off_bloc.dart';

@immutable
sealed class ShowCompOffState {}

final class ShowCompOffInitial extends ShowCompOffState {}

final class ShowCompOffLoading extends ShowCompOffState {}

final class ShowCompOffSuccess extends ShowCompOffState {
  final List<dynamic> compOffHistory;
  ShowCompOffSuccess({required this.compOffHistory});
}

final class ShowCompOffError extends ShowCompOffState {
  final String errorMessage;

  ShowCompOffError({required this.errorMessage});
}
