import 'package:bloc/bloc.dart';

part 'session_event.dart';
part 'session_state.dart';

class SessionBloc extends Bloc<SessionEvent, SessionState> {
  SessionBloc() : super(SessionInitial()) {
    on<SessionExpired>(_onSessionExpired);
    on<UserNotFound>(_onUserNotFound);
  }

  Future<void> _onSessionExpired(
      SessionExpired event, Emitter<SessionState> emit) async {
    emit(SessionExpiredState());
  }

  Future<void> _onUserNotFound(
      UserNotFound event, Emitter<SessionState> emit) async {
    emit(UserNotFoundState());
  }
}
