class PlatformNotificationModel {
  final int platformNotificationId;
  final int? tenantId;
  final String? businessName;
  final String notificationType;
  final String title;
  final String message;
  final String severity;
  final bool isRead;
  final bool isResolved;
  final DateTime createdOn;

  const PlatformNotificationModel({
    required this.platformNotificationId,
    this.tenantId,
    this.businessName,
    required this.notificationType,
    required this.title,
    required this.message,
    required this.severity,
    required this.isRead,
    required this.isResolved,
    required this.createdOn,
  });

  factory PlatformNotificationModel.fromJson(Map<String, dynamic> j) => PlatformNotificationModel(
        platformNotificationId: j['platformNotificationId'] as int? ?? 0,
        tenantId: j['tenantId'] as int?,
        businessName: j['businessName'] as String?,
        notificationType: j['notificationType'] as String? ?? '',
        title: j['title'] as String? ?? '',
        message: j['message'] as String? ?? '',
        severity: j['severity'] as String? ?? 'INFO',
        isRead: j['isRead'] as bool? ?? false,
        isResolved: j['isResolved'] as bool? ?? false,
        createdOn: DateTime.tryParse(j['createdOn'] as String? ?? '') ?? DateTime.now(),
      );
}

class NotificationSummaryModel {
  final int totalUnread;
  final int critical;
  final int warnings;
  final int info;

  const NotificationSummaryModel({
    required this.totalUnread,
    required this.critical,
    required this.warnings,
    required this.info,
  });

  factory NotificationSummaryModel.fromJson(Map<String, dynamic> j) => NotificationSummaryModel(
        totalUnread: j['totalUnread'] as int? ?? 0,
        critical: j['critical'] as int? ?? 0,
        warnings: j['warnings'] as int? ?? 0,
        info: j['info'] as int? ?? 0,
      );
}
