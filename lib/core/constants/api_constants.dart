class ApiConstants {
  static const String baseUrl = 'https://democurie-api.becurie.com';

  // Auth endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  static const String refreshToken = '/auth/refresh';
  static const String logout = '/auth/logout';
  static const String sendOtp = '/api/login/via_email_otp';
  static const String validateOtp = '/api/login/validate_otp';
  static const String verifyOtp = '/api/verifyotp';
  static const String deleteUser = '/api/users/delete';
  static const String userDetails = '/api/UserDetails';
  static const String allMusic = '/api/user/device/all_music';
  static const String socialLogin = '/api/auth/social';
  static const String createProfile = '/api/user/create_profile';
  static const String deviceTroubleshotLog = '/api/devicetroubleshotlog';
  static const String logsNewInsert = '/api/logs/newinsert';

  // User endpoints
  static const String profile = '/user/profile';
  static const String updateProfile = '/user/profile';
  static const String changePassword = '/user/change-password';

  // Dashboard endpoints
  static const String dashboard = '/dashboard';
  static const String notifications = '/notifications';

  // Settings endpoints
  static const String settings = '/settings';
  static const String preferences = '/user/preferences';
}
