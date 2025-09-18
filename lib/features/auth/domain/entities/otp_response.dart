class OtpResponse {
  final bool error;
  final String message;
  final OtpData data;

  OtpResponse({
    required this.error,
    required this.message,
    required this.data,
  });

  factory OtpResponse.fromJson(Map<String, dynamic> json) {
    return OtpResponse(
      error: json['error'] ?? false,
      message: json['message'] ?? '',
      data: OtpData.fromJson(json['data'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'error': error,
      'message': message,
      'data': data.toJson(),
    };
  }
}

class OtpData {
  final String emailId;
  final String source;
  final int otp;

  OtpData({
    required this.emailId,
    required this.source,
    required this.otp,
  });

  factory OtpData.fromJson(Map<String, dynamic> json) {
    return OtpData(
      emailId: json['email_id'] ?? '',
      source: json['source'] ?? '',
      otp: json['otp'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email_id': emailId,
      'source': source,
      'otp': otp,
    };
  }
}
