part of 'contact_us_bloc.dart';

@immutable
sealed class ContactUsState {}

final class ContactUsInitial extends ContactUsState {}

final class ContactUsLoading extends ContactUsInitial {}

final class ContactUsSuccess extends ContactUsInitial {
  final List<Map<String, dynamic>> contactUsData;

  ContactUsSuccess({required this.contactUsData});
}

final class ContactUsFailure extends ContactUsInitial {
  final String errorMessage;

  ContactUsFailure({required this.errorMessage});
}
