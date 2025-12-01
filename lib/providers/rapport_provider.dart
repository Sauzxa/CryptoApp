import 'package:flutter/foundation.dart';

/// Simple provider to notify UI when rapport is submitted
/// Used to rebuild room UI without refreshing
class RapportProvider extends ChangeNotifier {
  String? _lastSubmittedReservationId;
  DateTime? _lastSubmitTime;

  String? get lastSubmittedReservationId => _lastSubmittedReservationId;
  DateTime? get lastSubmitTime => _lastSubmitTime;

  /// Notify that a rapport was submitted
  void notifyRapportSubmitted(String reservationId) {
    _lastSubmittedReservationId = reservationId;
    _lastSubmitTime = DateTime.now();
    notifyListeners();
  }

  /// Clear the last submission
  void clearLastSubmission() {
    _lastSubmittedReservationId = null;
    _lastSubmitTime = null;
    notifyListeners();
  }
}
