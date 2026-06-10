import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/shared_pref_helper.dart';
import '../services/api_service.dart';

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

Future<bool> login(WidgetRef ref, String email, String password) async {
  final result = await ApiService.login(email, password);
  
  if (result['success'] == true) {
    final user = result['user'];
    final userId = user['id'];
    final userEmail = user['email'];
    final userName = user['name'];
    final userRole = user['role'];
    
    await SharedPrefHelper.setLoggedIn(true);
    await SharedPrefHelper.setUserId(userId);
    await SharedPrefHelper.setUserEmail(userEmail);
    await SharedPrefHelper.setUserName(userName);
    await SharedPrefHelper.setUserRole(userRole);

    ref.read(authProvider.notifier).state = AuthState(
      isLoggedIn: true,
      userId: userId,
      userEmail: userEmail,
      userName: userName,
      userRole: userRole,
    );
    return true;
  }
  return false;
}

Future<void> logout(WidgetRef ref) async {
  await SharedPrefHelper.logout();
  ref.read(authProvider.notifier).state = AuthState.initial();
}