class OtpValidationResponse {
  final bool error;
  final String message;
  final OtpValidationData data;

  OtpValidationResponse({
    required this.error,
    required this.message,
    required this.data,
  });

  factory OtpValidationResponse.fromJson(Map<String, dynamic> json) {
    try {
      return OtpValidationResponse(
        error: json['error'] ?? false,
        message: json['message'] ?? '',
        data: OtpValidationData.fromJson(json['data'] ?? {}),
      );
    } catch (e) {
      print('🔐 OtpValidationResponse: Error parsing JSON: $e');
      print('🔐 OtpValidationResponse: JSON data: $json');
      // Return a default response if parsing fails
      return OtpValidationResponse(
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

class OtpValidationData {
  final String? userId;
  final String? logId;
  final String? emailId;
  final String? roleId;
  final String? contactno;
  final String? delaytime;
  final String? sessid;
  final String? allowDevice;
  final String? category;
  final String? subCategory;
  final String? userName;
  final String? gender;
  final String? country;
  final String? age;
  final String? imagePath;
  final String? fname;
  final String? lname;
  final String? profilepicpath;
  final String? loginSource;
  final List<dynamic> devices;
  final String? token;

  OtpValidationData({
    this.userId,
    this.logId,
    this.emailId,
    this.roleId,
    this.contactno,
    this.delaytime,
    this.sessid,
    this.allowDevice,
    this.category,
    this.subCategory,
    this.userName,
    this.gender,
    this.country,
    this.age,
    this.imagePath,
    this.fname,
    this.lname,
    this.profilepicpath,
    this.loginSource,
    this.devices = const [],
    this.token,
  });

  factory OtpValidationData.fromJson(Map<String, dynamic> json) {
    try {
      return OtpValidationData(
        userId: json['UserId']?.toString(),
        logId: json['LogId']?.toString(),
        emailId: json['EmailId']?.toString(),
        roleId: json['RoleId']?.toString(),
        contactno: json['contactno']?.toString(),
        delaytime: json['delaytime']?.toString(),
        sessid: json['sessid']?.toString(),
        allowDevice: json['allowDevice']?.toString(),
        category: json['category']?.toString(),
        subCategory: json['subCategory']?.toString(),
        userName: json['UserName']?.toString(),
        gender: json['gender']?.toString(),
        country: json['country']?.toString(),
        age: json['age']?.toString(),
        imagePath: json['image_path']?.toString(),
        fname: json['fname']?.toString(),
        lname: json['lname']?.toString(),
        profilepicpath: json['profilepicpath']?.toString(),
        loginSource: json['login_source']?.toString(),
        devices: json['devices'] is List ? json['devices'] : [],
        token: json['token']?.toString(),
      );
    } catch (e) {
      print('🔐 OtpValidationData: Error parsing JSON: $e');
      print('🔐 OtpValidationData: JSON data: $json');
      // Return default data if parsing fails
      return OtpValidationData();
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'UserId': userId,
      'LogId': logId,
      'EmailId': emailId,
      'RoleId': roleId,
      'contactno': contactno,
      'delaytime': delaytime,
      'sessid': sessid,
      'allowDevice': allowDevice,
      'category': category,
      'subCategory': subCategory,
      'UserName': userName,
      'gender': gender,
      'country': country,
      'age': age,
      'image_path': imagePath,
      'fname': fname,
      'lname': lname,
      'profilepicpath': profilepicpath,
      'login_source': loginSource,
      'devices': devices,
      'token': token,
    };
  }
}
