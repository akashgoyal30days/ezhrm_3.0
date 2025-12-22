part of 'policy_bloc.dart';

@immutable
sealed class PolicyEvent {}

class GetCompanyPolicy extends PolicyEvent {}
