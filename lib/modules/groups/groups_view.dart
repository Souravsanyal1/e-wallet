import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/avatar.dart';
import '../../core/widgets/empty_state.dart';
import '../../data/models/conversation_model.dart';
import '../../data/repositories/chat_repository.dart';
import '../../routes/app_routes.dart';

class GroupsController extends GetxController {
  final ChatRepository _chatRepository;

  GroupsController(this._chatRepository);

  final RxList<ConversationModel> groups = <ConversationModel>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadGroups();
  }

  Future<void> loadGroups() async {
    isLoading.value = true;
    final res = await _chatRepository.fetchConversations();
    res.when(
      ok: (list) {
        groups.assignAll(list.where((c) => c.isGroup).toList());
        isLoading.value = false;
      },
      err: (_) {
        isLoading.value = false;
      },
    );
  }

  Future<void> createGroup(String title, List<String> handles) async {
    final res = await _chatRepository.createGroupConversation(
      title: title,
      memberHandles: handles,
    );
    res.when(
      ok: (newGroup) {
        groups.insert(0, newGroup);
        Get.toNamed(
          '${AppRoutes.conversation}?id=${newGroup.id}&title=${Uri.encodeComponent(newGroup.title)}',
        );
      },
      err: (_) {},
    );
  }
}

class GroupsView extends GetView<GroupsController> {
  const GroupsView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: Text('groups'.tr),
        actions: [
          IconButton(
            icon: const Icon(Icons.group_add_rounded),
            tooltip: 'Create Group',
            onPressed: () => _showCreateGroupDialog(context),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: AppLoader(label: 'Loading groups...'));
        }

        if (controller.groups.isEmpty) {
          return EmptyState(
            icon: Icons.groups_rounded,
            title: 'No groups yet',
            message: 'Create a community group or join an existing circle.',
            actionText: 'Create Group',
            onAction: () => _showCreateGroupDialog(context),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: controller.groups.length,
          separatorBuilder: (_, _) => Divider(
            indent: 76,
            height: 1,
            color: isDark ? AppColors.darkOutline : AppColors.lightOutline,
          ),
          itemBuilder: (context, index) {
            final grp = controller.groups[index];
            return ListTile(
              leading: Avatar(name: grp.title, size: 48),
              title: Text(grp.title, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(
                '${grp.memberCount} members · ${grp.lastMessagePreview ?? ""}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                Get.toNamed(
                  '${AppRoutes.conversation}?id=${grp.id}&title=${Uri.encodeComponent(grp.title)}',
                );
              },
            );
          },
        );
      }),
      floatingActionButton: FloatingActionButton(
        backgroundColor: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
        foregroundColor: isDark ? AppColors.darkOnPrimary : AppColors.lightOnPrimary,
        onPressed: () => _showCreateGroupDialog(context),
        child: const Icon(Icons.group_add_rounded),
      ),
    );
  }

  void _showCreateGroupDialog(BuildContext context) {
    final titleEdit = TextEditingController();
    final membersEdit = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: const Text('Create New Community Group'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Group Title:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            TextField(
              controller: titleEdit,
              decoration: const InputDecoration(hintText: 'e.g. DeFi Research DAO'),
            ),
            const SizedBox(height: 16),
            const Text('Initial Members (comma-separated handles):',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            TextField(
              controller: membersEdit,
              decoration: const InputDecoration(hintText: '@alice, @bob, @charlie'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('cancel'.tr)),
          ElevatedButton(
            onPressed: () {
              final title = titleEdit.text.trim();
              if (title.isNotEmpty) {
                final handles = membersEdit.text
                    .split(',')
                    .map((s) => s.trim())
                    .where((s) => s.isNotEmpty)
                    .toList();
                Get.back();
                controller.createGroup(title, handles);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}
