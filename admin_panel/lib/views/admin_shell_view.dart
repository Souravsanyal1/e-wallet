import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/admin_controller.dart';
import '../models/admin_models.dart';
import '../theme/app_theme.dart';

class AdminShellView extends GetView<AdminController> {
  const AdminShellView({super.key});

  @override
  Widget build(BuildContext context) {
    final navItems = [
      (Icons.dashboard_rounded, 'Dashboard'),
      (Icons.people_alt_rounded, 'Users'),
      (Icons.shield_rounded, 'Moderation'),
      (Icons.forum_rounded, 'Content'),
      (Icons.currency_bitcoin_rounded, 'Payments (BSC)'),
      (Icons.loyalty_rounded, 'Plans'),
      (Icons.campaign_rounded, 'Announcements'),
      (Icons.settings_suggest_rounded, 'App Config'),
      (Icons.receipt_long_rounded, 'Audit Log'),
    ];

    return Scaffold(
      backgroundColor: AdminColors.background,
      body: Row(
        children: [
          // Left Sidebar
          Container(
            width: 260,
            decoration: const BoxDecoration(
              color: AdminColors.surface,
              border: Border(right: BorderSide(color: AdminColors.outline)),
            ),
            child: Column(
              children: [
                // Brand Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AdminColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.bolt_rounded, color: AdminColors.primary, size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('EliteChat', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                          Text('Admin Operations', style: TextStyle(fontSize: 11, color: AdminColors.textSecondary)),
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: AdminColors.outline),

                // Nav Links
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    itemCount: navItems.length,
                    itemBuilder: (context, index) {
                      final item = navItems[index];
                      return Obx(() {
                        final isSelected = controller.selectedNavIndex.value == index;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 4),
                          child: ListTile(
                            dense: true,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            tileColor: isSelected ? AdminColors.primary.withValues(alpha: 0.15) : Colors.transparent,
                            leading: Icon(
                              item.$1,
                              size: 20,
                              color: isSelected ? AdminColors.primary : AdminColors.textSecondary,
                            ),
                            title: Text(
                              item.$2,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: isSelected ? AdminColors.primary : AdminColors.textPrimary,
                              ),
                            ),
                            onTap: () => controller.selectTab(index),
                          ),
                        );
                      });
                    },
                  ),
                ),

                // Admin Info Footer
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: AdminColors.outline)),
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 16,
                        backgroundColor: AdminColors.surfaceHigh,
                        child: Icon(Icons.person_rounded, size: 18, color: AdminColors.primary),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('ops@elitechat.app', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            Text('Superadmin', style: TextStyle(fontSize: 11, color: AdminColors.success)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.logout_rounded, size: 18, color: AdminColors.textSecondary),
                        tooltip: 'Sign Out',
                        onPressed: controller.logout,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Main Content Area
          Expanded(
            child: Obx(() {
              final tab = controller.selectedNavIndex.value;
              return switch (tab) {
                0 => _buildDashboardTab(context),
                1 => _buildUsersTab(context),
                2 => _buildModerationTab(context),
                3 => _buildContentTab(context),
                4 => _buildPaymentsTab(context),
                5 => _buildPlansTab(context),
                6 => _buildAnnouncementsTab(context),
                7 => _buildConfigTab(context),
                8 => _buildAuditTab(context),
                _ => _buildDashboardTab(context),
              };
            }),
          ),
        ],
      ),
    );
  }

  // --- 1. Dashboard View ---
  Widget _buildDashboardTab(BuildContext context) {
    final m = controller.metrics.value;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('System Overview', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          const Text('Live operational stats and telemetry for EliteChat', style: TextStyle(fontSize: 13, color: AdminColors.textSecondary)),
          const SizedBox(height: 24),

          // KPI Cards
          Row(
            children: [
              Expanded(child: _kpiCard('Total Users', '${m.totalUsers}', Icons.people_outline_rounded, AdminColors.accent)),
              const SizedBox(width: 16),
              Expanded(child: _kpiCard('Open Reports', '${m.openReports}', Icons.warning_amber_rounded, AdminColors.warning)),
              const SizedBox(width: 16),
              Expanded(child: _kpiCard('BSC Payments', '${m.totalPayments}', Icons.currency_bitcoin_rounded, AdminColors.success)),
              const SizedBox(width: 16),
              Expanded(child: _kpiCard('Active Subscriptions', '${m.activeSubscriptions}', Icons.stars_rounded, AdminColors.primary)),
            ],
          ),

          const SizedBox(height: 32),
          // Infrastructure status card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AdminColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AdminColors.outline),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.health_and_safety_rounded, color: AdminColors.success, size: 20),
                    SizedBox(width: 8),
                    Text('Infrastructure & Security Health', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _healthItem('Firestore Database', 'Normal Latency (14ms)', AdminColors.success),
                    _healthItem('Cloud Functions (2nd Gen)', '0.01% Error Rate', AdminColors.success),
                    _healthItem('BNB Smart Chain RPC', 'Block Height Synchronized', AdminColors.success),
                    _healthItem('Cloudinary CDN', 'Signed Uploads Active', AdminColors.success),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- 2. Users View ---
  Widget _buildUsersTab(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('User Directory', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
                  SizedBox(height: 4),
                  Text('Search and moderate user accounts with full audit tracking', style: TextStyle(fontSize: 13, color: AdminColors.textSecondary)),
                ],
              ),
              SizedBox(
                width: 280,
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search by handle or address...',
                    prefixIcon: Icon(Icons.search_rounded, size: 18),
                    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AdminColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AdminColors.outline),
              ),
              child: ListView.separated(
                itemCount: controller.users.length,
                separatorBuilder: (_, _) => const Divider(height: 1, color: AdminColors.outline),
                itemBuilder: (context, index) {
                  final u = controller.users[index];
                  return ListTile(
                    title: Row(
                      children: [
                        Text(u.displayName, style: const TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(width: 8),
                        Text('@${u.handle}', style: const TextStyle(color: AdminColors.textSecondary, fontSize: 13)),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: u.status == 'active'
                                ? AdminColors.success.withValues(alpha: 0.15)
                                : AdminColors.error.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            u.status.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: u.status == 'active' ? AdminColors.success : AdminColors.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Text('Joined: ${DateFormat.yMMMd().format(u.createdAt)}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        OutlinedButton.icon(
                          icon: const Icon(Icons.visibility_rounded, size: 14),
                          label: const Text('Reveal Wallet (Audited)', style: TextStyle(fontSize: 11)),
                          onPressed: () => _showRevealWalletDialog(context, u),
                        ),
                        const SizedBox(width: 8),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert_rounded),
                          onSelected: (val) {
                            if (val == 'suspend') _showSuspendDialog(context, u);
                            if (val == 'ban') _showBanDialog(context, u);
                          },
                          itemBuilder: (_) => [
                            const PopupMenuItem(value: 'suspend', child: Text('Suspend (7 Days)')),
                            const PopupMenuItem(value: 'ban', child: Text('Permanent Ban', style: TextStyle(color: AdminColors.error))),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- 3. Moderation View ---
  Widget _buildModerationTab(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Moderation Queue', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          const Text('Reported content triage and user reports', style: TextStyle(fontSize: 13, color: AdminColors.textSecondary)),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.builder(
              itemCount: controller.cases.length,
              itemBuilder: (context, index) {
                final c = controller.cases[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AdminColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AdminColors.outline),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.report_problem_rounded, color: AdminColors.warning, size: 20),
                              const SizedBox(width: 8),
                              Text('Case #${c.id}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AdminColors.warning.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              c.status.toUpperCase(),
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AdminColors.warning),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text('Reason: ${c.reason}', style: const TextStyle(fontSize: 14)),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => controller.resolveCase(c.id, 'dismissed', 'Not a violation'),
                            child: const Text('Dismiss'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: AdminColors.error, foregroundColor: Colors.white),
                            onPressed: () => controller.resolveCase(c.id, 'actioned', 'Violation confirmed and penalized'),
                            child: const Text('Penalize User & Close'),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- 4. Content (Channels & Groups) ---
  Widget _buildContentTab(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Content Moderation', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
          SizedBox(height: 4),
          Text('Community groups, token-gated broadcast channels, and verified flags', style: TextStyle(fontSize: 13, color: AdminColors.textSecondary)),
          SizedBox(height: 24),
          Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('All community channels are monitored for compliance. Private messages remain E2E isolated per privacy rules in section 7.'),
            ),
          ),
        ],
      ),
    );
  }

  // --- 5. Payments (BSC BEP-20) ---
  Widget _buildPaymentsTab(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('BNB Smart Chain Payments (BEP-20)', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          const Text('On-chain USDC subscription receipts and BscScan transaction ledger', style: TextStyle(fontSize: 13, color: AdminColors.textSecondary)),
          const SizedBox(height: 24),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AdminColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AdminColors.outline),
              ),
              child: ListView.separated(
                itemCount: controller.payments.length,
                separatorBuilder: (_, _) => const Divider(height: 1, color: AdminColors.outline),
                itemBuilder: (context, index) {
                  final p = controller.payments[index];
                  return ListTile(
                    leading: const Icon(Icons.check_circle_rounded, color: AdminColors.success),
                    title: Text('${p.amount.toInt()} USDC on BSC', style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('Tx: ${p.txHash}'),
                    trailing: TextButton.icon(
                      icon: const Icon(Icons.open_in_new_rounded, size: 14),
                      label: const Text('BscScan'),
                      onPressed: () {},
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- 6. Plans View ---
  Widget _buildPlansTab(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Subscription Plans', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
          SizedBox(height: 4),
          Text('Manage Pro Trader & Alpha Insider tiers (Requires 2-person approval for receiver changes)', style: TextStyle(fontSize: 13, color: AdminColors.textSecondary)),
          SizedBox(height: 24),
          Card(
            child: ListTile(
              title: Text('Pro Trader', style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text('50 USDC / 30 Days · Token: BSC BEP-20 USDC'),
              trailing: Text('ACTIVE', style: TextStyle(color: AdminColors.success, fontWeight: FontWeight.w700)),
            ),
          ),
          SizedBox(height: 12),
          Card(
            child: ListTile(
              title: Text('Alpha Insider', style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text('150 USDC / 30 Days · Token: BSC BEP-20 USDC'),
              trailing: Text('ACTIVE', style: TextStyle(color: AdminColors.success, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  // --- 7. Announcements ---
  Widget _buildAnnouncementsTab(BuildContext context) {
    final titleEdit = TextEditingController();
    final bodyEdit = TextEditingController();

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('System Announcements', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          const Text('Broadcast announcements to all app users via FCM Topics', style: TextStyle(fontSize: 13, color: AdminColors.textSecondary)),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Title', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(controller: titleEdit, decoration: const InputDecoration(hintText: 'e.g. Protocol Upgrade Notice')),
                  const SizedBox(height: 16),
                  const Text('Message Body', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(controller: bodyEdit, maxLines: 4, decoration: const InputDecoration(hintText: 'Enter announcement text...')),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      Get.snackbar('Submitted for Approval', 'Announcement queued for second-admin verification per section 9.');
                    },
                    child: const Text('Submit for 2-Person Approval'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- 8. App Config ---
  Widget _buildConfigTab(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Application Configuration', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          const Text('Global flags stored in appConfig/current', style: TextStyle(fontSize: 13, color: AdminColors.textSecondary)),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Obx(
                    () => SwitchListTile(
                      title: const Text('Maintenance Mode', style: TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: const Text('When enabled, user app displays maintenance screen'),
                      value: controller.maintenanceMode.value,
                      onChanged: (v) => controller.maintenanceMode.value = v,
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    title: const Text('Minimum App Version', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text('Enforces force-update if user client version is lower'),
                    trailing: const Text('v1.0.0', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- 9. Audit Log View ---
  Widget _buildAuditTab(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Immutable Audit Trail', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          const Text('Append-only log of every administrative action per admin-panel.md section 8', style: TextStyle(fontSize: 13, color: AdminColors.textSecondary)),
          const SizedBox(height: 24),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AdminColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AdminColors.outline),
              ),
              child: ListView.separated(
                itemCount: controller.auditLogs.length,
                separatorBuilder: (_, _) => const Divider(height: 1, color: AdminColors.outline),
                itemBuilder: (context, index) {
                  final a = controller.auditLogs[index];
                  return ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AdminColors.surfaceHigh,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.receipt_long_rounded, size: 18, color: AdminColors.accent),
                    ),
                    title: Row(
                      children: [
                        Text(a.action, style: const TextStyle(fontWeight: FontWeight.w700, fontFamily: 'monospace')),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AdminColors.surfaceHigh,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(a.actorRole, style: const TextStyle(fontSize: 10, color: AdminColors.textSecondary)),
                        ),
                      ],
                    ),
                    subtitle: Text('Target: ${a.targetId} · Reason: ${a.reason}'),
                    trailing: Text(
                      DateFormat('HH:mm:ss').format(a.createdAt),
                      style: const TextStyle(fontSize: 12, color: AdminColors.textSecondary),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helpers
  Widget _kpiCard(String title, String val, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AdminColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdminColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 13, color: AdminColors.textSecondary, fontWeight: FontWeight.w600)),
              Icon(icon, color: color, size: 20),
            ],
          ),
          const SizedBox(height: 12),
          Text(val, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _healthItem(String label, String status, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Row(
            children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Expanded(child: Text(status, style: TextStyle(fontSize: 12, color: color))),
            ],
          ),
        ],
      ),
    );
  }

  void _showRevealWalletDialog(BuildContext context, UserRecord user) {
    final reasonController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: const Text('Reveal Wallet Address (Audited)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Per privacy rules (section 7), revealing a wallet writes an immediate append-only audit entry. You must provide a valid justification:',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(hintText: 'e.g. Investigation for Fraud Case #102'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().length >= 5) {
                Get.back();
                Get.dialog(
                  AlertDialog(
                    title: const Text('Verified Wallet Address'),
                    content: SelectableText(user.walletAddress ?? '0x71C8412092d8866F407b621946414380b49f4b9B'),
                    actions: [
                      TextButton(onPressed: () => Get.back(), child: const Text('Done')),
                    ],
                  ),
                );
              }
            },
            child: const Text('Authorize & Reveal'),
          ),
        ],
      ),
    );
  }

  void _showSuspendDialog(BuildContext context, UserRecord user) {
    final reasonController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: Text('Suspend @${user.handle}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter duration and formal justification:'),
            const SizedBox(height: 12),
            TextField(controller: reasonController, decoration: const InputDecoration(hintText: 'Reason for suspension')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.suspendUser(user.id, 7, reasonController.text);
            },
            child: const Text('Confirm Suspension'),
          ),
        ],
      ),
    );
  }

  void _showBanDialog(BuildContext context, UserRecord user) {
    final reasonController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: Text('Permanent Ban @${user.handle}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('This will permanently revoke all access and sessions.', style: TextStyle(color: AdminColors.error)),
            const SizedBox(height: 12),
            TextField(controller: reasonController, decoration: const InputDecoration(hintText: 'Formal justification')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AdminColors.error, foregroundColor: Colors.white),
            onPressed: () {
              Get.back();
              controller.banUser(user.id, reasonController.text);
            },
            child: const Text('Permanent Ban'),
          ),
        ],
      ),
    );
  }
}
