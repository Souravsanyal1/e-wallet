enum AdminRole { superadmin, admin, moderator, support, analyst }

class AdminProfile {
  final String uid;
  final String email;
  final AdminRole role;
  final bool active;
  final bool mfaEnrolled;

  const AdminProfile({
    required this.uid,
    required this.email,
    required this.role,
    this.active = true,
    this.mfaEnrolled = true,
  });
}

class DashboardMetrics {
  final int totalUsers;
  final int openReports;
  final int totalPayments;
  final int activeSubscriptions;
  final String serverHealth;
  final String uptimePercent;

  const DashboardMetrics({
    this.totalUsers = 1250,
    this.openReports = 4,
    this.totalPayments = 380,
    this.activeSubscriptions = 95,
    this.serverHealth = 'Healthy',
    this.uptimePercent = '99.98%',
  });
}

class UserRecord {
  final String id;
  final String handle;
  final String displayName;
  String status;
  final String? walletAddress;
  final DateTime createdAt;

  UserRecord({
    required this.id,
    required this.handle,
    required this.displayName,
    this.status = 'active',
    this.walletAddress,
    required this.createdAt,
  });
}

class ModerationCase {
  final String id;
  final String reporterId;
  final String targetUserId;
  final String reason;
  String status;
  final DateTime createdAt;

  ModerationCase({
    required this.id,
    required this.reporterId,
    required this.targetUserId,
    required this.reason,
    this.status = 'open',
    required this.createdAt,
  });
}

class PaymentItem {
  final String id;
  final String userId;
  final String txHash;
  final double amount;
  final String status;
  final DateTime createdAt;

  PaymentItem({
    required this.id,
    required this.userId,
    required this.txHash,
    required this.amount,
    required this.status,
    required this.createdAt,
  });
}

class AuditEntry {
  final String id;
  final String actorRole;
  final String action;
  final String targetType;
  final String targetId;
  final String reason;
  final DateTime createdAt;

  AuditEntry({
    required this.id,
    required this.actorRole,
    required this.action,
    required this.targetType,
    required this.targetId,
    required this.reason,
    required this.createdAt,
  });
}
