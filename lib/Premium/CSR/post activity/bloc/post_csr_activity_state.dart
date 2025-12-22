part of 'post_csr_activity_bloc.dart';

@immutable
sealed class PostCsrActivityState {}

final class PostCsrActivityInitial extends PostCsrActivityState {}

final class PostCsrActivityLoading extends PostCsrActivityInitial {}

final class PostCsrActivitySuccess extends PostCsrActivityInitial {
  final List<Map<String, dynamic>> activityData;

  PostCsrActivitySuccess({required this.activityData});
}

final class PostCsrActivityError extends PostCsrActivityInitial {
  final String error;

  PostCsrActivityError({required this.error});
}
