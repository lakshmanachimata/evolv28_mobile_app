import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/api_constants.dart';

class SessionService {
  static final SessionService _instance = SessionService._internal();
  factory SessionService() => _instance;
  SessionService._internal();

  final Dio _dio = Dio();

  /// Update session ID for the user
  ///
  /// [userId] - The user ID to update session for
  /// Returns the new session ID if successful, null otherwise
  Future<String?> updateSessionId(int userId) async {
    try {
      print('🔄 SessionService: Updating session ID for user: $userId');

      // Get stored token for authorization
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('user_token') ?? '';

      if (token.isEmpty) {
        print('🔄 SessionService: No token found, skipping session update');
        return null;
      }

      final payload = {'userid': userId};

      final response = await _dio.put(
        '${ApiConstants.baseUrl}${ApiConstants.updateSessid}',
        options: Options(
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
            'Authorization': token,
          },
        ),
        data: payload,
      );

      print(
        '🔄 SessionService: Session update response - Status: ${response.statusCode}',
      );
      print(
        '🔄 SessionService: Session update response data: ${response.data}',
      );

      if (response.statusCode == 200) {
        // Parse the response to get the new session ID
        final responseData = response.data;
        if (responseData is Map<String, dynamic>) {
          // The API might return the session ID in different fields
          // Check common field names
          String? sessionId =
              responseData['SessId'] ??
              responseData['session_id'] ??
              responseData['sessionId'] ??
              responseData['sessid'] ??
              responseData['id'];

          if (sessionId != null) {
            print('🔄 SessionService: New session ID received: $sessionId');

            // Update SharedPreferences with the new session ID
            // await prefs.setString('user_log_id', sessionId);
            print('🔄 SessionService: Session ID updated in SharedPreferences');

            return sessionId;
          } else {
            print('🔄 SessionService: No session ID found in response');
            return null;
          }
        } else {
          print('🔄 SessionService: Invalid response format');
          return null;
        }
      } else {
        print(
          '🔄 SessionService: Session update failed with status: ${response.statusCode}',
        );
        return null;
      }
    } catch (e) {
      print('🔄 SessionService: Error updating session ID: $e');
      return null;
    }
  }

  /// Get current session ID from SharedPreferences
  Future<String?> getCurrentSessionId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('user_log_id');
    } catch (e) {
      print('🔄 SessionService: Error getting current session ID: $e');
      return null;
    }
  }
}
