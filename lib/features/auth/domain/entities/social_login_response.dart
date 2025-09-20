class SocialLoginResponse {
  final bool error;
  final String message;
  final SocialLoginData? data;

  SocialLoginResponse({
    required this.error,
    required this.message,
    this.data,
  });

  factory SocialLoginResponse.fromJson(Map<String, dynamic> json) {
    return SocialLoginResponse(
      error: json['error'] ?? true,
      message: json['message'] ?? '',
      data: json['data'] != null ? SocialLoginData.fromJson(json['data']) : null,
    );
  }
}

class SocialLoginData {
  final String id;
  final String? logId;
  final String fname;
  final String lname;
  final String emailid;
  final String tokenid;
  final String ustatus;
  final List<dynamic> devices;

  SocialLoginData({
    required this.id,
    this.logId,
    required this.fname,
    required this.lname,
    required this.emailid,
    required this.tokenid,
    required this.ustatus,
    required this.devices,
  });

  factory SocialLoginData.fromJson(Map<String, dynamic> json) {
    return SocialLoginData(
      id: json['id']?.toString() ?? '',
      logId: json['LogId']?.toString() ?? json['logId']?.toString(),
      fname: json['fname'] ?? '',
      lname: json['lname'] ?? '',
      emailid: json['emailid'] ?? '',
      tokenid: json['tokenid'] ?? '',
      ustatus: json['ustatus']?.toString() ?? '0',
      devices: json['devices'] ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'LogId': logId,
      'fname': fname,
      'lname': lname,
      'emailid': emailid,
      'tokenid': tokenid,
      'ustatus': ustatus,
      'devices': devices,
    };
  }
}
