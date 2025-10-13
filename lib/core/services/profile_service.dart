import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/api_constants.dart';

class ProfileService {
  static final ProfileService _instance = ProfileService._internal();
  factory ProfileService() => _instance;
  ProfileService._internal();

  final Dio _dio = Dio();

  /// Get profile details by email
  ///
  /// [emailId] - The email ID to get profile details for
  /// Returns the profile details if successful, null otherwise
  Future<Map<String, dynamic>?> getProfileDetailsByEmail(String emailId) async {
    try {
      print('👤 ProfileService: Getting profile details for email: $emailId');

      // Get stored token for authorization
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('user_token') ?? '';

      if (token.isEmpty) {
        print('👤 ProfileService: No token found, skipping profile details fetch');
        return null;
      }

      final payload = {'email_id': emailId};

      final response = await _dio.post(
        '${ApiConstants.baseUrl}${ApiConstants.getProfileDetailsByEmail}',
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
        '👤 ProfileService: Profile details response - Status: ${response.statusCode}',
      );
      print(
        '👤 ProfileService: Profile details response data: ${response.data}',
      );

      if (response.statusCode == 200) {
        // Parse the response
        final responseData = response.data;
        if (responseData is Map<String, dynamic>) {
          print('👤 ProfileService: Profile details retrieved successfully');
          return responseData;
        } else {
          print('👤 ProfileService: Invalid response format');
          return null;
        }
      } else {
        print(
          '👤 ProfileService: Profile details fetch failed with status: ${response.statusCode}',
        );
        return null;
      }
    } catch (e) {
      print('👤 ProfileService: Error getting profile details: $e');
      return null;
    }
  }
}
