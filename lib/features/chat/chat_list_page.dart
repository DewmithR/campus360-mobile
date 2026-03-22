import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/models/app_user.dart';
import '../../theme/app_theme.dart';
import '../../core/services/chat_service.dart';
import 'chat_room_page.dart';

class ChatListPage extends StatelessWidget {
  final AppUser user;
  final ChatService _chatService = ChatService();

  ChatListPage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: AppColors.neutralLight,
      appBar: AppBar(
        title: const Text('Chat'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: TextButton.icon(
              onPressed: () => _showNewChatDialog(context),
              icon: const Icon(Icons.edit_rounded, size: 18, color: Colors.white),
              label: const Text(
                'New Chat',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _chatService.streamChatList(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _EmptyState(onNewChat: () => _showNewChatDialog(context));
          }

          // Filter out chats deleted by current user
          final chats = snapshot.data!.docs.where((doc) {
            final data      = doc.data() as Map<String, dynamic>;
            final deletedFor = List<String>.from(data['deletedFor'] ?? []);
            return !deletedFor.contains(uid);
          }).toList();

          if (chats.isEmpty) {
            return _EmptyState(onNewChat: () => _showNewChatDialog(context));
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            itemCount: chats.length,
            separatorBuilder: (_, __) => const Divider(
              height: 1,
              indent: 72,
              endIndent: AppSpacing.md,
            ),
            itemBuilder: (context, index) {
              final doc  = chats[index];
              final data = doc.data() as Map<String, dynamic>;
              return _ChatTile(
                chatId: doc.id,
                data: data,
                currentUid: uid,
                currentUser: user,
                chatService: _chatService,
              );
            },
          );
        },
      ),
    );
  }

  // New Chat Dialog
  void _showNewChatDialog(BuildContext context) {
    final emailCtrl = TextEditingController();
    bool isLoading  = false;
    String? error;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('New Chat'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter the NSBM student email to start a chat.',
                style: AppTextStyles.bodySmall,
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Student Email',
                  hintText: 'student@students.nsbm.ac.lk',
                  prefixIcon: const Icon(Icons.email_outlined),
                  errorText: error,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      final email = emailCtrl.text.trim();
                      if (email.isEmpty) {
                        setState(() => error = 'Please enter an email');
                        return;
                      }

                      final uid = FirebaseAuth.instance.currentUser!.uid;

                      if (email.toLowerCase() == user.email.toLowerCase()) {
                        setState(() => error = 'You cannot chat with yourself');
                        return;
                      }

                      setState(() {
                        isLoading = true;
                        error = null;
                      });

                      final found = await ChatService().findUserByEmail(email);

                      if (found == null) {
                        setState(() {
                          isLoading = false;
                          error = 'No student found with this email';
                        });
                        return;
                      }

                      final chatId = await ChatService().getOrCreateChat(
                        currentUid: uid,
                        currentName: user.name,
                        otherUid: found['uid'] as String,
                        otherName: found['name'] as String,
                      );

                      if (context.mounted) {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatRoomPage(
                              chatId: chatId,
                              otherName: found['name'] as String,
                              otherUid: found['uid'] as String,
                              currentUser: user,
                            ),
                          ),
                        );
                      }
                    },
              child: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Start Chat'),
            ),
          ],
        ),
      ),
    );
  }
}

// Chat Tile
class _ChatTile extends StatelessWidget {
  final String chatId;
  final Map<String, dynamic> data;
  final String currentUid;
  final AppUser currentUser;
  final ChatService chatService;

  const _ChatTile({
    required this.chatId,
    required this.data,
    required this.currentUid,
    required this.currentUser,
    required this.chatService,
  });

  String get _otherUid {
    final participants = List<String>.from(data['participants'] ?? []);
    return participants.firstWhere((uid) => uid != currentUid, orElse: () => '');
  }

  String get _otherName {
    final names = Map<String, dynamic>.from(data['participantNames'] ?? {});
    return names[_otherUid] as String? ?? 'Unknown';
  }

  String get _initials {
    final parts = _otherName.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    if (parts.isNotEmpty && parts[0].isNotEmpty) return parts[0][0].toUpperCase();
    return '?';
  }

  String _formatTime(Timestamp? ts) {
    if (ts == null) return '';
    final dt  = ts.toDate();
    final now = DateTime.now();
    if (dt.day == now.day && dt.month == now.month && dt.year == now.year) {
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '$h:$m';
    }
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${dt.day} ${months[dt.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final lastMessage = data['lastMessage'] as String? ?? '';
    final lastMessageTime = data['lastMessageTime'] as Timestamp?;

    return Dismissible(
      key: Key(chatId),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.lg),
        color: AppColors.alert,
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete Chat'),
            content: const Text(
              'This will delete the chat from your view. The other person will still see it.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.alert,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) => chatService.deleteChat(chatId),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.xs,
        ),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            _initials,
            style: const TextStyle(
              fontFamily: 'Roboto',
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
        ),
        title: Text(
          _otherName,
          style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          lastMessage.isEmpty ? 'No messages yet' : lastMessage,
          style: AppTextStyles.bodySmall,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Text(
          _formatTime(lastMessageTime),
          style: AppTextStyles.caption,
        ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatRoomPage(
              chatId:      chatId,
              otherName:   _otherName,
              otherUid:    _otherUid,
              currentUser: currentUser,
            ),
          ),
        ),
      ),
    );
  }
}

// Empty State
class _EmptyState extends StatelessWidget {
  final VoidCallback onNewChat;
  const _EmptyState({required this.onNewChat});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chat_bubble_outline_rounded,
                size: 56,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'No Conversations Yet',
              style: AppTextStyles.heading2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Start a new chat by tapping the button above.',
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton.icon(
              onPressed: onNewChat,
              icon: const Icon(Icons.edit_rounded, size: 18),
              label: const Text('Start a New Chat'),
            ),
          ],
        ),
      ),
    );
  }
}