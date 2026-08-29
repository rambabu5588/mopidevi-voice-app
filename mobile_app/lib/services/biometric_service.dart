import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();

  // Storage keys
  static const String _keyHasLoggedInOnDevice = 'has_logged_in_on_device';
  static const String _keyLastUserId = 'last_user_id';
  static const String _keyLastUserName = 'last_user_name';
  static const String _keyLastUserRole = 'last_user_role';
  static const String _keyLastIsAdmin = 'last_is_admin';

  static const String _keyBiometricEnabled = 'biometric_enabled';
  static const String _keySavedPassword = 'biometric_password';
  static const String _keyHasPromptedFirstTime = 'biometric_has_prompted';

  /// Check if the device hardware supports biometrics (fingerprint / face)
  static Future<bool> isDeviceSupported() async {
    try {
      final isSupported = await _auth.isDeviceSupported();
      final canCheck = await _auth.canCheckBiometrics;
      return isSupported || canCheck;
    } catch (e) {
      debugPrint('Biometric check error: $e');
      return false;
    }
  }

  /// Get list of available biometrics on device
  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (e) {
      debugPrint('Get biometrics error: $e');
      return [];
    }
  }

  /// Check if ANY user has previously logged in successfully on this device
  static Future<bool> hasLoggedInBefore() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyHasLoggedInOnDevice) ?? false;
  }

  /// Get the last successfully logged-in account details
  static Future<Map<String, dynamic>?> getLastLoginAccount() async {
    final prefs = await SharedPreferences.getInstance();
    final hasLogged = prefs.getBool(_keyHasLoggedInOnDevice) ?? false;
    final userId = prefs.getString(_keyLastUserId);

    if (hasLogged && userId != null && userId.isNotEmpty) {
      return {
        'userId': userId,
        'userName': prefs.getString(_keyLastUserName) ?? userId,
        'role': prefs.getString(_keyLastUserRole) ?? 'operator',
        'isAdmin': prefs.getBool(_keyLastIsAdmin) ?? false,
      };
    }
    return null;
  }

  /// Record a successful login on this device
  static Future<void> recordSuccessfulLogin({
    required String userId,
    required String userName,
    required String role,
    required bool isAdmin,
    String? password,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyHasLoggedInOnDevice, true);
    await prefs.setString(_keyLastUserId, userId);
    await prefs.setString(_keyLastUserName, userName);
    await prefs.setString(_keyLastUserRole, role);
    await prefs.setBool(_keyLastIsAdmin, isAdmin);

    if (password != null && password.isNotEmpty) {
      await prefs.setString(_keySavedPassword, password);
    }
  }

  /// Check if biometric authentication is enabled
  static Future<bool> isBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyBiometricEnabled) ?? false;
  }

  /// Check if we have saved biometric credentials for quick login
  static Future<bool> hasSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final isEnabled = prefs.getBool(_keyBiometricEnabled) ?? false;
    final hasLogged = prefs.getBool(_keyHasLoggedInOnDevice) ?? false;
    final userId = prefs.getString(_keyLastUserId);
    return isEnabled && hasLogged && userId != null && userId.isNotEmpty;
  }

  /// Get saved credentials
  static Future<Map<String, dynamic>?> getSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString(_keyLastUserId);
    final userName = prefs.getString(_keyLastUserName) ?? '';
    final password = prefs.getString(_keySavedPassword) ?? 'User\$1234';
    final isAdmin = prefs.getBool(_keyLastIsAdmin) ?? false;
    final role = prefs.getString(_keyLastUserRole) ?? 'operator';

    if (userId != null && userId.isNotEmpty) {
      return {
        'userId': userId,
        'userName': userName,
        'password': password,
        'isAdmin': isAdmin,
        'role': role,
      };
    }
    return null;
  }

  /// Save biometric credentials after 1st time login or when enabling
  static Future<void> saveBiometricCredentials({
    required String userId,
    required String userName,
    required String password,
    required bool isAdmin,
    String role = 'operator',
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyHasLoggedInOnDevice, true);
    await prefs.setBool(_keyBiometricEnabled, true);
    await prefs.setString(_keyLastUserId, userId);
    await prefs.setString(_keyLastUserName, userName);
    await prefs.setString(_keyLastUserRole, role);
    await prefs.setString(_keySavedPassword, password);
    await prefs.setBool(_keyLastIsAdmin, isAdmin);
    await prefs.setBool(_keyHasPromptedFirstTime, true);
  }

  /// Mark first-time prompt as seen
  static Future<void> markPrompted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyHasPromptedFirstTime, true);
  }

  /// Prompt for fingerprint / biometric authentication
  static Future<bool> authenticate({
    String reason = 'మోపిదేవి ఆలయ AI సిస్టమ్ లాగిన్ కొరకు మీ వేలిముద్రను తాకండి (Touch Fingerprint sensor to Login)',
  }) async {
    try {
      final isSupported = await isDeviceSupported();
      if (!isSupported) return false;

      return await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
    } catch (e) {
      debugPrint('Biometric auth error: $e');
      return false;
    }
  }

  /// Disable biometric login
  static Future<void> disableBiometrics() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyBiometricEnabled, false);
  }

  /// Clear all saved device & biometric login data
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyHasLoggedInOnDevice);
    await prefs.remove(_keyLastUserId);
    await prefs.remove(_keyLastUserName);
    await prefs.remove(_keyLastUserRole);
    await prefs.remove(_keyLastIsAdmin);
    await prefs.remove(_keyBiometricEnabled);
    await prefs.remove(_keySavedPassword);
    await prefs.remove(_keyHasPromptedFirstTime);
  }
}
