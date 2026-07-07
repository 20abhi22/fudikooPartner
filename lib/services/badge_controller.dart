import 'package:flutter/foundation.dart';

/// A simple singleton controller to notify listeners when badge counts should be refreshed.
class BadgeController extends ChangeNotifier {
  BadgeController._private();

  static final BadgeController instance = BadgeController._private();

  /// Notify listeners that badges should be refreshed.
  void refresh() => notifyListeners();
}
