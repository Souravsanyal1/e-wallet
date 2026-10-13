import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/widgets/avatar.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/status_badge.dart';
import '../../data/models/message_model.dart';
import 'conversation_controller.dart';

class ConversationView extends StatelessWidget {
  final String? conversationId;
  final String? conversationTitle;

  const ConversationView({
    super.key,
    this.conversationId,
    this.conversationTitle,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveId = conversationId ?? Get.parameters['id'] ?? 'c_alice';
    final effectiveTitle = conversationTitle ?? Get.parameters['title'] ?? 'Alice Chen';

    final controller = Get.isRegistered<ConversationController>(tag: effectiveId)
        ? Get.find<ConversationController>(tag: effectiveId)
        : Get.put(
            ConversationController(Get.find(), effectiveId),
            tag: effectiveId,
          );

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            Avatar(name: effectiveTitle, size: 38, showBadge: true, isOnline: true),
            const SizedBox(width: AppDimensions.space12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    effectiveTitle,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  Obx(
                    () => Text(
                      controller.isOtherTyping.value ? 'typing'.tr : 'online'.tr,
                      style: TextStyle(
                        fontSize: 12,
                        color: controller.isOtherTyping.value
                            ? (isDark ? AppColors.darkPrimary : AppColors.lightPrimary)
                            : AppColors.darkSuccess,
                        fontWeight: controller.isOtherTyping.value ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.shield_outlined),
            tooltip: 'Security info',
            onPressed: () {
              Get.dialog(
                AlertDialog(
                  title: const Text('End-to-End Status'),
                  content: const Text(
                    'Direct chat with RLS policies enabled. Identity is cryptographically '
                    'anchored to the recipient’s primary Ethereum address.',
                  ),
                  actions: [
                    TextButton(onPressed: () => Get.back(), child: const Text('OK')),
                  ],
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert_rounded),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Message list
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(child: AppLoader(label: 'Loading messages...'));
                }

                if (controller.messages.isEmpty) {
                  return EmptyState(
                    icon: Icons.chat_bubble_outline_rounded,
                    title: 'No messages yet',
                    message: 'Say hello to start the conversation!',
                    actionText: 'Say Hello 👋',
                    onAction: () {
                      controller.textController.text = 'Hello! 👋';
                      controller.sendCurrentMessage();
                    },
                  );
                }

                return ListView.builder(
                  controller: controller.scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.space16,
                    vertical: AppDimensions.space16,
                  ),
                  itemCount: controller.messages.length + (controller.isOtherTyping.value ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == controller.messages.length) {
                      return _buildTypingIndicatorBubble(isDark);
                    }
                    final msg = controller.messages[index];
                    final isMe = msg.senderId == 'me';
                    return _buildMessageBubble(context, msg, isMe, isDark, controller);
                  },
                );
              }),
            ),

            // Quoted Reply Bar
            Obx(() {
              final reply = controller.replyingTo.value;
              if (reply == null) return const SizedBox.shrink();

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: isDark ? AppColors.darkSurfaceHigh : AppColors.lightSurfaceHigh,
                child: Row(
                  children: [
                    Container(
                      width: 3,
                      height: 36,
                      color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'replying_to'.tr,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                            ),
                          ),
                          Text(
                            reply.content,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      onPressed: controller.clearReply,
                    ),
                  ],
                ),
              );
            }),

            // Composer
            _buildComposer(context, isDark, controller),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(
    BuildContext context,
    MessageModel msg,
    bool isMe,
    bool isDark,
    ConversationController controller,
  ) {
    final timeStr = DateFormat('HH:mm').format(msg.createdAt);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        constraints: const BoxConstraints(maxWidth: AppDimensions.maxBubbleWidth),
        decoration: BoxDecoration(
          color: isMe
              ? (isDark ? AppColors.bubbleOutgoingDark : AppColors.bubbleOutgoingLight)
              : (isDark ? AppColors.darkSurfaceHigh : AppColors.lightSurfaceHigh),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(AppDimensions.radiusMedium),
            topRight: const Radius.circular(AppDimensions.radiusMedium),
            bottomLeft: Radius.circular(isMe ? AppDimensions.radiusMedium : 4),
            bottomRight: Radius.circular(isMe ? 4 : AppDimensions.radiusMedium),
          ),
          border: Border.all(
            color: isMe
                ? (isDark ? AppColors.bubbleOutgoingBorderDark : const Color(0xFFE8D49E))
                : (isDark ? AppColors.darkOutline : AppColors.lightOutline),
            width: 1,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // Quoted reply snippet inside bubble
            if (msg.replySnippet != null) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: isDark ? AppColors.darkOutline : AppColors.lightOutline),
                ),
                child: Text(
                  msg.replySnippet!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic),
                ),
              ),
            ],
            Text(
              msg.content,
              style: TextStyle(
                fontSize: 15,
                height: 1.35,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  timeStr,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  StatusBadge(status: msg.status),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicatorBubble(bool isDark) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurfaceHigh : AppColors.lightSurfaceHigh,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'typing'.tr,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(width: 6),
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComposer(BuildContext context, bool isDark, ConversationController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkOutline : AppColors.lightOutline,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded),
            color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
            onPressed: () {
              Get.snackbar(
                'Media Attachments',
                'Image & document attachments encrypted and stored via Supabase Storage buckets.',
                duration: const Duration(seconds: 2),
              );
            },
          ),
          Expanded(
            child: TextField(
              controller: controller.textController,
              maxLines: 5,
              minLines: 1,
              style: TextStyle(
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                fontSize: 15,
              ),
              decoration: InputDecoration(
                hintText: 'message_hint'.tr,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              onSubmitted: (_) => controller.sendCurrentMessage(),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(bottom: 4),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(
                Icons.send_rounded,
                size: 20,
                color: isDark ? AppColors.darkOnPrimary : AppColors.lightOnPrimary,
              ),
              onPressed: controller.sendCurrentMessage,
            ),
          ),
        ],
      ),
    );
  }
}
