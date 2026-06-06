import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefHelper {
  static late SharedPreferences _prefs;
  
  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyUserId = 'user_id';
  static const String _keyUserEmail = 'user_email';
  static const String _keyUserName = 'user_name';
  static const String _keyUserRole = 'user_role';
  static const String _keyThemeMode = 'theme_mode';
  static const String _keyRememberEmail = 'remember_email';
  static const String _keySavedEmail = 'saved_email';
  
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }
  
  static Future<void> setLoggedIn(bool isLoggedIn) async {
    await _prefs.setBool(_keyIsLoggedIn, isLoggedIn);
  }
  
  static bool isLoggedIn() {
    return _prefs.getBool(_keyIsLoggedIn) ?? false;
  }
  
  static Future<void> setUserId(int userId) async {
    await _prefs.setInt(_keyUserId, userId);
  }
  
  static int getUserId() {
    return _prefs.getInt(_keyUserId) ?? 0;
  }
  
  static Future<void> setUserEmail(String email) async {
    await _prefs.setString(_keyUserEmail, email);
  }
  
  static String getUserEmail() {
    return _prefs.getString(_keyUserEmail) ?? '';
  }
  
  static Future<void> setUserName(String name) async {
    await _prefs.setString(_keyUserName, name);
  }
  
  static String getUserName() {
    return _prefs.getString(_keyUserName) ?? '';
  }
  
  static Future<void> setUserRole(String role) async {
    await _prefs.setString(_keyUserRole, role);
  }
  
  static String getUserRole() {
    return _prefs.getString(_keyUserRole) ?? 'mahasiswa';
  }
  
  static Future<void> setRememberEmail(bool remember) async {
    await _prefs.setBool(_keyRememberEmail, remember);
  }
  
  static bool getRememberEmail() {
    return _prefs.getBool(_keyRememberEmail) ?? false;
  }
  
  static Future<void> setSavedEmail(String email) async {
    await _prefs.setString(_keySavedEmail, email);
  }
  
  static String getSavedEmail() {
    return _prefs.getString(_keySavedEmail) ?? '';
  }
  
  static Future<void> setThemeMode(String mode) async {
    await _prefs.setString(_keyThemeMode, mode);
  }
  
  static String getThemeMode() {
    return _prefs.getString(_keyThemeMode) ?? 'light';
  }
  
  static Future<void> logout() async {
    await _prefs.clear(); // Hapus semua data saat logout
  }
}