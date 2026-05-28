class RegResponseModel {
  final bool status;
  final String message;
  final String? token;
  final Map<String, String>? fieldErrors;

  RegResponseModel({
    required this.status,
    required this.message,
    this.token,
    this.fieldErrors,
  });

  factory RegResponseModel.fromJson(Map<String, dynamic> json) {
    Map<String, String>? parsedErrors;

    if (json['errors'] != null && json['errors'] is Map<String, dynamic>) {
      parsedErrors = (json['errors'] as Map<String, dynamic>).map((key, value) {
        final messages = value is List ? value : [value.toString()];
        return MapEntry(key, messages.isNotEmpty ? messages.first : '');
      });
    }

    return RegResponseModel(
      status: json['status'] ?? false,
      message: json['message'] ?? 'Unknown error',
      token: json['token'],
      fieldErrors: parsedErrors,
    );
  }
}
