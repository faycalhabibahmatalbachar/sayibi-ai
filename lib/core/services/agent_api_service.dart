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
    String? memoryContext,
  }) async {
    final res = await _dio.post<dynamic>(
      ApiConstants.agentTurn,
      data: <String, dynamic>{
        'message': message,
        if (pending != null) 'pending': pending,
        if (contactSearchResults != null)
          'contact_search_results': contactSearchResults,
        if (permissionState != null) 'permission_state': permissionState,
        if (memoryContext != null && memoryContext.trim().isNotEmpty)
          'memory_context': memoryContext.trim(),
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

  Future<Map<String, dynamic>?> memorySummary({int limit = 10}) async {
    try {
      final res = await _dio.post<dynamic>(
        ApiConstants.agentMemorySummary,
        data: <String, dynamic>{'limit': limit},
      );
      final body = res.data;
      if (body is Map && body['success'] == true && body['data'] is Map) {
        return Map<String, dynamic>.from(body['data'] as Map);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> createAlarm({
    required String title,
    String? message,
    required DateTime scheduledForUtc,
    String timezone = 'Africa/Ndjamena',
    String? repeatRule,
    String deliveryChannel = 'push',
    Map<String, dynamic>? metadata,
    String? requestId,
  }) async {
    final res = await _dio.post<dynamic>(
      ApiConstants.alarms,
      data: <String, dynamic>{
        'title': title,
        if (message != null && message.trim().isNotEmpty) 'message': message.trim(),
        'scheduled_for': scheduledForUtc.toIso8601String(),
        'timezone': timezone,
        if (repeatRule != null && repeatRule.trim().isNotEmpty) 'repeat_rule': repeatRule.trim(),
        'delivery_channel': deliveryChannel,
        if (metadata != null) 'metadata': metadata,
        if (requestId != null && requestId.isNotEmpty) 'request_id': requestId,
      },
    );
    final body = res.data;
    if (body is Map && body['success'] == true && body['data'] is Map) {
      return Map<String, dynamic>.from(body['data'] as Map);
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> listAlarms() async {
    final res = await _dio.get<dynamic>(ApiConstants.alarms);
    final body = res.data;
    if (body is Map && body['success'] == true && body['data'] is List) {
      return (body['data'] as List)
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return const [];
  }

  Future<Map<String, dynamic>?> updateAlarm(
    String alarmId, {
    String? title,
    String? message,
    DateTime? scheduledForUtc,
    String? timezone,
    String? repeatRule,
    bool? isEnabled,
    String? status,
    String? deliveryChannel,
    Map<String, dynamic>? metadata,
  }) async {
    final res = await _dio.put<dynamic>(
      '${ApiConstants.alarms}/$alarmId',
      data: <String, dynamic>{
        if (title != null) 'title': title,
        if (message != null) 'message': message,
        if (scheduledForUtc != null) 'scheduled_for': scheduledForUtc.toIso8601String(),
        if (timezone != null) 'timezone': timezone,
        if (repeatRule != null) 'repeat_rule': repeatRule,
        if (isEnabled != null) 'is_enabled': isEnabled,
        if (status != null) 'status': status,
        if (deliveryChannel != null) 'delivery_channel': deliveryChannel,
        if (metadata != null) 'metadata': metadata,
      },
    );
    final body = res.data;
    if (body is Map && body['success'] == true && body['data'] is Map) {
      return Map<String, dynamic>.from(body['data'] as Map);
    }
    return null;
  }

  Future<bool> deleteAlarm(String alarmId) async {
    final res = await _dio.delete<dynamic>('${ApiConstants.alarms}/$alarmId');
    final body = res.data;
    return body is Map && body['success'] == true;
  }

  Future<Map<String, dynamic>?> syncContacts(List<Map<String, dynamic>> contacts) async {
    final res = await _dio.post<dynamic>(
      ApiConstants.agentContactsSync,
      data: <String, dynamic>{'contacts': contacts},
    );
    final body = res.data;
    if (body is Map && body['success'] == true && body['data'] is Map) {
      return Map<String, dynamic>.from(body['data'] as Map);
    }
    return null;
  }

  Future<Map<String, dynamic>?> createSmsDraft({
    required String toE164,
    required String body,
    String? contactIdentityId,
    String? requestId,
    Map<String, dynamic>? clientMeta,
  }) async {
    final res = await _dio.post<dynamic>(
      ApiConstants.agentSmsDraft,
      data: <String, dynamic>{
        'to_e164': toE164,
        'body': body,
        if (contactIdentityId != null) 'contact_identity_id': contactIdentityId,
        if (requestId != null) 'request_id': requestId,
        if (clientMeta != null) 'client_meta': clientMeta,
      },
    );
    final payload = res.data;
    if (payload is Map && payload['success'] == true && payload['data'] is Map) {
      return Map<String, dynamic>.from(payload['data'] as Map);
    }
    return null;
  }

  Future<Map<String, dynamic>?> updateSmsStatus({
    required String smsId,
    required String status,
    String? errorMessage,
  }) async {
    final res = await _dio.post<dynamic>(
      '${ApiConstants.agentSmsList}/$smsId/status',
      data: <String, dynamic>{
        'status': status,
        if (errorMessage != null && errorMessage.trim().isNotEmpty)
          'error_message': errorMessage.trim(),
      },
    );
    final payload = res.data;
    if (payload is Map && payload['success'] == true && payload['data'] is Map) {
      return Map<String, dynamic>.from(payload['data'] as Map);
    }
    return null;
  }
}
