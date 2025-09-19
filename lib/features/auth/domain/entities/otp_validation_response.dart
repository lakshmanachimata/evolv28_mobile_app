import 'dart:convert';

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
  final String? id;
  final String? tokenid;
  final String? emailid;

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
    this.id,
    this.tokenid,
    this.emailid,
  });

  factory OtpValidationData.fromJson(Map<String, dynamic> json) {
    try {
      return OtpValidationData(
        userId: json['UserId']?.toString() ?? json['id']?.toString(),
        logId: json['LogId']?.toString(),
        emailId: json['EmailId']?.toString() ?? json['emailid']?.toString(),
        roleId: json['RoleId']?.toString() ?? json['roleid']?.toString(),
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
        devices: _parseDevices(json['devices']),
        token: json['token']?.toString() ?? json['tokenid']?.toString(),
        id: json['id']?.toString(),
        tokenid: json['tokenid']?.toString(),
        emailid: json['emailid']?.toString(),
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
      'id': id,
      'tokenid': tokenid,
      'emailid': emailid,
    };
  }

  // Helper method to safely parse devices field
  static List<dynamic> _parseDevices(dynamic devicesData) {
    try {
      if (devicesData == null) {
        return [];
      }
      
      if (devicesData is List) {
        return List.from(devicesData);
      }
      
      if (devicesData is String) {
        // If devices is a string, try to parse it as JSON
        try {
          final parsed = jsonDecode(devicesData);
          if (parsed is List) {
            return List.from(parsed);
          }
        } catch (e) {
          print('🔐 OtpValidationData: Error parsing devices string: $e');
        }
        return [];
      }
      
      // If it's any other type, return empty list
      return [];
    } catch (e) {
      print('🔐 OtpValidationData: Error parsing devices: $e');
      return [];
    }
  }
}
