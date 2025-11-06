import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../../../services/auth_service.dart';
import '../../../services/api_service.dart';
import '../../../services/family/family_service.dart';
import '../../../services/family/common/family_exceptions.dart';

enum SubmissionState {
  idle,
  submitting,
  success,
  error,
}

class AddHealthRecordController extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final ApiService _apiService = ApiService();
  final FamilyService _familyService = FamilyService();

  SubmissionState _state = SubmissionState.idle;
  String? _errorMessage;
  bool _canRetry = false;
  int _retryCount = 0;
  static const int _maxRetries = 2;

  SubmissionState get state => _state;
  String? get errorMessage => _errorMessage;
  bool get canRetry => _canRetry;
  bool get isSubmitting => _state == SubmissionState.submitting;
  bool get hasError => _state == SubmissionState.error;
  bool get isSuccess => _state == SubmissionState.success;

  void clearError() {
    _errorMessage = null;
    _canRetry = false;
    _state = SubmissionState.idle;
    notifyListeners();
  }

  String? validateTitle(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Title is required';
    }
    if (value.trim().length < 3) {
      return 'Title must be at least 3 characters';
    }
    if (value.trim().length > 100) {
      return 'Title must be less than 100 characters';
    }
    return null;
  }

  String? validateDescription(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Description is required';
    }
    if (value.trim().length < 10) {
      return 'Description must be at least 10 characters';
    }
    return null;
  }

  String? validateProvider(String? value) {
    if (value != null && value.trim().isNotEmpty && value.trim().length > 100) {
      return 'Provider name must be less than 100 characters';
    }
    return null;
  }

  String? validateLocation(String? value) {
    if (value != null && value.trim().isNotEmpty && value.trim().length > 200) {
      return 'Location must be less than 200 characters';
    }
    return null;
  }

  String? validateSubjectSelection({
    required String subjectCategory,
    String? selectedUserId,
    String? selectedFamilyMemberId,
    String? selectedFriendCircleId,
  }) {
    if (subjectCategory == 'user' && selectedUserId == null) {
      return 'Please select a user from the search results';
    }
    if (subjectCategory == 'family' && selectedFamilyMemberId == null) {
      return 'Please select a family member from the dropdown';
    }
    if (subjectCategory == 'friend' && selectedFriendCircleId == null) {
      return 'Please select a friend circle from the dropdown';
    }
    return null;
  }

  String? validateReminderDate({
    required bool enableReminder,
    DateTime? reminderDueDate,
  }) {
    if (enableReminder && reminderDueDate == null) {
      return 'Please select a reminder due date';
    }
    return null;
  }

  String _mapExceptionToUserMessage(dynamic error) {
    if (error is ApiException) {
      _canRetry = false;
      
      switch (error.statusCode) {
        case 400:
          if (error.errors != null && error.errors!.isNotEmpty) {
            final errorList = error.errors!.entries
                .map((e) => '${e.key}: ${e.value}')
                .join(', ');
            return 'Invalid data: $errorList';
          }
          return error.detail ?? 'The data you entered is invalid. Please check and try again.';
        
        case 403:
          return 'You don\'t have permission to create health records. Please check your account settings.';
        
        case 404:
          return 'The selected family member or circle was not found. Please refresh and try again.';
        
        case 409:
          return 'A similar health record already exists. Please check your records.';
        
        case 422:
          if (error.errors != null && error.errors!.isNotEmpty) {
            final errorMessages = <String>[];
            error.errors!.forEach((field, message) {
              errorMessages.add('$field: $message');
            });
            return 'Validation errors:\n${errorMessages.join('\n')}';
          }
          return error.detail ?? 'The information you entered is not valid. Please review and correct.';
        
        case 429:
          return 'Too many requests. Please wait a moment and try again.';
        
        case 500:
        case 502:
        case 503:
          _canRetry = true;
          return 'The server is experiencing issues. Please try again in a moment.';
        
        default:
          _canRetry = error.statusCode >= 500;
          return error.detail ?? 'Failed to create health record. Please try again.';
      }
    } else if (error is NetworkException) {
      _canRetry = true;
      
      if (error.statusCode == 408 || error.message.contains('timeout')) {
        return 'Request timed out. Please check your internet connection and try again.';
      }
      
      if (error.message.contains('connection') || error.message.contains('network')) {
        return 'Network connection failed. Please check your internet connection and try again.';
      }
      
      return 'Network error occurred. Please check your connection and try again.';
    } else if (error is AuthException) {
      _canRetry = false;
      return 'Your session has expired. Please log in again.';
    } else {
      _canRetry = false;
      final errorStr = error.toString();
      if (errorStr.contains('Exception:')) {
        return errorStr.replaceAll('Exception:', '').trim();
      }
      return 'An unexpected error occurred. Please try again.';
    }
  }

  Future<bool> submitHealthRecord({
    required String recordType,
    required String title,
    required String description,
    required DateTime selectedDate,
    required String provider,
    required String location,
    required String severity,
    required String notes,
    required bool isConfidential,
    required String subjectCategory,
    String? selectedUserId,
    String? selectedFamilyMemberId,
    String? selectedFriendCircleId,
    bool enableReminder = false,
    DateTime? reminderDueDate,
    String? reminderType,
  }) async {
    _state = SubmissionState.submitting;
    _errorMessage = null;
    _canRetry = false;
    notifyListeners();

    try {
      // Get current user's ObjectId from /users/me endpoint
      final currentUser = await _apiService.getCurrentUser();
      final currentUserObjectId = currentUser.id;

      final Map<String, dynamic> recordData = {
        'record_type': recordType,
        'title': title.trim(),
        'description': description.trim(),
        'date': DateFormat('yyyy-MM-dd').format(selectedDate),
        'provider': provider.trim(),
        'location': location.trim(),
        'severity': severity,
        'notes': notes.trim(),
        'medications': [],
        'attachments': [],
        'is_confidential': isConfidential,
      };

      if (subjectCategory == 'myself') {
        recordData['subject_type'] = 'self';
        recordData['subject_user_id'] = currentUserObjectId;
      } else if (subjectCategory == 'user') {
        recordData['subject_type'] = 'self';
        recordData['subject_user_id'] = selectedUserId;
      } else if (subjectCategory == 'family') {
        recordData['subject_type'] = 'family';
        recordData['subject_family_member_id'] = selectedFamilyMemberId;
      } else if (subjectCategory == 'friend') {
        recordData['subject_type'] = 'friend';
        recordData['subject_friend_circle_id'] = selectedFriendCircleId;
      }

      await _familyService.createHealthRecord(recordData);

      _state = SubmissionState.success;
      _retryCount = 0;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _mapExceptionToUserMessage(e);
      _state = SubmissionState.error;
      notifyListeners();
      return false;
    }
  }

  Future<bool> retrySubmission({
    required String recordType,
    required String title,
    required String description,
    required DateTime selectedDate,
    required String provider,
    required String location,
    required String severity,
    required String notes,
    required bool isConfidential,
    required String subjectCategory,
    String? selectedUserId,
    String? selectedFamilyMemberId,
    String? selectedFriendCircleId,
    bool enableReminder = false,
    DateTime? reminderDueDate,
    String? reminderType,
  }) async {
    if (_retryCount >= _maxRetries) {
      _errorMessage = 'Maximum retry attempts reached. Please try again later.';
      _canRetry = false;
      notifyListeners();
      return false;
    }

    _retryCount++;
    
    return await submitHealthRecord(
      recordType: recordType,
      title: title,
      description: description,
      selectedDate: selectedDate,
      provider: provider,
      location: location,
      severity: severity,
      notes: notes,
      isConfidential: isConfidential,
      subjectCategory: subjectCategory,
      selectedUserId: selectedUserId,
      selectedFamilyMemberId: selectedFamilyMemberId,
      selectedFriendCircleId: selectedFriendCircleId,
      enableReminder: enableReminder,
      reminderDueDate: reminderDueDate,
      reminderType: reminderType,
    );
  }

  void reset() {
    _state = SubmissionState.idle;
    _errorMessage = null;
    _canRetry = false;
    _retryCount = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    reset();
    super.dispose();
  }
}
