import 'package:flutter/foundation.dart';
import '../../../services/family/features/health_records_service.dart';
import '../../../services/family/common/family_exceptions.dart';

enum ApprovalState { idle, submitting, success, error }

class HealthRecordApprovalController extends ChangeNotifier {
  final FamilyHealthRecordsService _healthRecordsService = FamilyHealthRecordsService();
  
  ApprovalState _state = ApprovalState.idle;
  String? _errorMessage;
  
  ApprovalState get state => _state;
  String? get errorMessage => _errorMessage;
  bool get isSubmitting => _state == ApprovalState.submitting;

  Future<bool> approveRecord(
    String recordId, {
    required String visibilityType,
    List<String>? visibilityUserIds,
    List<String>? visibilityFamilyCircles,
  }) async {
    _state = ApprovalState.submitting;
    _errorMessage = null;
    notifyListeners();

    try {
      await _healthRecordsService.approveHealthRecord(
        recordId,
        visibilityType: visibilityType,
        visibilityUserIds: visibilityUserIds,
        visibilityFamilyCircles: visibilityFamilyCircles,
      );
      _state = ApprovalState.success;
      notifyListeners();
      return true;
    } catch (e) {
      _state = ApprovalState.error;
      if (e is ApiException) {
        _errorMessage = e.detail ?? e.message;
      } else if (e is NetworkException) {
        _errorMessage = e.message;
      } else {
        _errorMessage = 'An unexpected error occurred';
      }
      notifyListeners();
      return false;
    }
  }

  Future<bool> rejectRecord(String recordId) async {
    _state = ApprovalState.submitting;
    _errorMessage = null;
    notifyListeners();

    try {
      await _healthRecordsService.rejectHealthRecord(recordId);
      _state = ApprovalState.success;
      notifyListeners();
      return true;
    } catch (e) {
      _state = ApprovalState.error;
      if (e is ApiException) {
        _errorMessage = e.detail ?? e.message;
      } else if (e is NetworkException) {
        _errorMessage = e.message;
      } else {
        _errorMessage = 'An unexpected error occurred';
      }
      notifyListeners();
      return false;
    }
  }
}
