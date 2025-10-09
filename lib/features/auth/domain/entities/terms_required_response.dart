class TermsRequiredResponse {
  final bool error;
  final String message;
  final bool requiresTermsAcceptance;

  TermsRequiredResponse({
    required this.error,
    required this.message,
    required this.requiresTermsAcceptance,
  });

  factory TermsRequiredResponse.termsRequired() {
    return TermsRequiredResponse(
      error: false,
      message: 'Terms and Conditions acceptance required',
      requiresTermsAcceptance: true,
    );
  }

  factory TermsRequiredResponse.error(String message) {
    return TermsRequiredResponse(
      error: true,
      message: message,
      requiresTermsAcceptance: false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'error': error,
      'message': message,
      'requiresTermsAcceptance': requiresTermsAcceptance,
    };
  }
}
