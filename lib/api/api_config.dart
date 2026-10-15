/// Production backend configuration. Every URL the app talks to is derived
/// from here so switching environments is a one-line change.
class ApiConfig {
  ApiConfig._();

  static const String host = 'admin.fudikoo.com';

  /// Origin used to resolve relative image/file paths returned by the API.
  static const String origin = 'https://$host';

  /// Base URL for all REST calls.
  static const String baseUrl = '$origin/api';
}
