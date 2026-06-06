import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/shared_pref_helper.dart';

class AuthState {
  final bool isLoggedIn;
  final int userId;
  final String userEmail;
  final String userName;
  final String userRole;

  AuthState({
    required this.isLoggedIn,
    this.userId = 0,
    required this.userEmail,
    required this.userName,
    required this.userRole,
  });

  factory AuthState.initial() {
    return AuthState(
      isLoggedIn: SharedPrefHelper.isLoggedIn(),
      userId: SharedPrefHelper.getUserId(),
      userEmail: SharedPrefHelper.getUserEmail(),
      userName: SharedPrefHelper.getUserName(),
      userRole: SharedPrefHelper.getUserRole(),
    );
  }
}

final authProvider = StateProvider<AuthState>((ref) {
  return AuthState.initial();
});