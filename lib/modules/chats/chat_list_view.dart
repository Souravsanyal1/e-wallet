import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/widgets/avatar.dart';
import '../../core/widgets/empty_state.dart';
import '../../routes/app_routes.dart';
import 'chat_list_controller.dart';

class ChatListView extends GetView<ChatListController> {
  const ChatListView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: Text('chats'.tr),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner_rounded),
            tooltip: 'Scan Wallet QR',
            onPressed: () {
              Get.snackbar(
                'WalletConnect QR',
                'Camera scanner opens to pair mobile wallets and desktop clients.',
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.space16,
              vertical: AppDimensions.space8,
            ),
            child: TextField(
              onChanged: (v) => controller.searchQuery.value = v,
              decoration: InputDecoration(
                hintText: 'search_hint'.tr,
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ),

          // Conversation list
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: AppLoader(label: 'Loading conversations...'));
              }

              final list = controller.filteredConversations;
              if (list.isEmpty) {
                return EmptyState(
                  icon: Icons.forum_outlined,
                  title: 'No conversations',
                  message: 'Start a direct chat with another handle or wallet.',
                  actionText: 'New Chat',
                  onAction: () => _showNewChatDialog(context),
                );
              }

              return RefreshIndicator(
                onRefresh: controller.loadConversations,
                color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: list.length,
                  separatorBuilder: (_, _) => Divider(
                    indent: 76,
                    height: 1,
                    color: isDark ? AppColors.darkOutline : AppColors.lightOutline,
                  ),
                  itemBuilder: (context, index) {
                    final conv = list[index];
                    final timeStr = conv.lastMessageAt != null
                        ? DateFormat('HH:mm').format(conv.lastMessageAt!)
                        : '';

                    return InkWell(
                      onTap: () {
                        Get.toNamed(
                          '${AppRoutes.conversation}?id=${conv.id}&title=${Uri.encodeComponent(conv.title)}',
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimensions.space16,
                          vertical: AppDimensions.space12,
                        ),
                        child: Row(
                          children: [
                            Avatar(
                              name: conv.title,
                              size: 48,
                              showBadge: conv.isDirect,
                              isOnline: conv.otherUser?.isOnline ?? false,
                            ),
                            const SizedBox(width: AppDimensions.space12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          conv.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      if (timeStr.isNotEmpty) ...[
                                        const SizedBox(width: 8),
                                        Text(
                                          timeStr,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isDark
                                                ? AppColors.darkTextSecondary
                                                : AppColors.lightTextSecondary,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          conv.lastMessagePreview ?? 'No messages yet',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: isDark
                                                ? AppColors.darkTextSecondary
                                                : AppColors.lightTextSecondary,
                                          ),
                                        ),
                                      ),
                                      if (conv.unreadCount > 0) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 7,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isDark
                                                ? AppColors.darkPrimary
                                                : AppColors.lightPrimary,
                                            borderRadius: AppDimensions.borderPill,
                                          ),
                                          child: Text(
                                            conv.unreadCount > 99 ? '99+' : '${conv.unreadCount}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: isDark
                                                  ? AppColors.darkOnPrimary
                                                  : AppColors.lightOnPrimary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
        foregroundColor: isDark ? AppColors.darkOnPrimary : AppColors.lightOnPrimary,
        onPressed: () => _showNewChatDialog(context),
        child: const Icon(Icons.edit_rounded),
      ),
    );
  }

  void _showNewChatDialog(BuildContext context) {
    final textEdit = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: const Text('Start New Direct Chat'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter username handle or ENS/address to establish a secure DM:',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: textEdit,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: '@charlie or 0x...',
                prefixIcon: Icon(Icons.alternate_email_rounded, size: 18),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('cancel'.tr),
          ),
          ElevatedButton(
            onPressed: () {
              final handle = textEdit.text.trim();
              if (handle.isNotEmpty) {
                Get.back();
                controller.startDirectChat(handle);
              }
            },
            child: const Text('Start Chat'),
          ),
        ],
      ),
    );
  }
}
