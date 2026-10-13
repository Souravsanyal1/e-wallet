import 'package:get/get.dart';
import '../models/admin_models.dart';

class AdminController extends GetxController {
  final Rxn<AdminProfile> currentAdmin = Rxn<AdminProfile>();
  final RxInt selectedNavIndex = 0.obs;
  final RxBool isLoading = false.obs;

  bool get isAuthenticated => currentAdmin.value != null;

  // Mock data for immediate standalone operation & testing
  final Rx<DashboardMetrics> metrics = const DashboardMetrics().obs;
  final RxList<UserRecord> users = <UserRecord>[].obs;
  final RxList<ModerationCase> cases = <ModerationCase>[].obs;
  final RxList<PaymentItem> payments = <PaymentItem>[].obs;
  final RxList<AuditEntry> auditLogs = <AuditEntry>[].obs;

  // App Config
  final RxBool maintenanceMode = false.obs;
  final RxString minAppVersion = '1.0.0'.obs;

  @override
  void onInit() {
    super.onInit();
    _seedData();
  }

  void _seedData() {
    users.assignAll([
      UserRecord(
        id: 'u1',
        handle: 'alice_chen',
        displayName: 'Alice Chen',
        walletAddress: '0x71C8412092d8866F407b621946414380b49f4b9B',
        createdAt: DateTime.now().subtract(const Duration(days: 45)),
      ),
      UserRecord(
        id: 'u2',
        handle: 'bob_smith',
        displayName: 'Bob Smith',
        walletAddress: '0x32Be343B94f860124dC4fEe278FDCBD38C102D88',
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
      ),
      UserRecord(
        id: 'u3',
        handle: 'spammer_bot',
        displayName: 'Airdrop Claim',
        status: 'suspended',
        walletAddress: '0x95222290DD7278Aa3Ddd389Cc1E1d165CC4BAfe5',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
    ]);

    cases.assignAll([
      ModerationCase(
        id: 'case_101',
        reporterId: 'u1',
        targetUserId: 'u3',
        reason: 'Unsolicited phishing link sent in direct chat message.',
        status: 'open',
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      ),
      ModerationCase(
        id: 'case_102',
        reporterId: 'u2',
        targetUserId: 'u3',
        reason: 'Spamming referral codes repeatedly.',
        status: 'in_review',
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      ),
    ]);

    payments.assignAll([
      PaymentItem(
        id: 'pay_1',
        userId: 'u1',
        txHash: '0x4b78c9d012...89a1',
        amount: 50.0,
        status: 'confirmed',
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      ),
      PaymentItem(
        id: 'pay_2',
        userId: 'u2',
        txHash: '0x88f219b45e...33bc',
        amount: 150.0,
        status: 'confirmed',
        createdAt: DateTime.now().subtract(const Duration(hours: 8)),
      ),
    ]);

    auditLogs.assignAll([
      AuditEntry(
        id: 'aud_1',
        actorRole: 'moderator',
        action: 'user.suspend',
        targetType: 'user',
        targetId: 'u3',
        reason: 'Spamming links in DM',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      AuditEntry(
        id: 'aud_2',
        actorRole: 'admin',
        action: 'plan.upsert',
        targetType: 'plan',
        targetId: 'plan_pro',
        reason: 'Updated duration parameters',
        createdAt: DateTime.now().subtract(const Duration(hours: 12)),
      ),
    ]);
  }

  void login(String email, String password, String totpCode) {
    isLoading.value = true;
    Future.delayed(const Duration(milliseconds: 600), () {
      currentAdmin.value = const AdminProfile(
        uid: 'adm_super_01',
        email: 'ops@elitechat.app',
        role: AdminRole.superadmin,
      );
      isLoading.value = false;
    });
  }

  void logout() {
    currentAdmin.value = null;
  }

  void selectTab(int index) {
    selectedNavIndex.value = index;
  }

  void suspendUser(String userId, int days, String reason) {
    final idx = users.indexWhere((u) => u.id == userId);
    if (idx != -1) {
      users[idx].status = 'suspended';
      users.refresh();

      auditLogs.insert(
        0,
        AuditEntry(
          id: 'aud_${DateTime.now().millisecondsSinceEpoch}',
          actorRole: currentAdmin.value?.role.name ?? 'admin',
          action: 'user.suspend',
          targetType: 'user',
          targetId: userId,
          reason: reason,
          createdAt: DateTime.now(),
        ),
      );
      Get.snackbar('Action Complete', 'User suspended for $days days');
    }
  }

  void banUser(String userId, String reason) {
    final idx = users.indexWhere((u) => u.id == userId);
    if (idx != -1) {
      users[idx].status = 'banned';
      users.refresh();

      auditLogs.insert(
        0,
        AuditEntry(
          id: 'aud_${DateTime.now().millisecondsSinceEpoch}',
          actorRole: currentAdmin.value?.role.name ?? 'superadmin',
          action: 'user.ban',
          targetType: 'user',
          targetId: userId,
          reason: reason,
          createdAt: DateTime.now(),
        ),
      );
      Get.snackbar('Action Complete', 'User permanently banned.');
    }
  }

  void resolveCase(String caseId, String resolution, String notes) {
    final idx = cases.indexWhere((c) => c.id == caseId);
    if (idx != -1) {
      cases[idx].status = resolution;
      cases.refresh();

      auditLogs.insert(
        0,
        AuditEntry(
          id: 'aud_${DateTime.now().millisecondsSinceEpoch}',
          actorRole: currentAdmin.value?.role.name ?? 'moderator',
          action: 'case.resolve',
          targetType: 'case',
          targetId: caseId,
          reason: notes,
          createdAt: DateTime.now(),
        ),
      );
      Get.snackbar('Case Updated', 'Status set to $resolution');
    }
  }
}
