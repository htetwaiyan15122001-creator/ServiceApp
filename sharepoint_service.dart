import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'app_core.dart';

class SharePointService {
  // Point these at your deployed backend from the servicepro-sharepoint-backend
  // project (see its README) — e.g. "https://servicepro-backend.onrender.com".
  // TODO: swap this for your real deployed backend URL once hosting is set
  // up. For now, this points at localhost — works when testing on Chrome/web
  // on the SAME PC that's running `node server.js`. This will NOT work on a
  // real phone or Android emulator (they can't reach your PC's localhost) —
  // update this once the backend is deployed to Azure App Service.
  static const String backendBaseUrl = "http://localhost:3000";

  static String get webhookUrl => "$backendBaseUrl/upload-report";
  static String get sendSignatureLinkUrl => "$backendBaseUrl/send-signature-link";
  static String get sendSignatureLinkLineUrl => "$backendBaseUrl/send-signature-link-line";
  static String get registerLineCustomerUrl => "$backendBaseUrl/line/register-customer";
  static String get lineCustomersUrl => "$backendBaseUrl/line/customers";
  static String get checkSignatureStatusUrl => "$backendBaseUrl/signature-status";
  static String get receiveSignatureUrl => "$backendBaseUrl/receive-signature";
  static String get userRoleUrl => "$backendBaseUrl/user-role";

  /// Uploads a signature collected via [CollectSignaturePage] (in-app,
  /// on-site) straight to the backend's public /receive-signature endpoint
  /// — the same one sign.html posts to for remote signing.
  static Future<SharePointResult> uploadCollectedSignature({
    required String jobId,
    required String signatureBase64,
  }) async {
    if (!isConfigured) {
      return SharePointResult(success: false, message: "Backend not configured");
    }
    try {
      final response = await http
          .post(
            Uri.parse(receiveSignatureUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'jobId': jobId,
              'signatureBase64': signatureBase64,
              'signedAt': DateTime.now().toIso8601String(),
            }),
          )
          .timeout(const Duration(seconds: 120));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return SharePointResult(success: true, message: 'Signature uploaded');
      }
      return SharePointResult(success: false, message: 'Signature upload failed');
    } catch (e) {
      return SharePointResult(success: false, message: 'Signature upload failed: $e');
    }
  }


  // Must match API_KEY in the backend's .env file.
  static const String apiKey = "sp_test123makeThisAnythingYouWant";

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'x-api-key': apiKey,
        // Bypasses ngrok's free-tier "confirm you're human" HTML page, which
        // otherwise gets returned instead of real JSON on first contact from
        // a new device — remove this once you're on a real hosted URL.
        'ngrok-skip-browser-warning': 'true',
      };

  static bool get isConfigured => !backendBaseUrl.contains("YOUR-BACKEND-URL");

  static bool get isSignatureLinkConfigured => isConfigured;

  /// Emails the customer a link to sign_html so they can sign remotely
  /// when they weren't on-site at the time the report was submitted.
  static Future<SharePointResult> sendSignatureLink({
    required String jobId,
    required String jobTitle,
    required String customerEmail,
  }) async {
    if (!isSignatureLinkConfigured) {
      return SharePointResult(
        success: false,
        message: "${tr("Signature-link backend not configured yet. ")}"
            "${tr("Set backendBaseUrl / apiKey in sharepoint_service.dart.")}",
      );
    }

    try {
      final response = await http
          .post(
            Uri.parse(sendSignatureLinkUrl),
            headers: _headers,
            body: jsonEncode({
              'jobId': jobId,
              'jobTitle': jobTitle,
              'customerEmail': customerEmail,
            }),
          )
          .timeout(const Duration(seconds: 120));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return SharePointResult(success: true, message: tr("Signing link emailed to customer"));
      }
      return SharePointResult(
        success: false,
        message: "Failed to send signing link (${response.statusCode})",
      );
    } catch (e) {
      return SharePointResult(success: false, message: "Failed to send signing link: $e");
    }
  }

  /// Sends the customer a LINE message with a "Sign Now" button (link
  /// hidden behind the button, not shown as raw text) so they can sign
  /// remotely when they weren't on-site. [customerName] must match a row
  /// already saved via [registerLineCustomer] that the customer has linked
  /// (scanned the QR / tapped the pre-filled message) — see [fetchLineCustomers].
  static Future<SharePointResult> sendSignatureLinkLine({
    required String jobId,
    required String jobTitle,
    required String customerName,
  }) async {
    if (!isSignatureLinkConfigured) {
      return SharePointResult(
        success: false,
        message: "${tr("Signature-link backend not configured yet. ")}"
            "${tr("Set backendBaseUrl / apiKey in sharepoint_service.dart.")}",
      );
    }

    try {
      final response = await http
          .post(
            Uri.parse(sendSignatureLinkLineUrl),
            headers: _headers,
            body: jsonEncode({
              'jobId': jobId,
              'jobTitle': jobTitle,
              'customerName': customerName,
            }),
          )
          .timeout(const Duration(seconds: 120));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return SharePointResult(success: true, message: tr("Signing link sent via LINE"));
      }
      if (response.statusCode == 409) {
        return SharePointResult(
          success: false,
          message: tr("This customer hasn't linked their LINE account yet."),
        );
      }
      return SharePointResult(
        success: false,
        message: "Failed to send LINE signing link (${response.statusCode})",
      );
    } catch (e) {
      return SharePointResult(success: false, message: "Failed to send LINE signing link: $e");
    }
  }

  /// Registers a new customer name and generates a linking code + QR-ready
  /// deep link. Show the returned [LineRegisterResult.qrLink] as a QR code
  /// for the customer to scan — scanning it opens a chat with the LINE OA
  /// with the code already typed in, so they just tap send once.
  static Future<LineRegisterResult> registerLineCustomer(String customerName) async {
    if (!isSignatureLinkConfigured) {
      return LineRegisterResult(error: "Backend not configured (backendBaseUrl placeholder).");
    }
    try {
      final response = await http
          .post(
            Uri.parse(registerLineCustomerUrl),
            headers: _headers,
            body: jsonEncode({'customerName': customerName}),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        return LineRegisterResult(
          code: data['code'] as String,
          qrLink: data['qrLink'] as String,
        );
      }

      // Reached the server fine, but it returned an error — surface exactly
      // what it said instead of a generic "couldn't reach" message.
      String serverMessage;
      try {
        final data = jsonDecode(response.body);
        serverMessage = data['error'] as String? ?? response.body;
      } catch (_) {
        serverMessage = response.body;
      }
      return LineRegisterResult(error: "Server error (${response.statusCode}): $serverMessage");
    } on TimeoutException {
      return LineRegisterResult(error: "Request timed out — backend not responding.");
    } catch (e) {
      return LineRegisterResult(error: "Couldn't reach the backend: $e");
    }
  }

  /// Fetches every saved LINE customer (name + whether they've completed
  /// linking yet) for the "select customer" dropdown.
  static Future<List<LineCustomer>> fetchLineCustomers() async {
    if (!isSignatureLinkConfigured) return [];
    try {
      final response = await http.get(Uri.parse(lineCustomersUrl), headers: _headers).timeout(
            const Duration(seconds: 30),
          );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        final list = (data['customers'] as List?) ?? [];
        return list
            .map((e) => LineCustomer(
                  customerName: e['customerName'] as String? ?? '',
                  code: e['code'] as String? ?? '',
                  linked: e['linked'] as bool? ?? false,
                ))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Checks whether the customer has completed the remote signature yet.
  /// Returns the signature's base64 PNG if signed, or null if not yet.
  static Future<String?> checkSignatureStatus(String jobId) async {
    if (!isSignatureLinkConfigured) return null;

    try {
      final response = await http
          .post(
            Uri.parse(checkSignatureStatusUrl),
            headers: _headers,
            body: jsonEncode({'jobId': jobId}),
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        if (data is Map && data['signed'] == true) {
          return data['signatureBase64'] as String?;
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Uploads a completed service report. Returns true on success.
  static Future<SharePointResult> uploadServiceReport({
    required String? jobId,
    required List<String> photoBase64List,
    required List<String> photoFileNames,
    required String? signatureBase64,
    // Add the missing named parameters here:
    required String? serviceBy,
    required String? serviceByEmail,
    required String? remarks,
    required String? callToAction,
    required String? authorizedBy,
    String? jobType,
    bool customerNotOnSite = false,
  }) async {
    if (!isConfigured) {
      return SharePointResult(
        success: false,
        message: "${tr("SharePoint backend not configured yet. ")}"
            "${tr("Set SharePointService.backendBaseUrl / apiKey in sharepoint_service.dart.")}",
      );
    }

    // Build a list of {fileName, base64} pairs for every photo.
    final photos = List.generate(
      photoBase64List.length,
      (i) => {
        'fileName': i < photoFileNames.length ? photoFileNames[i] : 'photo_$i.jpg',
        'base64': photoBase64List[i],
      },
    );

    try {
      final response = await http
          .post(
            Uri.parse(webhookUrl),
            headers: _headers,
            body: jsonEncode({
              'jobId': jobId,
              // Full list of photos — matches uploadReport.js on the backend.
              'photos': photos,
              // Kept for backward compatibility with a backend built for a single photo.
              'photoFileName': photoFileNames.isNotEmpty ? photoFileNames.first : null,
              'photoBase64': photoBase64List.isNotEmpty ? photoBase64List.first : null,
              'signatureBase64': signatureBase64,
              'serviceBy': serviceBy,
              'serviceByEmail': serviceByEmail,
              'remarks': remarks,
              'callToAction': callToAction,
              'authorizedBy': authorizedBy,
              'jobType': jobType,
              'customerNotOnSite': customerNotOnSite,
              'submittedAt': DateTime.now().toIso8601String(),
            }),
          )
          .timeout(const Duration(seconds: 120));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return SharePointResult(success: true, message: tr("Uploaded to SharePoint"));
      }
      return SharePointResult(
        success: false,
        message: "SharePoint responded with ${response.statusCode}: ${response.body}",
      );
    } catch (e) {
      return SharePointResult(success: false, message: "Upload failed: $e");
    }
  }
  /// Looks up which role a work email is assigned in a SharePoint list an
  /// admin maintains — the app doesn't let someone pick their own role at
  /// login, it's decided entirely by that list. Also doubles as the login
  /// gate: an email not found there returns an error.
  static Future<UserRoleResult> fetchUserRole(String email) async {
    if (!isConfigured) {
      return UserRoleResult(error: "Backend not configured (backendBaseUrl placeholder).");
    }
    try {
      final response = await http
          .post(
            Uri.parse(userRoleUrl),
            headers: _headers,
            body: jsonEncode({'email': email}),
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        return UserRoleResult(
          role: data['role'] as String,
          name: (data['name'] as String?)?.trim().isNotEmpty == true ? data['name'] as String : null,
        );
      }

      String serverMessage;
      try {
        final data = jsonDecode(response.body);
        serverMessage = data['error'] as String? ?? response.body;
      } catch (_) {
        serverMessage = response.body;
      }
      return UserRoleResult(error: serverMessage);
    } on TimeoutException {
      return UserRoleResult(error: "Request timed out — backend not responding.");
    } catch (e) {
      return UserRoleResult(error: "Couldn't reach the backend: $e");
    }
  }
}

class SharePointResult {
  final bool success;
  final String message;
  SharePointResult({required this.success, required this.message});
}

/// Returned by [SharePointService.registerLineCustomer]. Either [error] is
/// set (something went wrong — show it to the user), or [code]/[qrLink] are.
class LineRegisterResult {
  final String? code;
  final String? qrLink;
  final String? error;
  LineRegisterResult({this.code, this.qrLink, this.error});
  bool get success => error == null;
}

/// A saved customer entry from [SharePointService.fetchLineCustomers].
class LineCustomer {
  final String customerName;
  final String code;
  final bool linked;
  LineCustomer({required this.customerName, required this.code, required this.linked});
}

/// Returned by [SharePointService.fetchUserRole]. Either [error] is set —
/// this email isn't in the UserRoles list, or the backend couldn't be
/// reached — or [role]/[name] are.
class UserRoleResult {
  final String? role; // "engineer" | "manager" | "sales"
  final String? name;
  final String? error;
  UserRoleResult({this.role, this.name, this.error});
  bool get success => error == null;
}