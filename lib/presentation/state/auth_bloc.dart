import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/repository/backend_repository.dart';

abstract class AuthEvent {}
class AuthLoginRequested extends AuthEvent {}
class AuthLogoutRequested extends AuthEvent {}
class AuthCheckStatus extends AuthEvent {}

abstract class AuthState {}
class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}
class AuthAuthenticated extends AuthState {}
class AuthUnauthenticated extends AuthState {}
class AuthError extends AuthState {
  final String message;
  AuthError(this.message);
}

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final BackendRepository backendRepository;
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);

  AuthBloc(this.backendRepository) : super(AuthInitial()) {
    on<AuthCheckStatus>((event, emit) async {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      if (token != null) {
        emit(AuthAuthenticated());
      } else {
        emit(AuthUnauthenticated());
      }
    });

    on<AuthLoginRequested>((event, emit) async {
      emit(AuthLoading());
      try {
        final GoogleSignInAccount? account = await _googleSignIn.signIn();
        if (account == null) {
          emit(AuthUnauthenticated());
          return;
        }

        if (!account.email.endsWith('@iitj.ac.in')) {
          await _googleSignIn.signOut();
          emit(AuthError('Restricted strictly to @iitj.ac.in domains.'));
          return;
        }

        final GoogleSignInAuthentication auth = await account.authentication;
        final bool success = await backendRepository.authenticateWithGoogle(auth.idToken!);
        
        if (success) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('jwt_token', auth.idToken!);
          emit(AuthAuthenticated());
        } else {
          emit(AuthError('Backend authentication failed.'));
        }
      } catch (e) {
        emit(AuthError(e.toString()));
      }
    });

    on<AuthLogoutRequested>((event, emit) async {
      await _googleSignIn.signOut();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('jwt_token');
      emit(AuthUnauthenticated());
    });
  }
}
