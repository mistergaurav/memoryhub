import '../common/family_api_client.dart';
import '../common/family_exceptions.dart';

class GenealogyInvitationsService extends FamilyApiClient {
  Future<List<Map<String, dynamic>>> getInvitations({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final params = {
        'page': page.toString(),
        'limit': limit.toString(),
      };
      
      final data = await get(
        '/family/genealogy/invitations',
        params: params,
        useCache: true,
      );
      
      final items = data['data'] ?? data['items'] ?? [];
      if (items is List) {
        return items.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      if (e is ApiException || e is NetworkException || e is AuthException) {
        rethrow;
      }
      throw NetworkException(
        message: 'Failed to load invitations',
        originalError: e,
      );
    }
  }

  Future<Map<String, dynamic>> createInvitation(
    Map<String, dynamic> invitationData,
  ) async {
    try {
      final data = await post(
        '/family/genealogy/invitations',
        body: invitationData,
      );
      return data['data'] ?? data;
    } catch (e) {
      if (e is ApiException || e is NetworkException || e is AuthException) {
        rethrow;
      }
      throw NetworkException(
        message: 'Failed to create invitation',
        originalError: e,
      );
    }
  }

  Future<Map<String, dynamic>> respondToInvitation(
    String invitationId,
    String action,
  ) async {
    try {
      final data = await post(
        '/family/genealogy/invitations/$invitationId/respond',
        body: {'action': action},
      );
      return data['data'] ?? data;
    } catch (e) {
      if (e is ApiException || e is NetworkException || e is AuthException) {
        rethrow;
      }
      throw NetworkException(
        message: 'Failed to respond to invitation',
        originalError: e,
      );
    }
  }

  Future<void> deleteInvitation(String invitationId) async {
    try {
      await delete('/family/genealogy/invitations/$invitationId');
    } catch (e) {
      if (e is ApiException || e is NetworkException || e is AuthException) {
        rethrow;
      }
      throw NetworkException(
        message: 'Failed to delete invitation',
        originalError: e,
      );
    }
  }

  Future<Map<String, dynamic>> acceptInvitation(String invitationId) async {
    return respondToInvitation(invitationId, 'accept');
  }

  Future<Map<String, dynamic>> rejectInvitation(String invitationId) async {
    return respondToInvitation(invitationId, 'reject');
  }
}
