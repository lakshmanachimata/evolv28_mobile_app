class SocialLoginRequest {
  final String deviceToken;
  final String emailId;
  final String fname;
  final String lname;
  final String loginSource;
  final String userKey;

  SocialLoginRequest({
    required this.deviceToken,
    required this.emailId,
    required this.fname,
    required this.lname,
    required this.loginSource,
    required this.userKey,
  });

  Map<String, dynamic> toJson() {
    return {
      'device_token': deviceToken,
      'emailid': emailId,
      'fname': fname,
      'lname': lname,
      'login_source': loginSource,
      'user_key': userKey,
    };
  }
}
