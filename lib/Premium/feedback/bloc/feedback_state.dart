part of 'feedback_bloc.dart';

@immutable
sealed class FeedbackState {}

final class FeedbackInitial extends FeedbackState {}

final class FeedbackLoading extends FeedbackInitial {}

class FeedbackSuccess extends FeedbackState {
  final List<Map<String, dynamic>> feedbackData;

  FeedbackSuccess({required this.feedbackData});
}

final class FeedbackError extends FeedbackInitial {
  final String error;

  FeedbackError({required this.error});
}
