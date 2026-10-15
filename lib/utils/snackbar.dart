import 'package:flutter/material.dart';
import 'package:fudiko/components/apptext.dart';
import 'package:fudiko/utils/constants.dart';

/// The one place a snack bar is built in this app.
///
/// Every screen goes through [showSuccessSnack] / [showErrorSnack] /
/// [showInfoSnack] / [showStatusSnack] so the shape, colour and typography stay
/// identical everywhere, and so messages get translated — [AppText] runs the
/// text through `TranslatorService`, which a plain `Text` would skip.
///
/// Usage: `showSuccessSnack(context, "Password updated")` /
/// `showErrorSnack(context, response.message)`.
void showAppSnack(
  BuildContext context,
  String message, {
  required Color background,
  Duration duration = const Duration(seconds: 3),
  SnackBarAction? action,
}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null || message.trim().isEmpty) return;

  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: AppText(
          text: message,
          size: 13,
          fontWeight: FontWeight.w500,
          color: snackTextColor,
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: background,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        action: action,
      ),
    );
}

void showSuccessSnack(
  BuildContext context,
  String message, {
  Duration duration = const Duration(seconds: 3),
  SnackBarAction? action,
}) => showAppSnack(
  context,
  message,
  background: snackSuccessColor,
  duration: duration,
  action: action,
);

void showErrorSnack(
  BuildContext context,
  String message, {
  Duration duration = const Duration(seconds: 3),
  SnackBarAction? action,
}) => showAppSnack(
  context,
  message,
  background: snackErrorColor,
  duration: duration,
  action: action,
);

void showInfoSnack(
  BuildContext context,
  String message, {
  Duration duration = const Duration(seconds: 3),
  SnackBarAction? action,
}) => showAppSnack(
  context,
  message,
  background: snackInfoColor,
  duration: duration,
  action: action,
);

/// Picks the colour from an API `status` flag.
void showStatusSnack(
  BuildContext context,
  bool isSuccess,
  String message, {
  Duration duration = const Duration(seconds: 3),
}) => isSuccess
    ? showSuccessSnack(context, message, duration: duration)
    : showErrorSnack(context, message, duration: duration);
