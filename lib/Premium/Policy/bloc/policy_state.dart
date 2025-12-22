part of 'policy_bloc.dart';

@immutable
sealed class PolicyState {}

final class PolicyInitial extends PolicyState {}

final class GetCompanyPolicyLoading extends PolicyInitial {}

final class GetCompanyPolicySuccess extends PolicyInitial {
  final List<PolicyModel> policyList;

  GetCompanyPolicySuccess(this.policyList);
}

final class GetCompanyPolicyFailure extends PolicyInitial {
  final String errorMessage;

  GetCompanyPolicyFailure({required this.errorMessage});
}
