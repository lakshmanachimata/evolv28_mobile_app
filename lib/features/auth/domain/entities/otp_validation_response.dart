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
    return OtpValidationResponse(
      error: json['error'] ?? false,
      message: json['message'] ?? '',
      data: OtpValidationData.fromJson(json['data'] ?? {}),
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
    return OtpValidationData(
      userId: json['UserId'],
      logId: json['LogId'],
      emailId: json['EmailId'],
      roleId: json['RoleId'],
      contactno: json['contactno'],
      delaytime: json['delaytime'],
      sessid: json['sessid'],
      allowDevice: json['allowDevice'],
      category: json['category'],
      subCategory: json['subCategory'],
      userName: json['UserName'],
      gender: json['gender'],
      country: json['country'],
      age: json['age'],
      imagePath: json['image_path'],
      fname: json['fname'],
      lname: json['lname'],
      profilepicpath: json['profilepicpath'],
      loginSource: json['login_source'],
      devices: json['devices'] ?? [],
      token: json['token'],
    );
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
