import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../channels/channels_view.dart';
import '../chats/chat_list_view.dart';
import '../conversation/conversation_view.dart';
import '../groups/groups_view.dart';
import '../profile/profile_view.dart';
import '../wallet/wallet_view.dart';
import 'home_controller.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < AppDimensions.breakpointCompact;
        final isExpanded = constraints.maxWidth >= AppDimensions.breakpointExpanded;

        final tabs = [
          const ChatListView(),
          const GroupsView(),
          const ChannelsView(),
          const WalletView(),
          const ProfileView(),
        ];

        if (isCompact) {
          return Scaffold(
            body: Obx(() => tabs[controller.currentTabIndex.value]),
            bottomNavigationBar: Obx(
              () => BottomNavigationBar(
                currentIndex: controller.currentTabIndex.value,
                onTap: controller.changeTab,
                items: [
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.chat_bubble_outline_rounded),
                    activeIcon: const Icon(Icons.chat_bubble_rounded),
                    label: 'chats'.tr,
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.groups_outlined),
                    activeIcon: const Icon(Icons.groups_rounded),
                    label: 'groups'.tr,
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.campaign_outlined),
                    activeIcon: const Icon(Icons.campaign_rounded),
                    label: 'channels'.tr,
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.account_balance_wallet_outlined),
                    activeIcon: const Icon(Icons.account_balance_wallet_rounded),
                    label: 'wallet'.tr,
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.person_outline_rounded),
                    activeIcon: const Icon(Icons.person_rounded),
                    label: 'profile'.tr,
                  ),
                ],
              ),
            ),
          );
        }

        // Medium or Expanded screen (Tablet / Desktop Web)
        return Scaffold(
          body: Row(
            children: [
              // Navigation Rail
              Obx(
                () => NavigationRail(
                  selectedIndex: controller.currentTabIndex.value,
                  onDestinationSelected: controller.changeTab,
                  labelType: NavigationRailLabelType.all,
                  leading: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: (isDark ? AppColors.darkPrimary : AppColors.lightPrimary).withValues(alpha: 0.15),
                        border: Border.all(
                          color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        Icons.bolt_rounded,
                        color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                      ),
                    ),
                  ),
                  destinations: [
                    NavigationRailDestination(
                      icon: const Icon(Icons.chat_bubble_outline_rounded),
                      selectedIcon: const Icon(Icons.chat_bubble_rounded),
                      label: Text('chats'.tr),
                    ),
                    NavigationRailDestination(
                      icon: const Icon(Icons.groups_outlined),
                      selectedIcon: const Icon(Icons.groups_rounded),
                      label: Text('groups'.tr),
                    ),
                    NavigationRailDestination(
                      icon: const Icon(Icons.campaign_outlined),
                      selectedIcon: const Icon(Icons.campaign_rounded),
                      label: Text('channels'.tr),
                    ),
                    NavigationRailDestination(
                      icon: const Icon(Icons.account_balance_wallet_outlined),
                      selectedIcon: const Icon(Icons.account_balance_wallet_rounded),
                      label: Text('wallet'.tr),
                    ),
                    NavigationRailDestination(
                      icon: const Icon(Icons.person_outline_rounded),
                      selectedIcon: const Icon(Icons.person_rounded),
                      label: Text('profile'.tr),
                    ),
                  ],
                ),
              ),

              const VerticalDivider(width: 1),

              // Master-Detail Pane on Expanded screens when on Chats tab
              Expanded(
                child: Obx(() {
                  final activeTabIdx = controller.currentTabIndex.value;

                  if (isExpanded && activeTabIdx == 0) {
                    return Row(
                      children: [
                        const SizedBox(
                          width: 360,
                          child: ChatListView(),
                        ),
                        const VerticalDivider(width: 1),
                        Expanded(
                          child: controller.activeConversationId.value != null
                              ? ConversationView(
                                  conversationId: controller.activeConversationId.value!,
                                  conversationTitle: controller.activeConversationTitle.value.isNotEmpty
                                      ? controller.activeConversationTitle.value
                                      : 'Chat',
                                )
                              : Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.chat_bubble_outline_rounded,
                                        size: 64,
                                        color: theme.colorScheme.outline.withValues(alpha: 0.5),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Select a conversation',
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Choose a conversation from the list to start messaging.',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: theme.colorScheme.outline,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                        ),
                      ],
                    );
                  }

                  return tabs[activeTabIdx];
                }),
              ),
            ],
          ),
        );
      },
    );
  }
}
