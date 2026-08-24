import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// =====================================================================
// Storage
// =====================================================================

/// Tiny wrapper around SharedPreferences.
///
/// [init] is called once in main() before runApp, so every other part of
/// the app (AppLocale, AppSession, JobHistoryPage) can read/write through
/// [prefs] synchronously without every call site needing to be async.
class AppStorage {
  AppStorage._();

  static late SharedPreferences prefs;

  static Future<void> init() async {
    prefs = await SharedPreferences.getInstance();
  }
}

// =====================================================================
// Theme
// =====================================================================

/// Single source of truth for the app's colors.
/// Change a value here and it updates across every screen automatically,
/// since every page imports its colors from this file instead of
/// hardcoding them.

/// Brand / primary color.
const primaryColor = Color(0xFF3183A1);

/// Kept so existing screens (which reference `navy`) don't need to be
/// touched one by one — it just points at the new brand color.
const navy = primaryColor;

/// Page background.
const bgGray = Color(0xFFF5F6F8);

// =====================================================================
// Session
// =====================================================================

/// The three account types in the app.
enum UserRole { engineer, manager, sales }

const String _roleKey = 'session_role';
const String _nameKey = 'session_name';
const String _emailKey = 'session_email';
const String _loggedInKey = 'session_logged_in';

/// Small "session" for who's logged in and what role they have — backed by
/// SharedPreferences, so signing in once keeps you signed in across app
/// restarts until Log Out is tapped.
///
/// In a real app this would be populated from your login API response
/// (name, role, etc. returned alongside the auth token). For now the name
/// is derived from whatever email the user signs in with, and the role
/// comes from the picker on the login screen (or the demo toggle in
/// Profile & Settings).
class AppSession {
  AppSession._();

  static final ValueNotifier<UserRole> roleNotifier =
      ValueNotifier<UserRole>(UserRole.engineer);

  static final ValueNotifier<String> nameNotifier =
      ValueNotifier<String>("Guest");

  static UserRole get currentRole => roleNotifier.value;
  static set currentRole(UserRole role) {
    roleNotifier.value = role;
    AppStorage.prefs.setString(_roleKey, role.name);
  }

  static bool get isManager => currentRole == UserRole.manager;
  static bool get isSales => currentRole == UserRole.sales;

  static String get currentName => nameNotifier.value;
  static set currentName(String name) {
    nameNotifier.value = name;
    AppStorage.prefs.setString(_nameKey, name);
  }

  static String _currentEmail = "";
  static String get currentEmail => _currentEmail;
  static set currentEmail(String email) {
    _currentEmail = email;
    AppStorage.prefs.setString(_emailKey, email);
  }

  static String get roleLabel => switch (currentRole) {
        UserRole.manager => "Engineering Manager",
        UserRole.sales => "Sales Representative",
        UserRole.engineer => "Service Engineer",
      };

  /// Turns an email like "john.smith@company.com" into a display name
  /// like "John.smith". Falls back to "Guest" if nothing usable is given.
  static String deriveNameFromEmail(String email) {
    final trimmed = email.trim();
    if (trimmed.isEmpty) return "Guest";
    final localPart = trimmed.split('@').first;
    if (localPart.isEmpty) return "Guest";
    return localPart[0].toUpperCase() + localPart.substring(1);
  }

  /// A single Listenable that fires when either role or name changes —
  /// handy for widgets that want to react to both with one listener.
  static Listenable get listenable => Listenable.merge([roleNotifier, nameNotifier]);

  /// Whether a previous sign-in is still saved on disk. Checked at startup
  /// so a returning user lands on the Dashboard instead of the Login page.
  static bool get isLoggedIn => AppStorage.prefs.getBool(_loggedInKey) ?? false;

  /// Called after a successful sign-in to persist the session.
  static void markLoggedIn() {
    AppStorage.prefs.setBool(_loggedInKey, true);
  }

  /// Called from Log Out — clears the saved session so the next launch
  /// starts back at the Login page.
  static void logOut() {
    AppStorage.prefs.setBool(_loggedInKey, false);
    currentEmail = "";
  }

  /// Restores the saved role/name/email, if any. Call once at startup,
  /// after AppStorage.init().
  static void loadSaved() {
    final savedRole = AppStorage.prefs.getString(_roleKey);
    if (savedRole == UserRole.manager.name) {
      roleNotifier.value = UserRole.manager;
    } else if (savedRole == UserRole.sales.name) {
      roleNotifier.value = UserRole.sales;
    } else {
      roleNotifier.value = UserRole.engineer;
    }
    nameNotifier.value = AppStorage.prefs.getString(_nameKey) ?? "Guest";
    _currentEmail = AppStorage.prefs.getString(_emailKey) ?? "";
  }
}

// =====================================================================
// Locale
// =====================================================================

/// The two languages the app supports.
enum AppLanguage { en, th }

const String _languagePrefKey = 'app_language';

/// App-wide language switch.
///
/// This mirrors the pattern already used by `AppSession` (a static
/// `ValueNotifier` that any widget can listen to). Toggling the language
/// from the Profile page updates `languageNotifier`, and every screen that
/// wraps its `build()` in a `ValueListenableBuilder<AppLanguage>` (or
/// listens via `AppLocale.listenable`) rebuilds immediately with the new
/// language — no restart needed. The choice is also saved to disk, so it
/// survives the app being closed and reopened.
class AppLocale {
  AppLocale._();

  static final ValueNotifier<AppLanguage> languageNotifier =
      ValueNotifier<AppLanguage>(AppLanguage.en);

  static AppLanguage get current => languageNotifier.value;
  static set current(AppLanguage lang) {
    languageNotifier.value = lang;
    AppStorage.prefs.setString(_languagePrefKey, lang.name);
  }

  static bool get isThai => current == AppLanguage.th;

  static void toggle() {
    current = isThai ? AppLanguage.en : AppLanguage.th;
  }

  static Listenable get listenable => languageNotifier;

  /// Restores the saved language, if any. Call once at startup, after
  /// AppStorage.init().
  static void loadSaved() {
    final saved = AppStorage.prefs.getString(_languagePrefKey);
    if (saved == AppLanguage.th.name) {
      languageNotifier.value = AppLanguage.th;
    } else {
      languageNotifier.value = AppLanguage.en;
    }
  }
}

/// Translate [key] (always written as the English UI copy) into the
/// currently selected language. If a Thai translation hasn't been added
/// yet for some string, this safely falls back to the English original
/// instead of showing a blank label.
String tr(String key) {
  if (AppLocale.current == AppLanguage.en) return key;
  return _th[key] ?? key;
}

/// English text -> Thai translation.
/// Keyed by the exact English copy used in the widgets, so call sites just
/// wrap the existing string literal in `tr(...)` — no separate key naming
/// scheme to maintain.
const Map<String, String> _th = {
  // ---- Bottom nav ----
  "Home": "หน้าหลัก",
  "Projects": "โปรเจกต์",
  "Assign": "มอบหมายงาน",
  "Profile": "โปรไฟล์",

  // ---- Calendar ----
  "Calendar": "ปฏิทิน",
  "Dashboard": "แดชบอร์ด",
  "Tasks": "งาน",
  "Whole month": "ทั้งเดือน",
  "Project Status": "สถานะโปรเจกต์",
  "Date range": "ช่วงวันที่",
  "Select dates": "เลือกวันที่",
  "Select start date": "เลือกวันเริ่มต้น",
  "Select end date": "เลือกวันสิ้นสุด",
  "Scheduled Dates": "วันที่กำหนด",
  "night": "คืน",
  "nights": "คืน",
  "Full calendar": "ปฏิทินทั้งหมด",
  "Jobs for": "งานวันที่",
  "New task": "งานใหม่",
  "Today": "วันนี้",
  "Tomorrow": "พรุ่งนี้",
  "In": "ใน",
  "days": "วัน",
  "Nothing scheduled": "ยังไม่มีนัดหมาย",
  "Tap New task to schedule one": "แตะ \"งานใหม่\" เพื่อกำหนดตาราง",
  "Mon": "จ.",
  "Tue": "อ.",
  "Wed": "พ.",
  "Thu": "พฤ.",
  "Fri": "ศ.",
  "Sat": "ส.",
  "Sun": "อา.",
  "January": "มกราคม",
  "February": "กุมภาพันธ์",
  "March": "มีนาคม",
  "April": "เมษายน",
  "May": "พฤษภาคม",
  "June": "มิถุนายน",
  "July": "กรกฎาคม",
  "August": "สิงหาคม",
  "September": "กันยายน",
  "October": "ตุลาคม",
  "November": "พฤศจิกายน",
  "December": "ธันวาคม",

  // ---- Login page ----
  "Welcome Back": "ยินดีต้อนรับกลับ",
  "Please sign in to continue": "กรุณาเข้าสู่ระบบเพื่อดำเนินการต่อ",
  "Email address": "อีเมล",
  "Password": "รหัสผ่าน",
  "Forgot Password?": "ลืมรหัสผ่าน?",
  "Sign in as": "เข้าสู่ระบบในฐานะ",
  "Engineer": "วิศวกร",
  "Manager": "ผู้จัดการ",
  "Sign In": "เข้าสู่ระบบ",

  // ---- Dashboard ----
  "Today's Summary": "สรุปวันนี้",
  "Assigned": "มอบหมายแล้ว",
  "In Progress": "กำลังดำเนินการ",
  "Completed": "เสร็จสิ้น",
  "Overdue": "เกินกำหนด",
  "Today's Jobs": "งานวันนี้",
  "See All": "ดูทั้งหมด",
  "No jobs yet": "ยังไม่มีงาน",
  "Unassigned": "ยังไม่มอบหมาย",
  "Pending Signature": "รอลายเซ็น",

  // ---- Profile page ----
  "Profile & Settings": "โปรไฟล์และการตั้งค่า",
  "Edit Name": "แก้ไขชื่อ",
  "Your name": "ชื่อของคุณ",
  "Cancel": "ยกเลิก",
  "Save": "บันทึก",
  "No email on file": "ไม่มีอีเมลในระบบ",
  "Work History": "ประวัติการทำงาน",
  "has worked on": "เคยทำงานที่",
  "View All": "ดูทั้งหมด",
  "Log Out": "ออกจากระบบ",
  "Language": "ภาษา",
  "English": "อังกฤษ",
  "Thai": "ไทย",
  "Engineering Manager": "ผู้จัดการฝ่ายวิศวกรรม",
  "Service Engineer": "วิศวกรบริการ",

  // ---- Job history / project history ----
  "Job History": "ประวัติงาน",
  "Search jobs": "ค้นหางาน",
  "All": "ทั้งหมด",
  "No jobs match your search": "ไม่พบงานที่ตรงกับการค้นหา",
  "Detail": "รายละเอียด",
  "Close": "ปิด",
  "Check Status": "ตรวจสอบสถานะ",
  "Get Signature": "ขอลายเซ็น",
  "Checking...": "กำลังตรวจสอบ...",
  "Awaiting customer signature — due today":
      "รอลายเซ็นลูกค้า — ครบกำหนดวันนี้",
  "Customer has signed — job marked complete":
      "ลูกค้าลงลายเซ็นแล้ว — งานถูกทำเครื่องหมายว่าเสร็จสิ้น",
  "Not signed yet": "ยังไม่ได้ลงลายเซ็น",
  "Signature-link flow isn't configured yet — see sharepoint_service.dart":
      "ยังไม่ได้ตั้งค่าลิงก์ลายเซ็น — โปรดดู sharepoint_service.dart",

  // ---- Assign page ----
  "Assign Jobs": "มอบหมายงาน",
  "Create": "สร้าง",
  "Tap Create to assign a new job": "แตะ \"สร้าง\" เพื่อมอบหมายงานใหม่",

  // ---- Assign job detail page ----
  "Create Job": "สร้างงาน",
  "Edit Job": "แก้ไขงาน",
  "Done": "เสร็จสิ้น",
  "Back": "ย้อนกลับ",
  "Job Title": "ชื่องาน",
  "e.g. Kansi": "เช่น Kansi",
  "Job Type": "ประเภทงาน",
  "Project": "โปรเจกต์",
  "Service": "บริการ",
  "Service Type": "ประเภทบริการ",
  "Product": "สินค้า",
  "Brand": "แบรนด์",
  "Model": "รุ่น",
  "Find items": "ค้นหารายการ",
  "Description": "รายละเอียด",
  "Describe the job": "อธิบายงาน",
  "Expected Date": "วันที่คาดว่าจะแล้วเสร็จ",
  "Select date": "เลือกวันที่",
  "Location": "สถานที่",
  "Enter location": "กรอกสถานที่",
  "Open\nMaps": "เปิด\nแผนที่",
  "Select engineer": "เลือกวิศวกร",
  "Action": "การดำเนินการ",
  "Select action": "เลือกการดำเนินการ",
  "Task": "งานย่อย",
  "Select task": "เลือกงานย่อย",
  "Please enter a job title": "กรุณากรอกชื่องาน",
  "Please enter a description": "กรุณากรอกรายละเอียด",
  "Please select an expected date": "กรุณาเลือกวันที่คาดว่าจะแล้วเสร็จ",
  "Please enter a location": "กรุณากรอกสถานที่",
  "Maps integration not configured yet": "ยังไม่ได้เชื่อมต่อระบบแผนที่",

  // ---- Service form / survey page ----
  "Service Form": "แบบฟอร์มบริการ",
  "Photos": "รูปภาพ",
  "Service By": "ให้บริการโดย",
  "Remarks": "หมายเหตุ",
  "Call to Action (next visit)": "สิ่งที่ต้องทำในครั้งถัดไป",
  "Authorized By": "อนุมัติโดย",
  "Customer not on-site": "ลูกค้าไม่อยู่หน้างาน",
  "Submit now and email them a link to sign remotely":
      "ส่งตอนนี้และอีเมลลิงก์ให้ลูกค้าเซ็นจากระยะไกล",
  "Customer email": "อีเมลลูกค้า",
  "Signature": "ลายเซ็น",
  "Clear": "ล้าง",
  "Sign above using your finger or stylus": "เซ็นด้านบนด้วยนิ้วหรือปากกาสไตลัส",
  "SUBMIT": "ส่ง",
  "Take Photo": "ถ่ายภาพ",
  "Choose from Gallery (select multiple)": "เลือกจากคลังภาพ (เลือกได้หลายภาพ)",
  "Add photo": "เพิ่มรูปภาพ",
  "Select engineer ": "เลือกวิศวกร",
  "Please select who performed the service": "กรุณาเลือกผู้ให้บริการ",
  "Please enter remarks": "กรุณากรอกหมายเหตุ",
  "Please enter a call to action for the next visit":
      "กรุณากรอกสิ่งที่ต้องทำในครั้งถัดไป",
  "Please enter who authorized this service": "กรุณากรอกชื่อผู้อนุมัติบริการนี้",
  "Please enter the customer's email to send the signing link":
      "กรุณากรอกอีเมลลูกค้าเพื่อส่งลิงก์ลงลายเซ็น",
  "Please collect a signature before submitting": "กรุณาเก็บลายเซ็นก่อนส่งข้อมูล",
  "Success": "สำเร็จ",
  "your service job": "งานบริการของคุณ",
  "Upload Issue": "ปัญหาการอัปโหลด",
  "Submitted. A signing link has been emailed to the customer.":
      "ส่งข้อมูลแล้ว มีการอีเมลลิงก์ลงลายเซ็นให้ลูกค้าแล้ว",
  "Survey submitted successfully!": "ส่งแบบฟอร์มสำเร็จ!",
  "OK": "ตกลง",

  // ---- Collect signature page ----
  "Please have the customer sign first": "กรุณาให้ลูกค้าเซ็นก่อน",
  "Signature saved — job marked complete":
      "บันทึกลายเซ็นแล้ว — งานถูกทำเครื่องหมายว่าเสร็จสิ้น",
  "SAVE SIGNATURE": "บันทึกลายเซ็น",
  "This job was submitted without a customer signature. ":
      "งานนี้ถูกส่งโดยไม่มีลายเซ็นลูกค้า ",
  "Capture it now to mark the job complete.": "เก็บลายเซ็นตอนนี้เพื่อทำเครื่องหมายว่างานเสร็จสิ้น",

  // ---- SharePoint service messages (surfaced in snackbars) ----
  "SharePoint backend not configured yet. ": "ยังไม่ได้ตั้งค่าเซิร์ฟเวอร์ SharePoint ",
  "Set SharePointService.backendBaseUrl / apiKey in sharepoint_service.dart.":
      "โปรดตั้งค่า SharePointService.backendBaseUrl / apiKey ในไฟล์ sharepoint_service.dart",
  "Uploaded to SharePoint": "อัปโหลดไปยัง SharePoint แล้ว",
  "Signature-link backend not configured yet. ": "ยังไม่ได้ตั้งค่าเซิร์ฟเวอร์สำหรับลิงก์ลายเซ็น ",
  "Set backendBaseUrl / apiKey in sharepoint_service.dart.":
      "โปรดตั้งค่า backendBaseUrl / apiKey ในไฟล์ sharepoint_service.dart",
  "Signing link emailed to customer": "ส่งลิงก์ลงลายเซ็นให้ลูกค้าทางอีเมลแล้ว",
  "Signature saved on this device. It'll sync to SharePoint once the backend is connected.":
      "บันทึกลายเซ็นไว้ในเครื่องนี้แล้ว จะซิงค์ไปยัง SharePoint เมื่อเชื่อมต่อเซิร์ฟเวอร์แล้ว",

  // ---- Job details page ----
  "Job Details": "รายละเอียดงาน",
  "Registered, but no QR link came back — check the backend logs.":
      "ลงทะเบียนแล้ว แต่ไม่ได้รับลิงก์ QR กลับมา — โปรดตรวจสอบล็อกของเซิร์ฟเวอร์",
  "Start Service": "เริ่มบริการ",
  "Sign-off": "ลงลายเซ็นยืนยัน",
  "Status": "สถานะ",
  "Date": "วันที่",
  "View Project History": "ดูประวัติโปรเจกต์",

  // ---- Sales role ----
  "Sales": "ฝ่ายขาย",
  "Welcome": "ยินดีต้อนรับ",
  "What would you like to do?": "คุณต้องการทำอะไร?",
  "New Project Information": "ข้อมูลโปรเจกต์ใหม่",
  "Engineer Action Request": "คำขอให้ช่างดำเนินการ",
  "After Sale Service Request": "คำขอบริการหลังการขาย",
  "Customer Name": "ชื่อลูกค้า",
  "Company Name": "ชื่อบริษัท",
  "Contact Person": "ผู้ติดต่อ",
  "Contact Number": "เบอร์ติดต่อ",
  "LINE ID (optional)": "LINE ID (ไม่บังคับ)",
  "LINE Username (optional)": "ชื่อผู้ใช้ LINE (ไม่บังคับ)",
  "Received Date": "วันที่ได้รับข้อมูล",
  "Referral Source": "แหล่งที่มาของลูกค้า",
  "Facebook": "Facebook",
  "LINE": "LINE",
  "Advertisement": "โฆษณา",
  "Submit": "ส่งข้อมูล",
  "Project information saved": "บันทึกข้อมูลโปรเจกต์แล้ว",
  "Please enter the customer's name": "กรุณากรอกชื่อลูกค้า",
  "Please enter the company name": "กรุณากรอกชื่อบริษัท",
  "Please enter the contact person": "กรุณากรอกชื่อผู้ติดต่อ",
  "Please enter a valid contact number": "กรุณากรอกเบอร์ติดต่อให้ถูกต้อง",
  "Select Project": "เลือกโปรเจกต์",
  "Project Info": "ข้อมูลโปรเจกต์",
  "Project Type": "ประเภทโปรเจกต์",
  "Notes": "หมายเหตุ",
  "Customer Info": "ข้อมูลลูกค้า",
  "Not on file yet — fill in below if known": "ยังไม่มีข้อมูล กรุณากรอกด้านล่างหากทราบ",
  "Phone Number": "เบอร์โทรศัพท์",
  "Request Details": "รายละเอียดคำขอ",
  "Products": "สินค้า",
  "Priority": "ความสำคัญ",
  "Normal": "ปกติ",
  "Urgent": "ด่วน",
  "Please select a project": "กรุณาเลือกโปรเจกต์",
  "Please describe the products involved": "กรุณาระบุสินค้าที่เกี่ยวข้อง",
  "Please describe what's needed": "กรุณาระบุสิ่งที่ต้องการให้ดำเนินการ",
  "Request sent to the manager": "ส่งคำขอถึงผู้จัดการแล้ว",
  "Please describe the issue": "กรุณาอธิบายปัญหา",
  "Repair": "ซ่อมแซม",
  "Warranty claim": "เคลมประกัน",
  "Complaint": "ข้อร้องเรียน",
  "General inquiry": "สอบถามทั่วไป",
  "Issue Category": "ประเภทปัญหา",
  "Notifications": "การแจ้งเตือน",
  "No notifications yet": "ยังไม่มีการแจ้งเตือน",
  "Just now": "เมื่อสักครู่",
  "min ago": "นาทีที่แล้ว",
  "hr ago": "ชั่วโมงที่แล้ว",
  "days ago": "วันที่แล้ว",
};
