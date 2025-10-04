import 'otp_validation_response.dart';

class CreateProfileResponse {
  final bool error;
  final String message;
  final OtpValidationData data;

  CreateProfileResponse({
    required this.error,
    required this.message,
    required this.data,
  });

  factory CreateProfileResponse.fromJson(Map<String, dynamic> json) {
    try {
      return CreateProfileResponse(
        error: json['error'] ?? false,
        message: json['message'] ?? '',
        data: OtpValidationData.fromJson(json['data'] ?? {}),
      );
    } catch (e) {
      print('🔐 CreateProfileResponse: Error parsing JSON: $e');
      print('🔐 CreateProfileResponse: JSON data: $json');
      // Return a default response if parsing fails
      return CreateProfileResponse(
        error: true,
        message: 'Failed to parse response',
        data: OtpValidationData(),
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'error': error,
      'message': message,
      'data': data.toJson(),
    };
  }
}
