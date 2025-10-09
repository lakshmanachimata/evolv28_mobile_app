class DeviceMappingResponse {
  final bool error;
  final String message;
  final dynamic data;

  DeviceMappingResponse({
    required this.error,
    required this.message,
    this.data,
  });

  factory DeviceMappingResponse.fromJson(Map<String, dynamic> json) {
    return DeviceMappingResponse(
      error: json['error'] ?? true,
      message: json['message'] ?? 'Unknown error',
      data: json['data'],
    );
  }
}
