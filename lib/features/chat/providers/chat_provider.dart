import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/app_utils.dart';
import '../../../models/app_models.dart';
import '../../../providers/app_providers.dart';
import '../../../services/api_service.dart';

final chatProvider =
    StateNotifierProvider.family.autoDispose<ChatNotifier, ChatState, String>(
  (ref, roomId) {
    final api = ref.watch(apiServiceProvider);
    final user = ref.watch(authStateProvider).user;
    final n = ChatNotifier(api, user, roomId);
    n.startPolling();
    return n;
  },
);

class ChatState {
  final bool isLoading;
  final bool isSending;
  final List<ChatMessage> messages;
  final ChatMessage? pinnedMessage;
  final int onlineCount;

  const ChatState({
    this.isLoading = true,
    this.isSending = false,
    this.messages = const [],
    this.pinnedMessage,
    this.onlineCount = 0,
  });

  ChatState copyWith({
    bool? isLoading,
    bool? isSending,
    List<ChatMessage>? messages,
    ChatMessage? pinnedMessage,
    int? onlineCount,
    bool clearPin = false,
  }) {
    return ChatState(
      isLoading: isLoading ?? this.isLoading,
      isSending: isSending ?? this.isSending,
      messages: messages ?? this.messages,
      pinnedMessage: clearPin ? null : (pinnedMessage ?? this.pinnedMessage),
      onlineCount: onlineCount ?? this.onlineCount,
    );
  }
}

class ChatNotifier extends StateNotifier<ChatState> {
  final ApiService _api;
  final dynamic _user;
  final String _roomId;
  Timer? _pollTimer;
  int _lastTs = 0;

  ChatNotifier(this._api, this._user, this._roomId) : super(const ChatState());

  void startPolling() {
    _fetchMessages();
    _fetchPinned();
    _pollTimer = Timer.periodic(
      const Duration(milliseconds: AppConstants.chatPollIntervalMs),
      (_) => _fetchMessages(),
    );
  }

  Future<void> _fetchMessages() async {
    try {
      final newMsgs = await _api.fetchMessages(_roomId, _lastTs);
      if (newMsgs.isEmpty && state.messages.isNotEmpty) {
        state = state.copyWith(isLoading: false);
        return;
      }

      final parsed = newMsgs.map((m) => ChatMessage.fromJson(m)).toList();
      if (parsed.isNotEmpty) {
        _lastTs = parsed.map((m) => m.ts).reduce((a, b) => a > b ? a : b);
        final merged = [...state.messages];
        for (final msg in parsed) {
          final existIdx = merged.indexWhere((m) => m.id == msg.id);
          if (existIdx >= 0) {
            merged[existIdx] = msg;
          } else {
            merged.add(msg);
          }
        }
        merged.sort((a, b) => a.ts.compareTo(b.ts));
        state = state.copyWith(isLoading: false, messages: merged);
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> _fetchPinned() async {
    try {
      final pinned = await _api.getPinnedMessage(_roomId);
      if (pinned != null) {
        state = state.copyWith(pinnedMessage: ChatMessage.fromJson(pinned));
      }
    } catch (_) {}
  }

  Future<void> sendMessage(String text) async {
    if (_user == null || text.isEmpty) return;
    if (_user.chatBanned == true) return;

    state = state.copyWith(isSending: true);

    final msgId = 'msg_${DateTime.now().millisecondsSinceEpoch}';
    final msg = ChatMessage(
      id: msgId,
      uid: _user.uid,
      name: _user.name,
      picture: _user.pictureUrl,
      role: _user.role,
      text: text,
      ts: DateTime.now().millisecondsSinceEpoch,
    );

    // Optimistic update
    final optimistic = [...state.messages, msg];
    state = state.copyWith(isSending: false, messages: optimistic);

    try {
      await _api.sendMessage(_roomId, msg.toJson());
      await _fetchMessages();
    } catch (_) {
      state = state.copyWith(isSending: false);
    }
  }

  Future<void> deleteMessage(String msgId) async {
    final updated = state.messages.map((m) {
      if (m.id == msgId) {
        return ChatMessage(
          id: m.id, uid: m.uid, name: m.name, role: m.role,
          text: m.text, ts: m.ts, deleted: true,
        );
      }
      return m;
    }).toList();
    state = state.copyWith(messages: updated);
    await _api.deleteMessage(_roomId, msgId);
  }

  Future<void> pinMessage(ChatMessage msg) async {
    state = state.copyWith(pinnedMessage: msg);
    await _api.pinMessage(_roomId, msg.toJson());
  }

  Future<void> unpinMessage() async {
    state = state.copyWith(clearPin: true);
    await _api.unpinMessage(_roomId);
  }

  Future<void> banUser(String uid) async {
    await _api.banUserFromChat(uid, true);
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }
}
