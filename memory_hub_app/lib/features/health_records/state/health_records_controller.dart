import 'package:flutter/material.dart';
import '../models/health_record.dart';
import '../data/health_records_repository.dart';

enum HealthRecordsState {
  initial,
  loading,
  loaded,
  error,
  empty,
}

class HealthRecordsController extends ChangeNotifier {
  final HealthRecordsRepository _repository = HealthRecordsRepository();

  HealthRecordsState _state = HealthRecordsState.initial;
  List<HealthRecord> _allRecords = [];
  List<HealthRecord> _filteredRecords = [];
  Map<String, dynamic> _dashboard = {};
  String? _errorMessage;

  String _selectedFilter = 'all';
  String _selectedSortBy = 'date_desc';
  String? _selectedSeverity;
  String? _selectedSubjectType;

  HealthRecordsState get state => _state;
  List<HealthRecord> get records => _filteredRecords;
  Map<String, dynamic> get dashboard => _dashboard;
  String? get errorMessage => _errorMessage;
  String get selectedFilter => _selectedFilter;
  String get selectedSortBy => _selectedSortBy;
  String? get selectedSeverity => _selectedSeverity;
  String? get selectedSubjectType => _selectedSubjectType;

  bool get isLoading => _state == HealthRecordsState.loading;
  bool get hasError => _state == HealthRecordsState.error;
  bool get isEmpty => _state == HealthRecordsState.empty;
  bool get isLoaded => _state == HealthRecordsState.loaded;

  int get totalRecords => _allRecords.length;
  int get filteredCount => _filteredRecords.length;

  Future<void> loadRecords({bool forceRefresh = false}) async {
    try {
      _state = HealthRecordsState.loading;
      _errorMessage = null;
      notifyListeners();

      _allRecords = await _repository.getRecords(
        forceRefresh: forceRefresh,
      );

      _applyFilters();

      if (_filteredRecords.isEmpty) {
        _state = HealthRecordsState.empty;
      } else {
        _state = HealthRecordsState.loaded;
      }
    } catch (e) {
      _state = HealthRecordsState.error;
      _errorMessage = _extractErrorMessage(e.toString());
    } finally {
      notifyListeners();
    }
  }

  Future<void> loadDashboard() async {
    try {
      _dashboard = await _repository.getDashboard();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading dashboard: $e');
    }
  }

  void setFilter(String filter) {
    if (_selectedFilter != filter) {
      _selectedFilter = filter;
      _applyFilters();
      notifyListeners();
    }
  }

  void setSeverityFilter(String? severity) {
    if (_selectedSeverity != severity) {
      _selectedSeverity = severity;
      _applyFilters();
      notifyListeners();
    }
  }

  void setSubjectTypeFilter(String? subjectType) {
    if (_selectedSubjectType != subjectType) {
      _selectedSubjectType = subjectType;
      _applyFilters();
      notifyListeners();
    }
  }

  void setSortBy(String sortBy) {
    if (_selectedSortBy != sortBy) {
      _selectedSortBy = sortBy;
      _applySort();
      notifyListeners();
    }
  }

  void clearFilters() {
    _selectedFilter = 'all';
    _selectedSeverity = null;
    _selectedSubjectType = null;
    _applyFilters();
    notifyListeners();
  }

  void _applyFilters() {
    _filteredRecords = List.from(_allRecords);

    if (_selectedFilter != 'all') {
      _filteredRecords = _repository.filterByRecordType(_filteredRecords, _selectedFilter);
    }

    if (_selectedSeverity != null) {
      _filteredRecords = _repository.filterBySeverity(_filteredRecords, _selectedSeverity!);
    }

    if (_selectedSubjectType != null) {
      _filteredRecords = _repository.filterBySubjectType(_filteredRecords, _selectedSubjectType!);
    }

    _applySort();

    if (_filteredRecords.isEmpty && _allRecords.isNotEmpty) {
      _state = HealthRecordsState.empty;
    } else if (_filteredRecords.isNotEmpty) {
      _state = HealthRecordsState.loaded;
    }
  }

  void _applySort() {
    switch (_selectedSortBy) {
      case 'date_desc':
        _filteredRecords = _repository.sortByDate(_filteredRecords, ascending: false);
        break;
      case 'date_asc':
        _filteredRecords = _repository.sortByDate(_filteredRecords, ascending: true);
        break;
      case 'title_asc':
        _filteredRecords.sort((a, b) => a.title.compareTo(b.title));
        break;
      case 'title_desc':
        _filteredRecords.sort((a, b) => b.title.compareTo(a.title));
        break;
    }
  }

  Future<void> createRecord(Map<String, dynamic> recordData) async {
    try {
      await _repository.createRecord(recordData);
      await loadRecords(forceRefresh: true);
    } catch (e) {
      _errorMessage = _extractErrorMessage(e.toString());
      rethrow;
    }
  }

  Future<void> deleteRecord(String recordId) async {
    try {
      await _repository.deleteRecord(recordId);
      _allRecords.removeWhere((record) => record.id == recordId);
      _filteredRecords.removeWhere((record) => record.id == recordId);
      
      if (_filteredRecords.isEmpty) {
        _state = HealthRecordsState.empty;
      }
      
      notifyListeners();
    } catch (e) {
      _errorMessage = _extractErrorMessage(e.toString());
      rethrow;
    }
  }

  Map<String, int> getRecordTypeStats() {
    return _repository.getRecordTypeStats(_allRecords);
  }

  List<HealthRecord> getRecentRecords({int days = 30}) {
    return _repository.getRecentRecords(_allRecords, days: days);
  }

  int getRecentRecordsCount({int days = 30}) {
    return getRecentRecords(days: days).length;
  }

  void clearCache() {
    _repository.clearCache();
  }

  String _extractErrorMessage(String error) {
    return error.replaceAll('Exception: ', '').replaceAll('Exception:', '').trim();
  }

  @override
  void dispose() {
    _repository.clearCache();
    super.dispose();
  }
}
