part of 'post_csr_activity_bloc.dart';

@immutable
sealed class PostCsrActivityEvent {}

class PostCsrActivity extends PostCsrActivityEvent {
  String? employee_id;
  final String description;
  final File activity;

  PostCsrActivity({
    required this.activity,
    required this.description,
  });
}
