part of 'view_doucments_bloc.dart';

@immutable
sealed class ViewDoucmentsEvent {}

class FetchEmployeeDocument extends ViewDoucmentsEvent {}
