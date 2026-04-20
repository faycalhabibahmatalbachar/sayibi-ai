import 'package:dio/dio.dart';

import '../constants/api_constants.dart';

/// Appels HTTP vers `/api/v1/agent/*` (mode agent JSON).
class AgentApiService {
  AgentApiService(this._dio);

  final Dio _dio;

  /// Tour NLU : renvoie `data` du wrapper `{ success, data, message }`.
  Future<Map<String, dynamic>?> agentTurn({
    required String message,
    Map<String, dynamic>? pending,
    List<Map<String, dynamic>>? contactSearchResults,
    Map<String, bool>? permissionState,
  }) async {
    final res = await _dio.post<dynamic>(
      ApiConstants.agentTurn,
      data: <String, dynamic>{
        'message': message,
        if (pending != null) 'pending': pending,
        if (contactSearchResults != null)
          'contact_search_results': contactSearchResults,
        if (permissionState != null) 'permission_state': permissionState,
      },
    );
    final body = res.data;
    if (body is Map && body['success'] == true && body['data'] is Map) {
      return Map<String, dynamic>.from(body['data'] as Map);
    }
    return null;
  }

  Future<void> logAction({
    required String actionType,
    String? contactId,
    String? phoneMasked,
    String? messagePreview,
    String status = 'success',
    String? ambiguityType,
    double? confidence,
    Map<String, dynamic>? clientMeta,
  }) async {
    try {
      await _dio.post<dynamic>(
        ApiConstants.agentLog,
        data: <String, dynamic>{
          'action_type': actionType,
          if (contactId != null) 'contact_id': contactId,
          if (phoneMasked != null) 'phone_masked': phoneMasked,
          if (messagePreview != null) 'message_preview': messagePreview,
          'status': status,
          if (ambiguityType != null) 'ambiguity_type': ambiguityType,
          if (confidence != null) 'confidence': confidence,
          if (clientMeta != null) 'client_meta': clientMeta,
        },
      );
    } catch (_) {}
  }

  Future<void> saveContactResolution({
    required String query,
    required String contactIdChosen,
    String? displayNameSnapshot,
    String resolutionType = 'user_picked',
  }) async {
    try {
      await _dio.post<dynamic>(
        ApiConstants.agentContactResolution,
        data: <String, dynamic>{
          'query': query,
          'contact_id_chosen': contactIdChosen,
          if (displayNameSnapshot != null) 'display_name_snapshot': displayNameSnapshot,
          'resolution_type': resolutionType,
        },
      );
    } catch (_) {}
  }
}
