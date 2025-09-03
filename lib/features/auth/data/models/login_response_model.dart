class LoginResponseModel {
  final String token;
  final String userId;
  final String email;
  final String name;

  LoginResponseModel({
    required this.token,
    required this.userId,
    required this.email,
    required this.name,
  });

  factory LoginResponseModel.fromJson(Map<String, dynamic> json) {
    return LoginResponseModel(
      token: json['token'] ?? '',
      userId: json['userId'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
    );
  }
}
