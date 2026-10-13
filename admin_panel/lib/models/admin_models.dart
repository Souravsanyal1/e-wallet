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
    this.totalUsers = 0,
    this.openReports = 0,
    this.totalPayments = 0,
    this.activeSubscriptions = 0,
    this.serverHealth = 'Healthy',
    this.uptimePercent = '100%',
  });

  factory DashboardMetrics.fromMap(Map<String, dynamic> data) {
    return DashboardMetrics(
      totalUsers: (data['totalUsers'] as num?)?.toInt() ?? 0,
      openReports: (data['openReports'] as num?)?.toInt() ?? 0,
      totalPayments: (data['totalPayments'] as num?)?.toInt() ?? 0,
      activeSubscriptions: (data['activeSubscriptions'] as num?)?.toInt() ?? 0,
      serverHealth: data['serverHealth'] as String? ?? 'Healthy',
      uptimePercent: data['uptimePercent'] as String? ?? '100%',
    );
  }
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

  factory UserRecord.fromDoc(String docId, Map<String, dynamic> data) {
    DateTime parseDate(dynamic val) {
      if (val == null) return DateTime.now();
      if (val is DateTime) return val;
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      try {
        final toDate = (val as dynamic).toDate();
        if (toDate is DateTime) return toDate;
      } catch (_) {}
      return DateTime.now();
    }

    return UserRecord(
      id: docId,
      handle: data['handle'] as String? ?? 'user',
      displayName: data['displayName'] as String? ?? 'User',
      status: data['status'] as String? ?? 'active',
      walletAddress: data['walletAddress'] as String?,
      createdAt: parseDate(data['createdAt']),
    );
  }
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

  factory ModerationCase.fromDoc(String docId, Map<String, dynamic> data) {
    DateTime parseDate(dynamic val) {
      if (val == null) return DateTime.now();
      if (val is DateTime) return val;
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      try {
        final toDate = (val as dynamic).toDate();
        if (toDate is DateTime) return toDate;
      } catch (_) {}
      return DateTime.now();
    }

    return ModerationCase(
      id: docId,
      reporterId: data['reporterId'] as String? ?? '',
      targetUserId: data['targetUserId'] as String? ?? '',
      reason: data['reason'] as String? ?? 'No reason specified',
      status: data['status'] as String? ?? 'open',
      createdAt: parseDate(data['createdAt']),
    );
  }
}

class PaymentItem {
  final String id;
  final String userId;
  final String txHash;
  final String amount;
  final int tokenDecimals;
  final String tokenSymbol;
  final String status;
  final DateTime createdAt;

  PaymentItem({
    required this.id,
    required this.userId,
    required this.txHash,
    required this.amount,
    required this.tokenDecimals,
    required this.tokenSymbol,
    required this.status,
    required this.createdAt,
  });

  factory PaymentItem.fromDoc(String docId, Map<String, dynamic> data) {
    DateTime parseDate(dynamic val) {
      if (val == null) return DateTime.now();
      if (val is DateTime) return val;
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      try {
        final toDate = (val as dynamic).toDate();
        if (toDate is DateTime) return toDate;
      } catch (_) {}
      return DateTime.now();
    }

    return PaymentItem(
      id: docId,
      userId: data['userId'] as String? ?? '',
      txHash: data['txHash'] as String? ?? '',
      amount: data['amount']?.toString() ?? '0',
      tokenDecimals: data['tokenDecimals'] as int? ?? 0,
      tokenSymbol: data['tokenSymbol'] as String? ?? 'E-FORCE',
      status: data['status'] as String? ?? 'confirmed',
      createdAt: parseDate(data['createdAt']),
    );
  }

  String get displayAmount {
    final raw = BigInt.tryParse(amount) ?? BigInt.zero;
    if (tokenDecimals <= 0) return raw.toString();
    final scale = BigInt.from(10).pow(tokenDecimals);
    final whole = raw ~/ scale;
    final fraction = (raw % scale).toString().padLeft(tokenDecimals, '0').replaceFirst(RegExp(r'0+$'), '');
    return fraction.isEmpty ? whole.toString() : '$whole.$fraction';
  }
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

  factory AuditEntry.fromDoc(String docId, Map<String, dynamic> data) {
    DateTime parseDate(dynamic val) {
      if (val == null) return DateTime.now();
      if (val is DateTime) return val;
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      try {
        final toDate = (val as dynamic).toDate();
        if (toDate is DateTime) return toDate;
      } catch (_) {}
      return DateTime.now();
    }

    return AuditEntry(
      id: docId,
      actorRole: data['actorRole'] as String? ?? 'admin',
      action: data['action'] as String? ?? 'unknown',
      targetType: data['targetType'] as String? ?? '',
      targetId: data['targetId'] as String? ?? '',
      reason: data['reason'] as String? ?? '',
      createdAt: parseDate(data['createdAt']),
    );
  }
}
