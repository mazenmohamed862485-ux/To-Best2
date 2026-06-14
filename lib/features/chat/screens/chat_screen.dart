import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_utils.dart';
import '../../../models/app_models.dart';
import '../../../providers/app_providers.dart';
import '../../../widgets/common/app_text_field.dart';
import '../providers/chat_provider.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String roomId;
  const ChatScreen({super.key, required this.roomId});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider(widget.roomId));
    final user = ref.watch(authStateProvider).user;
    final settings = ref.watch(appSettingsProvider);
    final isAr = settings.language == 'ar';

    if (chatState.messages.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }

    final isBanned = user?.chatBanned == true;
    final isMuted = user?.chatMutedUntil != null &&
        DateTime.now().millisecondsSinceEpoch < (user!.chatMutedUntil!);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.roomId == 'general'
                ? (isAr ? 'الشات العام' : 'General Chat')
                : widget.roomId,
                style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 16)),
            if (chatState.onlineCount > 0)
              Text('${chatState.onlineCount} ${isAr ? "متصل" : "online"}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey, fontFamily: 'Cairo')),
          ],
        ),
        actions: [
          if (user?.isAdminLike == true)
            PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'rooms') _showRoomsDialog(context, isAr);
              },
              itemBuilder: (_) => [
                PopupMenuItem(value: 'rooms', child: Text(isAr ? 'الغرف' : 'Rooms', style: const TextStyle(fontFamily: 'Cairo'))),
              ],
            ),
        ],
      ),
      body: Column(
        children: [
          // ── Pinned message ─────────────────────
          if (chatState.pinnedMessage != null)
            _PinnedMessageBar(msg: chatState.pinnedMessage!, isAr: isAr),

          // ── Messages ───────────────────────────
          Expanded(
            child: chatState.isLoading && chatState.messages.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : chatState.messages.isEmpty
                    ? Center(
                        child: Text(isAr ? 'لا توجد رسائل بعد' : 'No messages yet',
                            style: const TextStyle(color: Colors.grey, fontFamily: 'Cairo')))
                    : ListView.builder(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        itemCount: chatState.messages.length,
                        itemBuilder: (ctx, i) {
                          final msg = chatState.messages[i];
                          final isMe = msg.uid == user?.uid;
                          final isAdmin = msg.isAdminLike;
                          return _MessageBubble(
                            msg: msg,
                            isMe: isMe,
                            isAdmin: user?.isAdminLike == true,
                            onDelete: () => ref.read(chatProvider(widget.roomId).notifier).deleteMessage(msg.id),
                            onPin: () => ref.read(chatProvider(widget.roomId).notifier).pinMessage(msg),
                            onBan: () => ref.read(chatProvider(widget.roomId).notifier).banUser(msg.uid),
                          );
                        },
                      ),
          ),

          // ── Input ──────────────────────────────
          if (isBanned)
            _BannedBar(isAr: isAr)
          else if (isMuted)
            _MutedBar(until: user!.chatMutedUntil!, isAr: isAr)
          else
            _InputBar(
              controller: _msgCtrl,
              isAr: isAr,
              isSending: chatState.isSending,
              onSend: () => _sendMessage(user?.name ?? '?'),
              onAttach: () => _pickImage(context, isAr),
            ),
        ],
      ),
    );
  }

  Future<void> _sendMessage(String name) async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    _msgCtrl.clear();
    await ref.read(chatProvider(widget.roomId).notifier).sendMessage(text);
    _scrollToBottom();
  }

  Future<void> _pickImage(BuildContext ctx, bool isAr) async {
    final picker = ImagePicker();
    final xFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (xFile == null || !mounted) return;
    // TODO: Upload image to server and send URL as message
    AppUtils.showSnack(ctx, isAr ? 'قريباً: إرسال الصور' : 'Coming soon: image sending');
  }

  void _showRoomsDialog(BuildContext ctx, bool isAr) {
    showModalBottomSheet(
      context: ctx,
      builder: (bCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(isAr ? 'الغرف' : 'Rooms',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontFamily: 'Cairo', fontSize: 16)),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.group),
                title: Text(isAr ? 'الشات العام' : 'General Chat', style: const TextStyle(fontFamily: 'Cairo')),
                selected: widget.roomId == 'general',
                onTap: () => Navigator.pop(bCtx),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Pinned Message Bar ────────────────────────────────
class _PinnedMessageBar extends StatelessWidget {
  final ChatMessage msg;
  final bool isAr;
  const _PinnedMessageBar({required this.msg, required this.isAr});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: Colors.amber.withOpacity(0.1),
      child: Row(
        children: [
          const Icon(Icons.push_pin, size: 16, color: Colors.amber),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              msg.text,
              style: const TextStyle(fontSize: 12, fontFamily: 'Cairo', color: Colors.amber),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Message Bubble ────────────────────────────────────
class _MessageBubble extends StatelessWidget {
  final ChatMessage msg;
  final bool isMe;
  final bool isAdmin;
  final VoidCallback onDelete;
  final VoidCallback onPin;
  final VoidCallback onBan;

  const _MessageBubble({
    required this.msg,
    required this.isMe,
    required this.isAdmin,
    required this.onDelete,
    required this.onPin,
    required this.onBan,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (msg.deleted) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text('🗑 رسالة محذوفة',
            style: const TextStyle(color: Colors.grey, fontSize: 12, fontFamily: 'Cairo',
                fontStyle: FontStyle.italic)),
      );
    }

    return GestureDetector(
      onLongPress: () => _showOptions(context),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isMe) ...[
              CircleAvatar(
                radius: 16,
                backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                child: Text(AppUtils.initials(msg.name),
                    style: TextStyle(fontSize: 11, color: theme.colorScheme.primary, fontFamily: 'Cairo')),
              ),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isMe
                      ? theme.colorScheme.primary
                      : msg.isAdminLike
                          ? AppColors.ok.withOpacity(0.15)
                          : theme.cardColor,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isMe ? 16 : 4),
                    bottomRight: Radius.circular(isMe ? 4 : 16),
                  ),
                  border: msg.isAdminLike && !isMe
                      ? Border.all(color: AppColors.ok.withOpacity(0.4))
                      : null,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isMe) ...[
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(msg.name,
                              style: TextStyle(
                                  fontSize: 11, fontWeight: FontWeight.w700,
                                  color: msg.isAdminLike ? AppColors.ok : theme.colorScheme.primary,
                                  fontFamily: 'Cairo')),
                          if (msg.isAdminLike) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: AppColors.ok.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text('Coach',
                                  style: TextStyle(fontSize: 9, color: AppColors.ok, fontFamily: 'Cairo')),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                    ],
                    Text(
                      msg.text,
                      style: TextStyle(
                          fontSize: 14, fontFamily: 'Cairo',
                          color: isMe ? Colors.white : theme.textTheme.bodyMedium?.color),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatTs(msg.ts),
                      style: TextStyle(
                          fontSize: 10,
                          color: isMe ? Colors.white60 : Colors.grey,
                          fontFamily: 'Cairo'),
                    ),
                  ],
                ),
              ),
            ),
            if (isMe) const SizedBox(width: 6),
          ],
        ),
      ),
    );
  }

  String _formatTs(int ts) {
    final dt = DateTime.fromMillisecondsSinceEpoch(ts);
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  void _showOptions(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      builder: (bCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isMe || isAdmin)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: AppColors.error),
                title: const Text('حذف', style: TextStyle(fontFamily: 'Cairo', color: AppColors.error)),
                onTap: () { Navigator.pop(bCtx); onDelete(); },
              ),
            if (isAdmin) ...[
              ListTile(
                leading: const Icon(Icons.push_pin_outlined),
                title: const Text('تثبيت', style: TextStyle(fontFamily: 'Cairo')),
                onTap: () { Navigator.pop(bCtx); onPin(); },
              ),
              if (!isMe)
                ListTile(
                  leading: const Icon(Icons.block, color: AppColors.error),
                  title: const Text('حظر المستخدم', style: TextStyle(fontFamily: 'Cairo', color: AppColors.error)),
                  onTap: () { Navigator.pop(bCtx); onBan(); },
                ),
            ],
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')),
              onTap: () => Navigator.pop(bCtx),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Input Bar ─────────────────────────────────────────
class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isAr;
  final bool isSending;
  final VoidCallback onSend;
  final VoidCallback onAttach;

  const _InputBar({
    required this.controller,
    required this.isAr,
    required this.isSending,
    required this.onSend,
    required this.onAttach,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.attach_file, size: 22),
              onPressed: onAttach,
            ),
            Expanded(
              child: TextField(
                controller: controller,
                maxLines: 4,
                minLines: 1,
                style: const TextStyle(fontFamily: 'Cairo', fontSize: 14),
                decoration: InputDecoration(
                  hintText: isAr ? 'اكتب رسالة...' : 'Type a message...',
                  hintStyle: const TextStyle(fontFamily: 'Cairo', color: Colors.grey),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  isDense: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                  filled: true,
                ),
                onSubmitted: (_) => onSend(),
              ),
            ),
            const SizedBox(width: 8),
            isSending
                ? const SizedBox(
                    width: 40, height: 40,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : IconButton(
                    icon: Icon(Icons.send, color: theme.colorScheme.primary),
                    onPressed: onSend,
                  ),
          ],
        ),
      ),
    );
  }
}

class _BannedBar extends StatelessWidget {
  final bool isAr;
  const _BannedBar({required this.isAr});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      color: AppColors.error.withOpacity(0.1),
      child: Text(
        isAr ? '🚫 تم حظرك من الشات' : '🚫 You are banned from chat',
        style: const TextStyle(color: AppColors.error, fontFamily: 'Cairo', fontSize: 13),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _MutedBar extends StatelessWidget {
  final int until;
  final bool isAr;
  const _MutedBar({required this.until, required this.isAr});

  @override
  Widget build(BuildContext context) {
    final dt = DateTime.fromMillisecondsSinceEpoch(until);
    return Container(
      padding: const EdgeInsets.all(12),
      color: AppColors.warn.withOpacity(0.1),
      child: Text(
        '${isAr ? "🔇 تم كتمك حتى" : "🔇 Muted until"}: ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}',
        style: const TextStyle(color: AppColors.warn, fontFamily: 'Cairo', fontSize: 13),
        textAlign: TextAlign.center,
      ),
    );
  }
}
