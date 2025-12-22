part of 'view_csr_activity_bloc.dart';

@immutable
sealed class ViewCsrActivityState {}

final class ViewCsrActivityInitial extends ViewCsrActivityState {}

final class ViewCsrActivityLoading extends ViewCsrActivityState {}

final class ViewCsrActivitySuccess extends ViewCsrActivityState {
  final List<Map<String, dynamic>> csrActivityData;

  ViewCsrActivitySuccess({required this.csrActivityData});
}

final class ViewCsrActivityError extends ViewCsrActivityState {
  final String error;

  ViewCsrActivityError({required this.error});
}
