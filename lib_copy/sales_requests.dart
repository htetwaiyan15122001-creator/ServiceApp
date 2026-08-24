import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'app_core.dart';

const List<String> referralSources = ["Facebook", "LINE", "Advertisement"];

const String _newProjectsPrefKey = 'sales_new_projects';
const String _engineerRequestsPrefKey = 'sales_engineer_requests';
const String _afterSaleRequestsPrefKey = 'sales_after_sale_requests';
const String _notificationsPrefKey = 'manager_notifications';

/// Submitted via the "New Project Information" form.
class NewProjectInfo {
  final String id;
  String customerName;
  String companyName;
  String contactPerson;
  String contactNumber; // includes +66 prefix
  String? lineId;
  DateTime receivedDate;
  String referralSource;
  String submittedBy;
  DateTime submittedAt;

  NewProjectInfo({
    required this.id,
    required this.customerName,
    required this.companyName,
    required this.contactPerson,
    required this.contactNumber,
    this.lineId,
    required this.receivedDate,
    required this.referralSource,
    required this.submittedBy,
    required this.submittedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'customerName': customerName,
        'companyName': companyName,
        'contactPerson': contactPerson,
        'contactNumber': contactNumber,
        'lineId': lineId,
        'receivedDate': receivedDate.toIso8601String(),
        'referralSource': referralSource,
        'submittedBy': submittedBy,
        'submittedAt': submittedAt.toIso8601String(),
      };

  factory NewProjectInfo.fromJson(Map<String, dynamic> json) => NewProjectInfo(
        id: json['id'] as String,
        customerName: json['customerName'] as String,
        companyName: json['companyName'] as String,
        contactPerson: json['contactPerson'] as String,
        contactNumber: json['contactNumber'] as String,
        lineId: json['lineId'] as String?,
        receivedDate: DateTime.parse(json['receivedDate'] as String),
        referralSource: json['referralSource'] as String,
        submittedBy: json['submittedBy'] as String,
        submittedAt: DateTime.parse(json['submittedAt'] as String),
      );
}

/// Submitted via "Engineer Action Request" — tied to an existing project
/// (HistoryJob), asking an engineer to do something on it.
class EngineerActionRequest {
  final String id;
  final String projectId;
  final String projectName;
  // Snapshot of customer/project info at submission time (read-only in the
  // form — pulled from the linked HistoryJob so Sales can't edit it).
  final String? customerName;
  final String? companyName;
  final String? contactPerson;
  final String? phoneNumber;
  final String? lineId;
  final String? projectType;
  final String? location;
  String products;
  String description;
  String priority; // "Normal" or "Urgent"
  String submittedBy;
  DateTime submittedAt;
  bool handled;

  EngineerActionRequest({
    required this.id,
    required this.projectId,
    required this.projectName,
    this.customerName,
    this.companyName,
    this.contactPerson,
    this.phoneNumber,
    this.lineId,
    this.projectType,
    this.location,
    required this.products,
    required this.description,
    this.priority = "Normal",
    required this.submittedBy,
    required this.submittedAt,
    this.handled = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'projectId': projectId,
        'projectName': projectName,
        'customerName': customerName,
        'companyName': companyName,
        'contactPerson': contactPerson,
        'phoneNumber': phoneNumber,
        'lineId': lineId,
        'projectType': projectType,
        'location': location,
        'products': products,
        'description': description,
        'priority': priority,
        'submittedBy': submittedBy,
        'submittedAt': submittedAt.toIso8601String(),
        'handled': handled,
      };

  factory EngineerActionRequest.fromJson(Map<String, dynamic> json) => EngineerActionRequest(
        id: json['id'] as String,
        projectId: json['projectId'] as String,
        projectName: json['projectName'] as String,
        customerName: json['customerName'] as String?,
        companyName: json['companyName'] as String?,
        contactPerson: json['contactPerson'] as String?,
        phoneNumber: json['phoneNumber'] as String?,
        lineId: json['lineId'] as String?,
        projectType: json['projectType'] as String?,
        location: json['location'] as String?,
        products: json['products'] as String,
        description: json['description'] as String,
        priority: json['priority'] as String? ?? "Normal",
        submittedBy: json['submittedBy'] as String,
        submittedAt: DateTime.parse(json['submittedAt'] as String),
        handled: json['handled'] as bool? ?? false,
      );
}

/// Submitted via "After Sale Service Request" — a fresh customer service
/// request, not necessarily tied to an existing project.
class AfterSaleServiceRequest {
  final String id;
  String customerName;
  String contactNumber;
  String? lineUsername;
  String referralSource;
  String companyName;
  String contactPerson;
  String issueCategory; // Repair / Warranty claim / Complaint / General inquiry
  String description;
  String submittedBy;
  DateTime submittedAt;
  bool handled;

  AfterSaleServiceRequest({
    required this.id,
    required this.customerName,
    required this.contactNumber,
    this.lineUsername,
    required this.referralSource,
    required this.companyName,
    required this.contactPerson,
    required this.issueCategory,
    required this.description,
    required this.submittedBy,
    required this.submittedAt,
    this.handled = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'customerName': customerName,
        'contactNumber': contactNumber,
        'lineUsername': lineUsername,
        'referralSource': referralSource,
        'companyName': companyName,
        'contactPerson': contactPerson,
        'issueCategory': issueCategory,
        'description': description,
        'submittedBy': submittedBy,
        'submittedAt': submittedAt.toIso8601String(),
        'handled': handled,
      };

  factory AfterSaleServiceRequest.fromJson(Map<String, dynamic> json) => AfterSaleServiceRequest(
        id: json['id'] as String,
        customerName: json['customerName'] as String,
        contactNumber: json['contactNumber'] as String,
        lineUsername: json['lineUsername'] as String?,
        referralSource: json['referralSource'] as String,
        companyName: json['companyName'] as String,
        contactPerson: json['contactPerson'] as String,
        issueCategory: json['issueCategory'] as String,
        description: json['description'] as String,
        submittedBy: json['submittedBy'] as String,
        submittedAt: DateTime.parse(json['submittedAt'] as String),
        handled: json['handled'] as bool? ?? false,
      );
}

const List<String> issueCategories = ["Repair", "Warranty claim", "Complaint", "General inquiry"];

enum NotificationKind { engineerAction, afterSaleService }

/// A single item in the Manager's notification list — created whenever
/// Sales submits an Engineer Action Request or After Sale Service Request.
class ManagerNotification {
  final String id;
  final NotificationKind kind;
  final String title;
  final String subtitle;
  final String relatedRequestId;
  final DateTime createdAt;
  bool read;

  ManagerNotification({
    required this.id,
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.relatedRequestId,
    required this.createdAt,
    this.read = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind.name,
        'title': title,
        'subtitle': subtitle,
        'relatedRequestId': relatedRequestId,
        'createdAt': createdAt.toIso8601String(),
        'read': read,
      };

  factory ManagerNotification.fromJson(Map<String, dynamic> json) => ManagerNotification(
        id: json['id'] as String,
        kind: NotificationKind.values.firstWhere((k) => k.name == json['kind'], orElse: () => NotificationKind.engineerAction),
        title: json['title'] as String,
        subtitle: json['subtitle'] as String,
        relatedRequestId: json['relatedRequestId'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        read: json['read'] as bool? ?? false,
      );
}

/// Central store for all three Sales request types plus the Manager's
/// notification list. Mirrors the ValueNotifier + SharedPreferences pattern
/// already used by JobHistoryPage, AppLocale, and AppSession.
class SalesRequests {
  SalesRequests._();

  static final ValueNotifier<List<NewProjectInfo>> newProjectsNotifier = ValueNotifier([]);
  static final ValueNotifier<List<EngineerActionRequest>> engineerRequestsNotifier = ValueNotifier([]);
  static final ValueNotifier<List<AfterSaleServiceRequest>> afterSaleRequestsNotifier = ValueNotifier([]);
  static final ValueNotifier<List<ManagerNotification>> notificationsNotifier = ValueNotifier([]);

  static int get unreadCount => notificationsNotifier.value.where((n) => !n.read).length;

  static String _newId() => DateTime.now().microsecondsSinceEpoch.toString();

  static void submitNewProject({
    required String customerName,
    required String companyName,
    required String contactPerson,
    required String contactNumber,
    String? lineId,
    required DateTime receivedDate,
    required String referralSource,
  }) {
    final entry = NewProjectInfo(
      id: _newId(),
      customerName: customerName,
      companyName: companyName,
      contactPerson: contactPerson,
      contactNumber: contactNumber,
      lineId: lineId,
      receivedDate: receivedDate,
      referralSource: referralSource,
      submittedBy: AppSession.currentName,
      submittedAt: DateTime.now(),
    );
    newProjectsNotifier.value = [entry, ...newProjectsNotifier.value];
    _persistNewProjects();
    // New Project Information doesn't notify the Manager — only Engineer
    // Action Request and After Sale Service Request do (per spec).
  }

  static void submitEngineerActionRequest({
    required String projectId,
    required String projectName,
    String? customerName,
    String? companyName,
    String? contactPerson,
    String? phoneNumber,
    String? lineId,
    String? projectType,
    String? location,
    required String products,
    required String description,
    required String priority,
  }) {
    final entry = EngineerActionRequest(
      id: _newId(),
      projectId: projectId,
      projectName: projectName,
      customerName: customerName,
      companyName: companyName,
      contactPerson: contactPerson,
      phoneNumber: phoneNumber,
      lineId: lineId,
      projectType: projectType,
      location: location,
      products: products,
      description: description,
      priority: priority,
      submittedBy: AppSession.currentName,
      submittedAt: DateTime.now(),
    );
    engineerRequestsNotifier.value = [entry, ...engineerRequestsNotifier.value];
    _persistEngineerRequests();
    _notifyManager(
      kind: NotificationKind.engineerAction,
      title: "Engineer action requested — $projectName",
      subtitle: "${AppSession.currentName} · $priority priority",
      relatedRequestId: entry.id,
    );
  }

  static void submitAfterSaleServiceRequest({
    required String customerName,
    required String contactNumber,
    String? lineUsername,
    required String referralSource,
    required String companyName,
    required String contactPerson,
    required String issueCategory,
    required String description,
  }) {
    final entry = AfterSaleServiceRequest(
      id: _newId(),
      customerName: customerName,
      contactNumber: contactNumber,
      lineUsername: lineUsername,
      referralSource: referralSource,
      companyName: companyName,
      contactPerson: contactPerson,
      issueCategory: issueCategory,
      description: description,
      submittedBy: AppSession.currentName,
      submittedAt: DateTime.now(),
    );
    afterSaleRequestsNotifier.value = [entry, ...afterSaleRequestsNotifier.value];
    _persistAfterSaleRequests();
    _notifyManager(
      kind: NotificationKind.afterSaleService,
      title: "After sale service request — $customerName",
      subtitle: "${AppSession.currentName} · $issueCategory",
      relatedRequestId: entry.id,
    );
  }

  static void _notifyManager({
    required NotificationKind kind,
    required String title,
    required String subtitle,
    required String relatedRequestId,
  }) {
    final notification = ManagerNotification(
      id: _newId(),
      kind: kind,
      title: title,
      subtitle: subtitle,
      relatedRequestId: relatedRequestId,
      createdAt: DateTime.now(),
    );
    notificationsNotifier.value = [notification, ...notificationsNotifier.value];
    _persistNotifications();
  }

  static void markNotificationRead(String id) {
    for (final n in notificationsNotifier.value) {
      if (n.id == id) {
        n.read = true;
        break;
      }
    }
    notificationsNotifier.value = [...notificationsNotifier.value];
    _persistNotifications();
  }

  static void markAllNotificationsRead() {
    for (final n in notificationsNotifier.value) {
      n.read = true;
    }
    notificationsNotifier.value = [...notificationsNotifier.value];
    _persistNotifications();
  }

  static void markEngineerRequestHandled(String id) {
    for (final r in engineerRequestsNotifier.value) {
      if (r.id == id) {
        r.handled = true;
        break;
      }
    }
    engineerRequestsNotifier.value = [...engineerRequestsNotifier.value];
    _persistEngineerRequests();
  }

  static void markAfterSaleRequestHandled(String id) {
    for (final r in afterSaleRequestsNotifier.value) {
      if (r.id == id) {
        r.handled = true;
        break;
      }
    }
    afterSaleRequestsNotifier.value = [...afterSaleRequestsNotifier.value];
    _persistAfterSaleRequests();
  }

  static void _persistNewProjects() {
    AppStorage.prefs.setString(
      _newProjectsPrefKey,
      jsonEncode(newProjectsNotifier.value.map((e) => e.toJson()).toList()),
    );
  }

  static void _persistEngineerRequests() {
    AppStorage.prefs.setString(
      _engineerRequestsPrefKey,
      jsonEncode(engineerRequestsNotifier.value.map((e) => e.toJson()).toList()),
    );
  }

  static void _persistAfterSaleRequests() {
    AppStorage.prefs.setString(
      _afterSaleRequestsPrefKey,
      jsonEncode(afterSaleRequestsNotifier.value.map((e) => e.toJson()).toList()),
    );
  }

  static void _persistNotifications() {
    AppStorage.prefs.setString(
      _notificationsPrefKey,
      jsonEncode(notificationsNotifier.value.map((e) => e.toJson()).toList()),
    );
  }

  /// Restores everything from disk. Call once at startup, after AppStorage.init().
  static void loadSaved() {
    final newProjectsRaw = AppStorage.prefs.getString(_newProjectsPrefKey);
    if (newProjectsRaw != null) {
      final list = jsonDecode(newProjectsRaw) as List;
      newProjectsNotifier.value = list.map((e) => NewProjectInfo.fromJson(e as Map<String, dynamic>)).toList();
    }
    final engineerRaw = AppStorage.prefs.getString(_engineerRequestsPrefKey);
    if (engineerRaw != null) {
      final list = jsonDecode(engineerRaw) as List;
      engineerRequestsNotifier.value = list.map((e) => EngineerActionRequest.fromJson(e as Map<String, dynamic>)).toList();
    }
    final afterSaleRaw = AppStorage.prefs.getString(_afterSaleRequestsPrefKey);
    if (afterSaleRaw != null) {
      final list = jsonDecode(afterSaleRaw) as List;
      afterSaleRequestsNotifier.value = list.map((e) => AfterSaleServiceRequest.fromJson(e as Map<String, dynamic>)).toList();
    }
    final notificationsRaw = AppStorage.prefs.getString(_notificationsPrefKey);
    if (notificationsRaw != null) {
      final list = jsonDecode(notificationsRaw) as List;
      notificationsNotifier.value = list.map((e) => ManagerNotification.fromJson(e as Map<String, dynamic>)).toList();
    }
  }
}
