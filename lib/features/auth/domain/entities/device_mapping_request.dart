class DeviceMappingRequest {
  final String userid;
  final String maddress;

  DeviceMappingRequest({
    required this.userid,
    required this.maddress,
  });

  Map<String, dynamic> toJson() {
    return {
      'userid': userid,
      'maddress': maddress,
    };
  }
}
