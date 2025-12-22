part of 'feedback_bloc.dart';

@immutable
sealed class FeedbackEvent {}

class FeedbackActivity extends FeedbackEvent {
  String? employee_id;
  final String feedback_text;
  // final File file_url;

  FeedbackActivity({
    required this.feedback_text,
    // required this.file_url,
  });
}
