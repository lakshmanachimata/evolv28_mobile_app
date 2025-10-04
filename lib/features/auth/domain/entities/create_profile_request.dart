class CreateProfileRequest {
  final String firstName;
  final String lastName;
  final String emailId;

  CreateProfileRequest({
    required this.firstName,
    required this.lastName,
    required this.emailId,
  });

  Map<String, dynamic> toJson() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'email_id': emailId,
    };
  }
}
