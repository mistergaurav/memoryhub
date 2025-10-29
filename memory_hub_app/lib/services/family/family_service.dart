import 'dart:convert';
import 'package:http/http.dart' as http;
import '../auth_service.dart';
import '../../config/api_config.dart';
import '../../models/family/family_album.dart';
import '../../models/family/family_timeline.dart';
import '../../models/family/family_milestone.dart';
import '../../models/family/family_recipe.dart';
import '../../models/family/legacy_letter.dart';
import '../../models/family/family_tradition.dart';
import '../../models/family/parental_control.dart';
import '../../models/family/family_calendar.dart';
import '../../models/user_search_result.dart';

class FamilyService {
  static String get baseUrl => ApiConfig.baseUrl;
  final AuthService _authService = AuthService();

  Future<http.Response> _handleRequest(Future<http.Response> request) async {
    try {
      final response = await request;
      if (response.statusCode == 401) {
        final newTokens = await _authService.refreshAccessToken();
        if (newTokens != null) {
          return await request;
        }
        throw Exception('Unauthorized - Please login again');
      }
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<FamilyAlbum>> getFamilyAlbums() async {
    final headers = await _authService.getAuthHeaders();
    final response = await _handleRequest(
      http.get(Uri.parse('$baseUrl/family-albums/'), headers: headers),
    );
    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);
      final List<dynamic> items = responseBody['items'] ?? [];
      return items.map((json) => FamilyAlbum.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load family albums');
    }
  }

  Future<List<AlbumPhoto>> getAlbumPhotos(String albumId) async {
    final headers = await _authService.getAuthHeaders();
    final response = await _handleRequest(
      http.get(Uri.parse('$baseUrl/family-albums/$albumId/photos'), headers: headers),
    );
    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);
      final List<dynamic> items = responseBody['items'] ?? [];
      return items.map((json) => AlbumPhoto.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load album photos');
    }
  }

  Future<List<TimelineEvent>> getTimelineEvents({String? filter}) async {
    final headers = await _authService.getAuthHeaders();
    final url = filter != null
        ? '$baseUrl/family-timeline/?filter=$filter'
        : '$baseUrl/family-timeline/';
    final response = await _handleRequest(
      http.get(Uri.parse(url), headers: headers),
    );
    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);
      final List<dynamic> items;
      
      if (responseBody is Map<String, dynamic> && responseBody['items'] != null) {
        items = responseBody['items'] as List<dynamic>;
      } else if (responseBody is List) {
        items = responseBody;
      } else {
        items = [];
      }
      
      return items.map((json) => TimelineEvent.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load timeline events');
    }
  }

  Future<List<FamilyMilestone>> getMilestones() async {
    final headers = await _authService.getAuthHeaders();
    final response = await _handleRequest(
      http.get(Uri.parse('$baseUrl/family-milestones/'), headers: headers),
    );
    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);
      final List<dynamic> items = responseBody['items'] ?? [];
      return items.map((json) => FamilyMilestone.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load milestones');
    }
  }

  Future<List<FamilyRecipe>> getRecipes() async {
    final headers = await _authService.getAuthHeaders();
    final response = await _handleRequest(
      http.get(Uri.parse('$baseUrl/family-recipes/'), headers: headers),
    );
    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);
      final List<dynamic> items = responseBody['items'] ?? [];
      return items.map((json) => FamilyRecipe.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load recipes');
    }
  }

  Future<FamilyRecipe> getRecipeDetail(String id) async {
    final headers = await _authService.getAuthHeaders();
    final response = await _handleRequest(
      http.get(Uri.parse('$baseUrl/family-recipes/$id'), headers: headers),
    );
    if (response.statusCode == 200) {
      return FamilyRecipe.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load recipe');
    }
  }

  Future<List<LegacyLetter>> getLegacyLetters() async {
    final headers = await _authService.getAuthHeaders();
    final response = await _handleRequest(
      http.get(Uri.parse('$baseUrl/legacy-letters/'), headers: headers),
    );
    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);
      final List<dynamic> items = responseBody['items'] ?? [];
      return items.map((json) => LegacyLetter.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load legacy letters');
    }
  }

  Future<List<FamilyTradition>> getTraditions() async {
    final headers = await _authService.getAuthHeaders();
    final response = await _handleRequest(
      http.get(Uri.parse('$baseUrl/family-traditions/'), headers: headers),
    );
    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);
      final List<dynamic> items = responseBody['items'] ?? [];
      return items.map((json) => FamilyTradition.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load traditions');
    }
  }

  Future<ParentalControlSettings> getParentalControls() async {
    final headers = await _authService.getAuthHeaders();
    final response = await _handleRequest(
      http.get(Uri.parse('$baseUrl/parental-controls/settings'), headers: headers),
    );
    if (response.statusCode == 200) {
      return ParentalControlSettings.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load parental controls');
    }
  }

  Future<List<ApprovalRequest>> getApprovalQueue() async {
    final headers = await _authService.getAuthHeaders();
    final response = await _handleRequest(
      http.get(Uri.parse('$baseUrl/parental-controls/approvals'), headers: headers),
    );
    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);
      final List<dynamic> items = responseBody['items'] ?? [];
      return items.map((json) => ApprovalRequest.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load approval queue');
    }
  }

  Future<void> approveRequest(String requestId) async {
    final headers = await _authService.getAuthHeaders();
    final response = await _handleRequest(
      http.post(
        Uri.parse('$baseUrl/parental-controls/approvals/$requestId/approve'),
        headers: headers,
      ),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to approve request');
    }
  }

  Future<void> rejectRequest(String requestId, String reason) async {
    final headers = await _authService.getAuthHeaders();
    final response = await _handleRequest(
      http.post(
        Uri.parse('$baseUrl/parental-controls/approvals/$requestId/reject'),
        headers: headers,
        body: jsonEncode({'reason': reason}),
      ),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to reject request');
    }
  }

  Future<List<FamilyCalendarEvent>> getCalendarEvents({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final headers = await _authService.getAuthHeaders();
    var url = '$baseUrl/family-calendar/';
    if (startDate != null && endDate != null) {
      url += '?start=${startDate.toIso8601String()}&end=${endDate.toIso8601String()}';
    }
    final response = await _handleRequest(
      http.get(Uri.parse(url), headers: headers),
    );
    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);
      final List<dynamic> items = responseBody['items'] ?? [];
      return items.map((json) => FamilyCalendarEvent.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load calendar events');
    }
  }

  Future<Map<String, dynamic>> createCalendarEvent(Map<String, dynamic> eventData) async {
    final headers = await _authService.getAuthHeaders();
    final response = await _handleRequest(
      http.post(
        Uri.parse('$baseUrl/family-calendar/events'),
        headers: headers,
        body: jsonEncode(eventData),
      ),
    );
    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to create calendar event');
    }
  }

  Future<Map<String, dynamic>> getFamilyDashboard() async {
    final headers = await _authService.getAuthHeaders();
    final response = await _handleRequest(
      http.get(Uri.parse('$baseUrl/family/dashboard'), headers: headers),
    );
    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);
      if (responseBody['data'] != null) {
        return responseBody['data'] as Map<String, dynamic>;
      }
      return responseBody;
    } else {
      throw Exception('Failed to load family dashboard');
    }
  }

  Future<List<Map<String, dynamic>>> getPersons() async {
    final headers = await _authService.getAuthHeaders();
    final response = await _handleRequest(
      http.get(Uri.parse('$baseUrl/genealogy/persons'), headers: headers),
    );
    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);
      final List<dynamic> items = responseBody['items'] ?? [];
      return items.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to load persons');
    }
  }

  Future<Map<String, dynamic>> createPerson(Map<String, dynamic> personData) async {
    final headers = await _authService.getAuthHeaders();
    final response = await _handleRequest(
      http.post(
        Uri.parse('$baseUrl/genealogy/persons'),
        headers: headers,
        body: jsonEncode(personData),
      ),
    );
    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to create person');
    }
  }

  Future<Map<String, dynamic>> updatePerson(String personId, Map<String, dynamic> personData) async {
    final headers = await _authService.getAuthHeaders();
    final response = await _handleRequest(
      http.put(
        Uri.parse('$baseUrl/genealogy/persons/$personId'),
        headers: headers,
        body: jsonEncode(personData),
      ),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to update person');
    }
  }

  Future<void> deletePerson(String personId) async {
    final headers = await _authService.getAuthHeaders();
    final response = await _handleRequest(
      http.delete(
        Uri.parse('$baseUrl/genealogy/persons/$personId'),
        headers: headers,
      ),
    );
    if (response.statusCode != 204) {
      throw Exception('Failed to delete person');
    }
  }

  Future<Map<String, dynamic>> createRelationship(Map<String, dynamic> relationshipData) async {
    final headers = await _authService.getAuthHeaders();
    final response = await _handleRequest(
      http.post(
        Uri.parse('$baseUrl/genealogy/relationships'),
        headers: headers,
        body: jsonEncode(relationshipData),
      ),
    );
    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to create relationship');
    }
  }

  Future<List<Map<String, dynamic>>> getRelationships() async {
    final headers = await _authService.getAuthHeaders();
    final response = await _handleRequest(
      http.get(Uri.parse('$baseUrl/genealogy/relationships'), headers: headers),
    );
    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);
      final List<dynamic> items = responseBody['items'] ?? [];
      return items.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to load relationships');
    }
  }

  Future<List<Map<String, dynamic>>> getFamilyTree() async {
    final headers = await _authService.getAuthHeaders();
    final response = await _handleRequest(
      http.get(Uri.parse('$baseUrl/genealogy/tree'), headers: headers),
    );
    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);
      final List<dynamic> items = responseBody['items'] ?? [];
      return items.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to load family tree');
    }
  }

  Future<List<Map<String, dynamic>>> searchPlatformUsers(String query) async {
    final headers = await _authService.getAuthHeaders();
    final response = await _handleRequest(
      http.get(
        Uri.parse('$baseUrl/genealogy/search-users?query=${Uri.encodeComponent(query)}'),
        headers: headers,
      ),
    );
    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);
      final List<dynamic> items = responseBody['items'] ?? [];
      return items.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to search users');
    }
  }

  Future<Map<String, dynamic>> sendFamilyHubInvitation(
    String personId,
    String invitedUserId,
    String? message,
  ) async {
    final headers = await _authService.getAuthHeaders();
    final invitationData = {
      'person_id': personId,
      'invited_user_id': invitedUserId,
      if (message != null && message.isNotEmpty) 'message': message,
    };
    final response = await _handleRequest(
      http.post(
        Uri.parse('$baseUrl/genealogy/invitations'),
        headers: headers,
        body: jsonEncode(invitationData),
      ),
    );
    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to send invitation');
    }
  }

  Future<List<Map<String, dynamic>>> getSentInvitations({String? statusFilter}) async {
    final headers = await _authService.getAuthHeaders();
    var url = '$baseUrl/genealogy/invitations/sent';
    if (statusFilter != null) {
      url += '?status_filter=$statusFilter';
    }
    final response = await _handleRequest(
      http.get(Uri.parse(url), headers: headers),
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to load sent invitations');
    }
  }

  Future<List<Map<String, dynamic>>> getReceivedInvitations({String? statusFilter}) async {
    final headers = await _authService.getAuthHeaders();
    var url = '$baseUrl/genealogy/invitations/received';
    if (statusFilter != null) {
      url += '?status_filter=$statusFilter';
    }
    final response = await _handleRequest(
      http.get(Uri.parse(url), headers: headers),
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to load received invitations');
    }
  }

  Future<Map<String, dynamic>> respondToInvitation(String invitationId, String action) async {
    final headers = await _authService.getAuthHeaders();
    final response = await _handleRequest(
      http.post(
        Uri.parse('$baseUrl/genealogy/invitations/$invitationId/respond'),
        headers: headers,
        body: jsonEncode({'action': action}),
      ),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to respond to invitation');
    }
  }

  Future<List<Map<String, dynamic>>> getFamilyMembers() async {
    final headers = await _authService.getAuthHeaders();
    final response = await _handleRequest(
      http.get(Uri.parse('$baseUrl/family/relationships'), headers: headers),
    );
    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);
      final List<dynamic> items = responseBody['items'] ?? [];
      return items.map((item) => {
        'id': item['related_user_id'] ?? item['id'],
        'name': item['related_user_name'] ?? item['name'] ?? 'Unknown',
        'relation_type': item['relation_type'] ?? 'family',
      }).toList();
    } else {
      throw Exception('Failed to load family members');
    }
  }

  Future<List<Map<String, dynamic>>> getFriendCircles() async {
    final headers = await _authService.getAuthHeaders();
    final response = await _handleRequest(
      http.get(Uri.parse('$baseUrl/family/circles'), headers: headers),
    );
    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);
      final List<dynamic> items = responseBody['items'] ?? [];
      return items.map((item) => {
        'id': item['id'] ?? '',
        'name': item['name'] ?? 'Unknown',
        'circle_type': item['circle_type'] ?? 'friend',
      }).toList();
    } else {
      throw Exception('Failed to load friend circles');
    }
  }

  Future<List<Map<String, dynamic>>> getHealthRecords({String? memberId, String? recordType}) async {
    final headers = await _authService.getAuthHeaders();
    var url = '$baseUrl/health-records/';
    final queryParams = <String, String>{};
    if (memberId != null) queryParams['family_member_id'] = memberId;
    if (recordType != null) queryParams['record_type'] = recordType;
    if (queryParams.isNotEmpty) {
      url += '?${queryParams.entries.map((e) => '${e.key}=${e.value}').join('&')}';
    }
    final response = await _handleRequest(
      http.get(Uri.parse(url), headers: headers),
    );
    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);
      final data = responseBody['data'] ?? {};
      final List<dynamic> items = data['items'] ?? [];
      return items.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to load health records');
    }
  }

  Future<Map<String, dynamic>> createHealthRecord(Map<String, dynamic> recordData) async {
    final headers = await _authService.getAuthHeaders();
    final response = await _handleRequest(
      http.post(
        Uri.parse('$baseUrl/health-records/'),
        headers: headers,
        body: jsonEncode(recordData),
      ),
    );
    if (response.statusCode == 201) {
      final responseBody = jsonDecode(response.body);
      return responseBody['data'] ?? responseBody;
    } else {
      throw Exception('Failed to create health record');
    }
  }

  Future<Map<String, dynamic>> updateHealthRecord(String recordId, Map<String, dynamic> recordData) async {
    final headers = await _authService.getAuthHeaders();
    final response = await _handleRequest(
      http.put(
        Uri.parse('$baseUrl/health-records/$recordId'),
        headers: headers,
        body: jsonEncode(recordData),
      ),
    );
    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);
      return responseBody['data'] ?? responseBody;
    } else {
      throw Exception('Failed to update health record');
    }
  }

  Future<void> deleteHealthRecord(String recordId) async {
    final headers = await _authService.getAuthHeaders();
    final response = await _handleRequest(
      http.delete(
        Uri.parse('$baseUrl/health-records/$recordId'),
        headers: headers,
      ),
    );
    if (response.statusCode != 204) {
      throw Exception('Failed to delete health record');
    }
  }

  Future<Map<String, dynamic>> createVaccination(Map<String, dynamic> vaccinationData) async {
    final headers = await _authService.getAuthHeaders();
    final response = await _handleRequest(
      http.post(
        Uri.parse('$baseUrl/health-records/vaccinations'),
        headers: headers,
        body: jsonEncode(vaccinationData),
      ),
    );
    if (response.statusCode == 201) {
      final responseBody = jsonDecode(response.body);
      return responseBody['data'] ?? responseBody;
    } else {
      throw Exception('Failed to create vaccination');
    }
  }

  Future<List<Map<String, dynamic>>> getVaccinations() async {
    final headers = await _authService.getAuthHeaders();
    final response = await _handleRequest(
      http.get(Uri.parse('$baseUrl/health-records/vaccinations'), headers: headers),
    );
    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);
      final data = responseBody['data'] ?? {};
      final List<dynamic> items = data['items'] ?? [];
      return items.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to load vaccinations');
    }
  }

  Future<Map<String, dynamic>> getMemberHealthSummary(String memberId) async {
    final headers = await _authService.getAuthHeaders();
    final response = await _handleRequest(
      http.get(Uri.parse('$baseUrl/health-records/member/$memberId/summary'), headers: headers),
    );
    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);
      return responseBody['data'] ?? responseBody;
    } else {
      throw Exception('Failed to load health summary');
    }
  }

  Future<Map<String, dynamic>> createReminder(Map<String, dynamic> reminderData) async {
    final headers = await _authService.getAuthHeaders();
    final response = await _handleRequest(
      http.post(
        Uri.parse('$baseUrl/health-records/reminders/'),
        headers: headers,
        body: jsonEncode(reminderData),
      ),
    );
    if (response.statusCode == 201) {
      final responseData = jsonDecode(response.body);
      return responseData['data'] ?? responseData;
    } else {
      throw Exception('Failed to create reminder');
    }
  }

  Future<List<Map<String, dynamic>>> getReminders({
    String? recordId,
    String? assignedUserId,
    String? status,
  }) async {
    final headers = await _authService.getAuthHeaders();
    var url = '$baseUrl/health-records/reminders/';
    final queryParams = <String, String>{};
    if (recordId != null) queryParams['record_id'] = recordId;
    if (assignedUserId != null) queryParams['assigned_user_id'] = assignedUserId;
    if (status != null) queryParams['status'] = status;
    if (queryParams.isNotEmpty) {
      url += '?${queryParams.entries.map((e) => '${e.key}=${e.value}').join('&')}';
    }
    final response = await _handleRequest(
      http.get(Uri.parse(url), headers: headers),
    );
    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      if (responseData is Map && responseData.containsKey('items')) {
        return List<Map<String, dynamic>>.from(responseData['items']);
      } else if (responseData is List) {
        return responseData.cast<Map<String, dynamic>>();
      }
      return [];
    } else {
      throw Exception('Failed to load reminders');
    }
  }

  Future<Map<String, dynamic>> updateReminder(String reminderId, Map<String, dynamic> reminderData) async {
    final headers = await _authService.getAuthHeaders();
    final response = await _handleRequest(
      http.put(
        Uri.parse('$baseUrl/health-records/reminders/$reminderId'),
        headers: headers,
        body: jsonEncode(reminderData),
      ),
    );
    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      return responseData['data'] ?? responseData;
    } else {
      throw Exception('Failed to update reminder');
    }
  }

  Future<void> deleteReminder(String reminderId) async {
    final headers = await _authService.getAuthHeaders();
    final response = await _handleRequest(
      http.delete(
        Uri.parse('$baseUrl/health-records/reminders/$reminderId'),
        headers: headers,
      ),
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete reminder');
    }
  }

  Future<Map<String, dynamic>> snoozeReminder(String reminderId, DateTime snoozeUntil) async {
    final headers = await _authService.getAuthHeaders();
    final response = await _handleRequest(
      http.post(
        Uri.parse('$baseUrl/health-records/reminders/$reminderId/snooze'),
        headers: headers,
        body: jsonEncode({'snooze_until': snoozeUntil.toIso8601String()}),
      ),
    );
    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      return responseData['data'] ?? responseData;
    } else {
      throw Exception('Failed to snooze reminder');
    }
  }

  Future<Map<String, dynamic>> completeReminder(String reminderId) async {
    final headers = await _authService.getAuthHeaders();
    final response = await _handleRequest(
      http.post(
        Uri.parse('$baseUrl/health-records/reminders/$reminderId/complete'),
        headers: headers,
      ),
    );
    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      return responseData['data'] ?? responseData;
    } else {
      throw Exception('Failed to complete reminder');
    }
  }

  Future<List<Map<String, dynamic>>> getDocuments({String? documentType}) async {
    final headers = await _authService.getAuthHeaders();
    var url = '$baseUrl/document-vault/';
    if (documentType != null) {
      url += '?document_type=$documentType';
    }
    final response = await _handleRequest(
      http.get(Uri.parse(url), headers: headers),
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to load documents');
    }
  }

  Future<Map<String, dynamic>> createDocument(Map<String, dynamic> documentData) async {
    final headers = await _authService.getAuthHeaders();
    final response = await _handleRequest(
      http.post(
        Uri.parse('$baseUrl/document-vault/'),
        headers: headers,
        body: jsonEncode(documentData),
      ),
    );
    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to create document');
    }
  }

  Future<Map<String, dynamic>> updateDocument(String documentId, Map<String, dynamic> documentData) async {
    final headers = await _authService.getAuthHeaders();
    final response = await _handleRequest(
      http.put(
        Uri.parse('$baseUrl/document-vault/$documentId'),
        headers: headers,
        body: jsonEncode(documentData),
      ),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to update document');
    }
  }

  Future<void> deleteDocument(String documentId) async {
    final headers = await _authService.getAuthHeaders();
    final response = await _handleRequest(
      http.delete(
        Uri.parse('$baseUrl/document-vault/$documentId'),
        headers: headers,
      ),
    );
    if (response.statusCode != 204) {
      throw Exception('Failed to delete document');
    }
  }

  Future<List<Map<String, dynamic>>> getDocumentAccessLog(String documentId) async {
    final headers = await _authService.getAuthHeaders();
    final response = await _handleRequest(
      http.get(Uri.parse('$baseUrl/document-vault/$documentId/access-log'), headers: headers),
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to load access log');
    }
  }

  Future<void> logDocumentAccess(String documentId, String action, {String? ipAddress}) async {
    final headers = await _authService.getAuthHeaders();
    final body = {'action': action};
    if (ipAddress != null) body['ip_address'] = ipAddress;
    final response = await _handleRequest(
      http.post(
        Uri.parse('$baseUrl/document-vault/$documentId/log-access'),
        headers: headers,
        body: jsonEncode(body),
      ),
    );
    if (response.statusCode != 201) {
      throw Exception('Failed to log access');
    }
  }

  Future<Map<String, dynamic>> createMilestone(Map<String, dynamic> milestoneData) async {
    final headers = await _authService.getAuthHeaders();
    final response = await _handleRequest(
      http.post(
        Uri.parse('$baseUrl/family-milestones/'),
        headers: headers,
        body: jsonEncode(milestoneData),
      ),
    );
    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to create milestone');
    }
  }

  Future<Map<String, dynamic>> createRecipe(Map<String, dynamic> recipeData) async {
    final headers = await _authService.getAuthHeaders();
    final response = await _handleRequest(
      http.post(
        Uri.parse('$baseUrl/family-recipes/'),
        headers: headers,
        body: jsonEncode(recipeData),
      ),
    );
    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to create recipe');
    }
  }

  Future<Map<String, dynamic>> createTradition(Map<String, dynamic> traditionData) async {
    final headers = await _authService.getAuthHeaders();
    final response = await _handleRequest(
      http.post(
        Uri.parse('$baseUrl/family-traditions/'),
        headers: headers,
        body: jsonEncode(traditionData),
      ),
    );
    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to create tradition');
    }
  }

  Future<FamilyAlbum> createAlbum(Map<String, dynamic> albumData) async {
    final headers = await _authService.getAuthHeaders();
    final response = await _handleRequest(
      http.post(
        Uri.parse('$baseUrl/family-albums/'),
        headers: headers,
        body: jsonEncode(albumData),
      ),
    );
    if (response.statusCode == 201) {
      return FamilyAlbum.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create album');
    }
  }

  Future<LegacyLetter> createLegacyLetter(Map<String, dynamic> letterData) async {
    final headers = await _authService.getAuthHeaders();
    final response = await _handleRequest(
      http.post(
        Uri.parse('$baseUrl/legacy-letters/'),
        headers: headers,
        body: jsonEncode(letterData),
      ),
    );
    if (response.statusCode == 201) {
      return LegacyLetter.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create legacy letter');
    }
  }

  Future<List<LegacyLetter>> getSentLetters() async {
    final headers = await _authService.getAuthHeaders();
    final response = await _handleRequest(
      http.get(Uri.parse('$baseUrl/legacy-letters/sent'), headers: headers),
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => LegacyLetter.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load sent letters');
    }
  }

  Future<List<ReceivedLetter>> getReceivedLetters() async {
    final headers = await _authService.getAuthHeaders();
    final response = await _handleRequest(
      http.get(Uri.parse('$baseUrl/legacy-letters/received'), headers: headers),
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => ReceivedLetter.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load received letters');
    }
  }

  Future<LegacyLetter> getLetterDetail(String id) async {
    final headers = await _authService.getAuthHeaders();
    final response = await _handleRequest(
      http.get(Uri.parse('$baseUrl/legacy-letters/$id'), headers: headers),
    );
    if (response.statusCode == 200) {
      return LegacyLetter.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load letter detail');
    }
  }

  Future<void> markLetterAsRead(String id) async {
    final headers = await _authService.getAuthHeaders();
    final response = await _handleRequest(
      http.post(
        Uri.parse('$baseUrl/legacy-letters/$id/mark-read'),
        headers: headers,
      ),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to mark letter as read');
    }
  }

  Future<List<Map<String, dynamic>>> getInviteLinks({String? statusFilter}) async {
    final headers = await _authService.getAuthHeaders();
    var url = '$baseUrl/genealogy/invite-links';
    if (statusFilter != null) {
      url += '?status_filter=$statusFilter';
    }
    final response = await _handleRequest(
      http.get(Uri.parse(url), headers: headers),
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to load invite links');
    }
  }

  Future<List<Map<String, dynamic>>> getPersonTimeline(String personId) async {
    final headers = await _authService.getAuthHeaders();
    final response = await _handleRequest(
      http.get(
        Uri.parse('$baseUrl/genealogy/persons/$personId/timeline'),
        headers: headers,
      ),
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to load person timeline');
    }
  }

  Future<Map<String, dynamic>> createInviteLink(String personId, String email, {String? message, int expiresInDays = 7}) async {
    final headers = await _authService.getAuthHeaders();
    final inviteData = {
      'person_id': personId,
      'email': email,
      if (message != null && message.isNotEmpty) 'message': message,
      'expires_in_days': expiresInDays,
    };
    final response = await _handleRequest(
      http.post(
        Uri.parse('$baseUrl/genealogy/invite-links'),
        headers: headers,
        body: jsonEncode(inviteData),
      ),
    );
    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to create invite link');
    }
  }

  Future<Map<String, dynamic>> redeemInviteLink(String token) async {
    final headers = await _authService.getAuthHeaders();
    final response = await _handleRequest(
      http.post(
        Uri.parse('$baseUrl/genealogy/join/$token'),
        headers: headers,
      ),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to redeem invite link');
    }
  }

  Future<String> generateInviteLink() async {
    final headers = await _authService.getAuthHeaders();
    final response = await _handleRequest(
      http.post(
        Uri.parse('$baseUrl/genealogy/generate-invite-link'),
        headers: headers,
      ),
    );
    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);
      return responseBody['invite_link'];
    } else {
      throw Exception('Failed to generate invite link');
    }
  }

  Future<List<UserSearchResult>> searchFamilyCircleUsers(String query) async {
    final headers = await _authService.getAuthHeaders();
    final response = await _handleRequest(
      http.get(
        Uri.parse('$baseUrl/users/search?query=${Uri.encodeComponent(query)}'),
        headers: headers,
      ),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> items = data['data']?['results'] ?? data['results'] ?? [];
      return items.map((json) => UserSearchResult.fromJson(json)).toList();
    }
    throw Exception('Failed to search users');
  }

  Future<void> approveHealthRecord(String recordId) async {
    final headers = await _authService.getAuthHeaders();
    final response = await _handleRequest(
      http.post(
        Uri.parse('$baseUrl/family/health-records/$recordId/approve'),
        headers: headers,
      ),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to approve health record');
    }
  }

  Future<void> rejectHealthRecord(String recordId, String? reason) async {
    final headers = await _authService.getAuthHeaders();
    final url = reason != null 
      ? '$baseUrl/family/health-records/$recordId/reject?rejection_reason=${Uri.encodeComponent(reason)}'
      : '$baseUrl/family/health-records/$recordId/reject';
    final response = await _handleRequest(
      http.post(Uri.parse(url), headers: headers),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to reject health record');
    }
  }

  Future<Map<String, dynamic>> getHealthDashboard() async {
    final headers = await _authService.getAuthHeaders();
    final response = await _handleRequest(
      http.get(
        Uri.parse('$baseUrl/family/health-records/dashboard'),
        headers: headers,
      ),
    );
    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);
      return responseBody['data'] ?? responseBody;
    }
    throw Exception('Failed to load health dashboard');
  }
}
