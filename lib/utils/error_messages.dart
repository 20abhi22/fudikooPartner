import 'package:dio/dio.dart';

/// Converts a raw exception into a short sentence that is safe to show in a
/// snack bar. Dio stack text ("DioException [connection timeout] ...") must
/// never reach the user, so every service failure goes through here.
String friendlyErrorMessage(
  Object? error, {
  String fallback = 'Something went wrong. Please try again.',
}) {
  if (error is DioException) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'The server is taking too long to respond. '
            'Please check your connection and try again.';
      case DioExceptionType.connectionError:
        return 'No internet connection. '
            'Please check your network and try again.';
      case DioExceptionType.badCertificate:
        return 'We could not connect securely to the server. '
            'Please try again later.';
      case DioExceptionType.cancel:
        return 'The request was cancelled. Please try again.';
      case DioExceptionType.badResponse:
        return _serverMessage(error.response) ??
            statusCodeMessage(error.response?.statusCode, fallback: fallback);
      case DioExceptionType.unknown:
        if (_looksLikeNetworkIssue(error)) {
          return 'No internet connection. '
              'Please check your network and try again.';
        }
        return fallback;
    }
  }

  return fallback;
}

/// A friendly sentence for a plain HTTP status code, for responses that come
/// back without an exception.
String statusCodeMessage(
  int? statusCode, {
  String fallback = 'Something went wrong. Please try again.',
}) {
  if (statusCode == null) return fallback;
  if (statusCode == 400 || statusCode == 422) {
    return 'Please check the details you entered and try again.';
  }
  if (statusCode == 401) {
    return 'Your login details are incorrect or your session has expired.';
  }
  if (statusCode == 403) {
    return 'You do not have permission to do that.';
  }
  if (statusCode == 404) {
    return 'We could not find what you were looking for.';
  }
  if (statusCode == 429) {
    return 'Too many attempts. Please wait a moment and try again.';
  }
  if (statusCode >= 500) {
    return 'The server is having trouble right now. '
        'Please try again in a little while.';
  }
  return fallback;
}

/// The API already returns readable messages ("Invalid credentials"), so use
/// one when it is there.
String? _serverMessage(Response<dynamic>? response) {
  final data = response?.data;
  if (data is Map) {
    for (final key in const ['message', 'error', 'errors']) {
      final value = data[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
      if (value is List && value.isNotEmpty && value.first is String) {
        return (value.first as String).trim();
      }
      if (value is Map && value.values.isNotEmpty) {
        final first = value.values.first;
        if (first is String && first.trim().isNotEmpty) return first.trim();
        if (first is List && first.isNotEmpty && first.first is String) {
          return (first.first as String).trim();
        }
      }
    }
  }
  return null;
}

bool _looksLikeNetworkIssue(DioException error) {
  final details = '${error.error} ${error.message}';
  return details.contains('SocketException') ||
      details.contains('HandshakeException') ||
      details.contains('Failed host lookup') ||
      details.contains('Connection refused') ||
      details.contains('Network is unreachable');
}
