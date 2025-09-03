class ApiConstants {
  static const String baseUrl = 'https://api.evolv28.com/v1';
  
  // Auth endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  static const String refreshToken = '/auth/refresh';
  static const String logout = '/auth/logout';
  
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
