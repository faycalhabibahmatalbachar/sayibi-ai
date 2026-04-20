import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/agent_api_service.dart';
import '../../auth/providers/auth_provider.dart';

class AlarmItem {
  const AlarmItem({
    required this.id,
    required this.title,
    required this.scheduledFor,
    required this.timezone,
    required this.isEnabled,
    required this.status,
    this.message,
    this.repeatRule,
  });

  final String id;
  final String title;
  final String? message;
  final DateTime scheduledFor;
  final String timezone;
  final String? repeatRule;
  final bool isEnabled;
  final String status;

  factory AlarmItem.fromMap(Map<String, dynamic> m) {
    return AlarmItem(
      id: (m['id'] ?? '').toString(),
      title: (m['title'] ?? 'Alarme').toString(),
      message: m['message']?.toString(),
      scheduledFor: DateTime.tryParse(m['scheduled_for']?.toString() ?? '') ??
          DateTime.now(),
      timezone: (m['timezone'] ?? 'Africa/Ndjamena').toString(),
      repeatRule: m['repeat_rule']?.toString(),
      isEnabled: m['is_enabled'] == true,
      status: (m['status'] ?? 'scheduled').toString(),
    );
  }
}

class AlarmState {
  const AlarmState({
    this.loading = false,
    this.saving = false,
    this.error,
    this.items = const [],
  });

  final bool loading;
  final bool saving;
  final String? error;
  final List<AlarmItem> items;

  AlarmState copyWith({
    bool? loading,
    bool? saving,
    String? error,
    bool clearError = false,
    List<AlarmItem>? items,
  }) {
    return AlarmState(
      loading: loading ?? this.loading,
      saving: saving ?? this.saving,
      error: clearError ? null : (error ?? this.error),
      items: items ?? this.items,
    );
  }
}

final alarmProvider = StateNotifierProvider<AlarmNotifier, AlarmState>((ref) {
  return AlarmNotifier(ref);
});

class AlarmNotifier extends StateNotifier<AlarmState> {
  AlarmNotifier(this._ref) : super(const AlarmState());

  final Ref _ref;

  AgentApiService get _api => _ref.read(agentApiServiceProvider);

  Future<void> load() async {
    if (!_ref.read(authProvider).authenticated) return;
    state = state.copyWith(loading: true, clearError: true);
    try {
      final rows = await _api.listAlarms();
      final items = rows.map(AlarmItem.fromMap).where((e) => e.id.isNotEmpty).toList();
      state = state.copyWith(loading: false, items: items);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<bool> create({
    required String title,
    String? message,
    required DateTime scheduledForLocal,
    String timezone = 'Africa/Ndjamena',
    String? repeatRule,
  }) async {
    state = state.copyWith(saving: true, clearError: true);
    try {
      await _api.createAlarm(
        title: title,
        message: message,
        scheduledForUtc: scheduledForLocal.toUtc(),
        timezone: timezone,
        repeatRule: repeatRule,
        metadata: {'source': 'flutter_alarm_ui'},
      );
      state = state.copyWith(saving: false);
      await load();
      return true;
    } catch (e) {
      state = state.copyWith(saving: false, error: e.toString());
      return false;
    }
  }

  Future<bool> update(
    String id, {
    String? title,
    String? message,
    DateTime? scheduledForLocal,
    bool? isEnabled,
    String? repeatRule,
  }) async {
    state = state.copyWith(saving: true, clearError: true);
    try {
      await _api.updateAlarm(
        id,
        title: title,
        message: message,
        scheduledForUtc: scheduledForLocal?.toUtc(),
        isEnabled: isEnabled,
        repeatRule: repeatRule,
      );
      state = state.copyWith(saving: false);
      await load();
      return true;
    } catch (e) {
      state = state.copyWith(saving: false, error: e.toString());
      return false;
    }
  }

  Future<void> delete(String id) async {
    state = state.copyWith(saving: true, clearError: true);
    try {
      await _api.deleteAlarm(id);
      state = state.copyWith(saving: false);
      await load();
    } catch (e) {
      state = state.copyWith(saving: false, error: e.toString());
    }
  }
}

