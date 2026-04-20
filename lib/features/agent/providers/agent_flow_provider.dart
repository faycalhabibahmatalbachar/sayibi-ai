import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/services/agent_api_service.dart';
import '../../../core/services/contacts_local_service.dart';
import '../../../core/services/sim_sms_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../../chat/providers/chat_provider.dart';

/// État du flux agent (NLU JSON + actions locales).
class AgentFlowState {
  const AgentFlowState({
    this.modeEnabled = false,
    this.loading = false,
    this.error,
    this.lastResponse,
    this.anchorMessage,
    this.successHint,
  });

  final bool modeEnabled;
  final bool loading;
  final String? error;

  /// Dernière réponse brute `/agent/turn` (thinking, action, payload, …).
  final Map<String, dynamic>? lastResponse;

  /// Premier message utilisateur du tour en cours (pour boucles search_contacts).
  final String? anchorMessage;

  /// Court message de succès après exécution locale.
  final String? successHint;

  AgentFlowState copyWith({
    bool? modeEnabled,
    bool? loading,
    Object? error = _sentinel,
    Map<String, dynamic>? lastResponse,
    String? anchorMessage,
    String? successHint,
    bool clearResponse = false,
    bool clearError = false,
    bool clearSuccessHint = false,
  }) {
    return AgentFlowState(
      modeEnabled: modeEnabled ?? this.modeEnabled,
      loading: loading ?? this.loading,
      error: clearError
          ? null
          : (identical(error, _sentinel) ? this.error : (error as String?)),
      lastResponse: clearResponse ? null : (lastResponse ?? this.lastResponse),
      anchorMessage: anchorMessage ?? (clearResponse ? null : this.anchorMessage),
      successHint:
          clearSuccessHint ? null : (successHint ?? this.successHint),
    );
  }

  static const Object _sentinel = Object();
}

final agentFlowProvider =
    StateNotifierProvider<AgentFlowNotifier, AgentFlowState>((ref) {
  return AgentFlowNotifier(ref);
});

class AgentFlowNotifier extends StateNotifier<AgentFlowState> {
  AgentFlowNotifier(this._ref) : super(const AgentFlowState());

  final Ref _ref;

  AgentApiService get _api => _ref.read(agentApiServiceProvider);

  Future<Map<String, bool>> _permissionState() async {
    if (kIsWeb) {
      return {'contacts': false, 'sms': false, 'phone': false};
    }
    final contacts = await Permission.contacts.isGranted;
    final sms = await Permission.sms.isGranted;
    var phone = false;
    try {
      phone = await Permission.phone.isGranted;
    } catch (_) {}
    return {'contacts': contacts, 'sms': sms, 'phone': phone};
  }

  void setMode(bool enabled) {
    if (!enabled) {
      state = const AgentFlowState();
    } else {
      state = state.copyWith(modeEnabled: true, clearError: true);
    }
  }

  /// Nouvelle conversation : vide le flux agent en gardant le mode activé ou non.
  void resetSession() {
    state = AgentFlowState(modeEnabled: state.modeEnabled);
  }

  void clearSuccessHint() {
    state = state.copyWith(successHint: null);
  }

  /// Entrée principale depuis la zone de saisie (mode actions activé).
  Future<void> submitUserMessage(String text) async {
    final t = text.trim();
    if (t.isEmpty) return;
    if (!_ref.read(authProvider).authenticated) {
      state = state.copyWith(error: 'Connectez-vous pour utiliser le mode actions.');
      return;
    }

    state = state.copyWith(
      loading: true,
      clearError: true,
      clearResponse: true,
    );
    state = state.copyWith(anchorMessage: t);

    _ref.read(chatProvider.notifier).appendAgentUserMessage(t);

    try {
      final data = await _runWithSearchLoop(message: t, pending: null);
      if (data == null) {
        state = state.copyWith(
          loading: false,
          error: 'Réponse agent indisponible.',
        );
        return;
      }
      await _handleAgentData(data, userMessage: t);
    } on DioException catch (e) {
      state = state.copyWith(
        loading: false,
        error: e.response?.data?.toString() ?? e.message ?? 'Erreur réseau',
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  /// Boucle interne : `search_contacts` → recherche locale → re-tour.
  Future<Map<String, dynamic>?> _runWithSearchLoop({
    required String message,
    required Map<String, dynamic>? pending,
  }) async {
    Map<String, dynamic>? pend = pending;
    List<Map<String, dynamic>>? crs;
    final anchor = message;

    for (var i = 0; i < 5; i++) {
      final data = await _api.agentTurn(
        message: anchor,
        pending: pend,
        contactSearchResults: crs,
        permissionState: await _permissionState(),
      );
      crs = null;
      if (data == null) return null;

      final action = data['action']?.toString() ?? '';
      if (action == 'search_contacts') {
        final payload = data['payload'];
        final q = payload is Map
            ? (payload['query'] ?? payload['q'])?.toString() ?? ''
            : '';
        if (q.isEmpty) return data;
        final local = await ContactsLocalService.searchContacts(q, fuzzy: true);
        crs = local;
        pend = Map<String, dynamic>.from(data);
        continue;
      }
      return data;
    }
    return null;
  }

  Future<void> _handleAgentData(
    Map<String, dynamic> data, {
    required String userMessage,
  }) async {
    final action = data['action']?.toString() ?? '';
    final msg = data['message_to_user']?.toString() ?? '';

    if (action == 'execute_action') {
      await _executeNative(data);
      state = state.copyWith(loading: false, clearResponse: true);
      return;
    }

    if (action == 'cancelled') {
      _ref.read(chatProvider.notifier).appendAgentAssistantMessage(msg);
      state = state.copyWith(loading: false, clearResponse: true);
      return;
    }

    if (action == 'error') {
      state = state.copyWith(
        loading: false,
        lastResponse: data,
        error: data['payload'] is Map
            ? (data['payload'] as Map)['error_message']?.toString()
            : null,
      );
      if (msg.isNotEmpty) {
        _ref.read(chatProvider.notifier).appendAgentAssistantMessage(msg);
      }
      return;
    }

    state = state.copyWith(loading: false, lastResponse: data, error: null);
    if (msg.isNotEmpty) {
      _ref.read(chatProvider.notifier).appendAgentAssistantMessage(msg);
    }
  }

  Future<void> _executeNative(Map<String, dynamic> data) async {
    final payload = data['payload'];
    if (payload is! Map) {
      _ref.read(chatProvider.notifier).appendAgentAssistantMessage(
            'Action terminée.',
          );
      return;
    }
    final p = Map<String, dynamic>.from(payload);
    final type = (p['action_type'] ?? p['type'] ?? '').toString();

    if (type == 'send_sms' || type == 'send_sms_scheduled') {
      final rawTo = p['phone_number']?.toString() ?? '';
      final digits = rawTo.replaceAll(RegExp(r'[^\d+]'), '');
      final to = digits.startsWith('+') ? digits : '+$digits';
      var body = p['message']?.toString() ?? '';
      if (body.isEmpty) body = p['message_generated']?.toString() ?? '';
      body = body.trim();
      if (to.length < 4 || body.isEmpty) {
        _ref.read(chatProvider.notifier).appendAgentAssistantMessage(
              'Données incomplètes pour l’envoi SMS.',
            );
        return;
      }
      final r = await SimSmsService.send(toE164: to, body: body);
      final masked = to.length > 6
          ? '${to.substring(0, 4)} ••• •• ${to.substring(to.length - 2)}'
          : '•••';
      if (r.ok) {
        await _api.logAction(
          actionType: 'send_sms',
          contactId: p['contact_id']?.toString(),
          phoneMasked: masked,
          messagePreview: body.length > 120 ? '${body.substring(0, 120)}…' : body,
          confidence: (data['confidence'] is num)
              ? (data['confidence'] as num).toDouble()
              : null,
        );
        state = state.copyWith(
          successHint: r.usedSimDirect
              ? 'SMS envoyé.'
              : 'Application Messages ouverte — validez l’envoi.',
        );
        _ref.read(chatProvider.notifier).appendAgentAssistantMessage(
              r.usedSimDirect
                  ? '✅ SMS envoyé.'
                  : '✅ Messages ouvert avec le texte prérempli — validez sur l’appareil.',
            );
      } else {
        _ref.read(chatProvider.notifier).appendAgentAssistantMessage(
              '❌ ${r.message ?? "Échec d’envoi"}',
            );
      }
      return;
    }

    if (type == 'make_call') {
      _ref.read(chatProvider.notifier).appendAgentAssistantMessage(
            '📞 Action appel : ouvrez le composeur téléphone depuis l’appareil (intégration à venir).',
          );
      return;
    }

    _ref.read(chatProvider.notifier).appendAgentAssistantMessage(
          '✅ Action enregistrée (${type.isEmpty ? "execute" : type}).',
        );
  }

  /// Confirmation explicite (« oui »).
  Future<void> confirm() async {
    await _followUp('oui, confirme');
  }

  Future<void> cancel() async {
    await _followUp('non, annule');
  }

  Future<void> pickContact({
    required String contactId,
    required String displayName,
    required String querySnapshot,
  }) async {
    await _api.saveContactResolution(
      query: querySnapshot,
      contactIdChosen: contactId,
      displayNameSnapshot: displayName,
    );
    await _followUp('Je choisis le contact : $displayName');
  }

  Future<void> pickPhoneNumber({
    required String number,
    required String label,
  }) async {
    await _followUp('J’utilise le numéro $label : $number');
  }

  Future<void> requestPermissions() async {
    await Permission.contacts.request();
    await Permission.sms.request();
    await _followUp('J’ai mis à jour les autorisations. On continue.');
  }

  Future<void> _followUp(String text) async {
    final pending = state.lastResponse;
    if (pending == null) return;
    if (!_ref.read(authProvider).authenticated) return;

    state = state.copyWith(loading: true, clearError: true);
    _ref.read(chatProvider.notifier).appendAgentUserMessage(text);

    try {
      final data = await _runWithSearchLoop(message: text, pending: pending);
      if (data == null) {
        state = state.copyWith(
          loading: false,
          error: 'Réponse agent indisponible.',
        );
        return;
      }
      await _handleAgentData(data, userMessage: text);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }
}
