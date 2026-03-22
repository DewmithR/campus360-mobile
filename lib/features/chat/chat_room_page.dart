import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/models/app_user.dart';
import '../../theme/app_theme.dart';
import '../../core/services/chat_service.dart';

class ChatRoomPage extends StatefulWidget {
  final String chatId;
  final String otherName;
  final String otherUid;
  final AppUser currentUser;

  const ChatRoomPage({
    super.key,
    required this.chatId,
    required this.otherName,
    required this.otherUid,
    required this.currentUser,
  });

  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _chatService  = ChatService();
  bool _isSending = false;

  String get _currentUid => FirebaseAuth.instance.currentUser!.uid;

  String get _otherInitials {
    final parts = widget.otherName.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    if (parts.isNotEmpty && parts[0].isNotEmpty) return parts[0][0].toUpperCase();
    return '?';
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSending = true);
    _msgCtrl.clear();

    try {
      await _chatService.sendMessage(chatId: widget.chatId, text: text);
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showMessageOptions(BuildContext context, String messageId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: const BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.only(
            topLeft:  Radius.circular(AppRadius.xl),
            topRight: Radius.circular(AppRadius.xl),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.neutralBorder,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.alert.withAlpha(15),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: const Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.alert,
                ),
              ),
              title: Text(
                'Delete Message',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.alert,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                'Deleted for everyone',
                style: AppTextStyles.caption,
              ),
              onTap: () async {
                Navigator.pop(context);
                await _chatService.deleteMessage(
                  chatId:    widget.chatId,
                  messageId: messageId,
                );
              },
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutralLight,
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                _otherInitials,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(widget.otherName),
          ],
        ),
      ),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _chatService.streamMessages(widget.chatId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allDocs = snapshot.data?.docs ?? [];

                // Filter out messages deleted by current user
                final docs = allDocs.where((doc) {
                  final data       = doc.data() as Map<String, dynamic>;
                  final deletedFor = List<String>.from(data['deletedFor'] ?? []);
                  return !deletedFor.contains(_currentUid);
                }).toList();

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.waving_hand_rounded,
                          size: 40,
                          color: AppColors.primary.withAlpha(120),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Say hello to ${widget.otherName.split(' ').first}!',
                          style: AppTextStyles.bodySmall,
                        ),
                      ],
                    ),
                  );
                }

                // Scroll to bottom on new messages
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollCtrl.hasClients) {
                    _scrollCtrl.jumpTo(
                      _scrollCtrl.position.maxScrollExtent,
                    );
                  }
                });

                return ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final isMe = data['senderUid'] == _currentUid;
                    final text = data['text'] as String? ?? '';
                    final timestamp = data['timestamp'] as Timestamp?;

                    // Show date separator if needed
                    bool showDate = false;
                    if (index == 0) {
                      showDate = true;
                    } else {
                      final prevData = docs[index - 1].data()
                          as Map<String, dynamic>;
                      final prevTs = prevData['timestamp'] as Timestamp?;
                      if (prevTs != null && timestamp != null) {
                        final prev = prevTs.toDate();
                        final curr = timestamp.toDate();
                        showDate = prev.day != curr.day ||
                            prev.month != curr.month ||
                            prev.year != curr.year;
                      }
                    }

                    return Column(
                      children: [
                        if (showDate && timestamp != null)
                          _DateSeparator(timestamp: timestamp),
                        _MessageBubble(
                          messageId: doc.id,
                          text: text,
                          isMe: isMe,
                          timestamp: timestamp,
                          onLongPress: isMe
                              ? () => _showMessageOptions(context, doc.id)
                              : null,
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),

          //Message Input
          _MessageInput(
            controller: _msgCtrl,
            isSending: _isSending,
            onSend:  _sendMessage,
          ),
        ],
      ),
    );
  }
}

// Message Bubble
class _MessageBubble extends StatelessWidget {
  final String messageId;
  final String text;
  final bool isMe;
  final Timestamp? timestamp;
  final VoidCallback? onLongPress;

  const _MessageBubble({
    required this.messageId,
    required this.text,
    required this.isMe,
    required this.timestamp,
    this.onLongPress,
  });

  String _formatTime(Timestamp ts) {
    final dt = ts.toDate();
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: onLongPress,
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: EdgeInsets.only(
            top: 2,
            bottom: 2,
            left: isMe ? 64 : 0,
            right: isMe ? 0 : 64,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: isMe ? AppColors.primary : AppColors.surfaceCard,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(AppRadius.lg),
              topRight: const Radius.circular(AppRadius.lg),
              bottomLeft: Radius.circular(isMe ? AppRadius.lg : 4),
              bottomRight: Radius.circular(isMe ? 4 : AppRadius.lg),
            ),
            border: isMe
                ? null
                : const Border.fromBorderSide(
                    BorderSide(color: AppColors.neutralBorder, width: 0.8),
                  ),
            boxShadow: AppShadows.subtle,
          ),
          child: Column(
            crossAxisAlignment:
                isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Text(
                text,
                style: AppTextStyles.body.copyWith(
                  color: isMe ? Colors.white : AppColors.neutralDark,
                  fontSize: 14,
                ),
              ),
              if (timestamp != null) ...[
                const SizedBox(height: 2),
                Text(
                  _formatTime(timestamp!),
                  style: AppTextStyles.caption.copyWith(
                    color: isMe
                        ? Colors.white.withAlpha(160)
                        : AppColors.neutralMid,
                    fontSize: 10,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// Date Separator
class _DateSeparator extends StatelessWidget {
  final Timestamp timestamp;
  const _DateSeparator({required this.timestamp});

  String _formatDate() {
    final dt = timestamp.toDate();
    final now = DateTime.now();
    if (dt.day == now.day && dt.month == now.month && dt.year == now.year) {
      return 'Today';
    }
    final yesterday = now.subtract(const Duration(days: 1));
    if (dt.day == yesterday.day &&
        dt.month == yesterday.month &&
        dt.year == yesterday.year) {
      return 'Yesterday';
    }
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        children: [
          const Expanded(child: Divider()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Text(
              _formatDate(),
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Expanded(child: Divider()),
        ],
      ),
    );
  }
}

// Message Input Bar
class _MessageInput extends StatelessWidget {
  final TextEditingController controller;
  final bool isSending;
  final VoidCallback onSend;

  const _MessageInput({
    required this.controller,
    required this.isSending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.sm + MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceCard,
        border: Border(
          top: BorderSide(color: AppColors.neutralBorder, width: 0.8),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Text field
            Expanded(
              child: TextField(
                controller: controller,
                maxLines: 4,
                minLines: 1,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: AppTextStyles.bodySmall,
                  filled: true,
                  fillColor: AppColors.neutralLight,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    borderSide: const BorderSide(
                      color: AppColors.neutralBorder,
                      width: 0.8,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    borderSide: const BorderSide(
                      color: AppColors.neutralBorder,
                      width: 0.8,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(width: AppSpacing.sm),

            // Send button
            GestureDetector(
              onTap: isSending ? null : onSend,
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: isSending ? null : AppColors.primaryGradient,
                  color: isSending ? AppColors.neutralBorder : null,
                  shape: BoxShape.circle,
                  boxShadow: isSending ? null : AppShadows.subtle,
                ),
                alignment: Alignment.center,
                child: isSending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.neutralMid,
                        ),
                      )
                    : const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}