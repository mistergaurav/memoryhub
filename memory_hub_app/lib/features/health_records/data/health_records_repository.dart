import '../models/health_record.dart';
import 'health_records_api.dart';

class HealthRecordsRepository {
  final HealthRecordsApi _api = HealthRecordsApi();
  
  final Map<String, List<HealthRecord>> _cache = {};
  DateTime? _lastFetch;
  static const _cacheDuration = Duration(minutes: 5);

  bool get _isCacheValid {
    if (_lastFetch == null) return false;
    return DateTime.now().difference(_lastFetch!) < _cacheDuration;
  }

  void clearCache() {
    _cache.clear();
    _lastFetch = null;
  }

  Future<Map<String, dynamic>> getDashboard() async {
    return await _api.getDashboard();
  }

  Future<List<HealthRecord>> getRecords({
    int page = 1,
    int limit = 50,
    String? recordType,
    String? severity,
    String? subjectType,
    bool forceRefresh = false,
  }) async {
    final cacheKey = '${recordType ?? 'all'}_${severity ?? 'all'}_${subjectType ?? 'all'}';
    
    if (!forceRefresh && _isCacheValid && _cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    final response = await _api.getRecords(
      page: page,
      limit: limit,
      recordType: recordType,
      severity: severity,
      subjectType: subjectType,
    );

    final items = response['data'] ?? response['items'] ?? [];
    final records = (items as List)
        .map((item) => HealthRecord.fromJson(item as Map<String, dynamic>))
        .toList();

    _cache[cacheKey] = records;
    _lastFetch = DateTime.now();

    return records;
  }

  Future<HealthRecord> getRecordById(String recordId) async {
    final data = await _api.getRecordById(recordId);
    return HealthRecord.fromJson(data);
  }

  Future<HealthRecord> createRecord(Map<String, dynamic> recordData) async {
    final data = await _api.createRecord(recordData);
    clearCache();
    return HealthRecord.fromJson(data);
  }

  Future<HealthRecord> updateRecord(String recordId, Map<String, dynamic> recordData) async {
    final data = await _api.updateRecord(recordId, recordData);
    clearCache();
    return HealthRecord.fromJson(data);
  }

  Future<void> deleteRecord(String recordId) async {
    await _api.deleteRecord(recordId);
    clearCache();
  }

  Future<Map<String, dynamic>> createReminder(Map<String, dynamic> reminderData) async {
    final data = await _api.createReminder(reminderData);
    clearCache();
    return data;
  }

  Future<List<dynamic>> getReminders({String? recordId}) async {
    return await _api.getReminders(recordId: recordId);
  }

  Future<void> deleteReminder(String reminderId) async {
    await _api.deleteReminder(reminderId);
    clearCache();
  }

  Map<String, int> getRecordTypeStats(List<HealthRecord> records) {
    final stats = <String, int>{};
    for (final record in records) {
      stats[record.recordType] = (stats[record.recordType] ?? 0) + 1;
    }
    return stats;
  }

  List<HealthRecord> filterByRecordType(List<HealthRecord> records, String recordType) {
    if (recordType == 'all') return records;
    return records.where((r) => r.recordType == recordType).toList();
  }

  List<HealthRecord> filterBySeverity(List<HealthRecord> records, String severity) {
    return records.where((r) => r.severity == severity).toList();
  }

  List<HealthRecord> filterBySubjectType(List<HealthRecord> records, String subjectType) {
    return records.where((r) => r.subjectType == subjectType).toList();
  }

  List<HealthRecord> filterByDateRange(
    List<HealthRecord> records,
    DateTime startDate,
    DateTime endDate,
  ) {
    return records.where((r) {
      return r.recordDate.isAfter(startDate) && r.recordDate.isBefore(endDate);
    }).toList();
  }

  List<HealthRecord> sortByDate(List<HealthRecord> records, {bool ascending = false}) {
    final sorted = List<HealthRecord>.from(records);
    sorted.sort((a, b) => ascending
        ? a.recordDate.compareTo(b.recordDate)
        : b.recordDate.compareTo(a.recordDate));
    return sorted;
  }

  List<HealthRecord> getRecentRecords(List<HealthRecord> records, {int days = 30}) {
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    return records.where((r) => r.recordDate.isAfter(cutoffDate)).toList();
  }
}
