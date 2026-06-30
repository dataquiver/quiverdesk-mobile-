import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class AppStarted extends AuthEvent {}

class LoginRequested extends AuthEvent {
  final String emailOrMobile;
  final String password;
  const LoginRequested(this.emailOrMobile, this.password);
  @override
  List<Object?> get props => [emailOrMobile];
}

class LogoutRequested extends AuthEvent {}
