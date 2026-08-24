import 'package:flutter/material.dart';
import 'sales_requests.dart';
import 'app_core.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  @override
  void initState() {
    super.initState();
    // Opening the list is treated as "seen" — clears the badge count.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SalesRequests.markAllNotificationsRead();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLanguage>(
      valueListenable: AppLocale.languageNotifier,
      builder: (context, _, __) => ValueListenableBuilder<List<ManagerNotification>>(
        valueListenable: SalesRequests.notificationsNotifier,
        builder: (context, notifications, __) {
          return Scaffold(
            backgroundColor: bgGray,
            appBar: AppBar(
              backgroundColor: navy,
              elevation: 0,
              title: Text(tr("Notifications"), style: const TextStyle(color: Colors.white)),
              iconTheme: const IconThemeData(color: Colors.white),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
              ),
            ),
            body: SafeArea(
              child: notifications.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.notifications_none, size: 48, color: Colors.black26),
                          const SizedBox(height: 12),
                          Text(tr("No notifications yet"), style: const TextStyle(color: Colors.black45)),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: notifications.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) => _notificationCard(notifications[index]),
                    ),
            ),
          );
        },
      ),
    );
  }

  Widget _notificationCard(ManagerNotification n) {
    final isUrgent = n.subtitle.contains("Urgent");
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (isUrgent ? Colors.red : navy).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              n.kind == NotificationKind.engineerAction ? Icons.engineering_outlined : Icons.support_agent_outlined,
              color: isUrgent ? Colors.red : navy,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(n.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 3),
                Text(n.subtitle, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                const SizedBox(height: 4),
                Text(_relativeTime(n.createdAt), style: const TextStyle(fontSize: 11, color: Colors.black38)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _relativeTime(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 1) return tr("Just now");
    if (diff.inMinutes < 60) return "${diff.inMinutes} ${tr("min ago")}";
    if (diff.inHours < 24) return "${diff.inHours} ${tr("hr ago")}";
    return "${diff.inDays} ${tr("days ago")}";
  }
}
