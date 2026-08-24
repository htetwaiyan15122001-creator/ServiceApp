# What's new

- **Profile & Settings page** (`profile_page.dart`) — reachable from the header avatar or the "Profile" nav icon.
- **Job History page** (`job_history_page.dart`) — reachable from "See All" on the dashboard, or the "Projects"/"Task" nav icons.
- **Working photo picker** in the Service Form — tap the photo box to choose Camera or Gallery.
- **Working signature pad** in the Service Form — draw with your finger, "Clear" button resets it.
- **SharePoint upload** (`sharepoint_service.dart`) — submitting the form sends project info + photo + signature to SharePoint.

## 1. Add dependencies

In `pubspec.yaml`, under `dependencies:` add:

```yaml
  image_picker: ^1.1.2
  http: ^1.2.2
```

Then run:
```
flutter pub get
```

## 2. Platform permissions (needed for camera/gallery)

**Android** — in `android/app/src/main/AndroidManifest.xml`, inside `<manifest>`:
```xml
<uses-permission android:name="android.permission.CAMERA"/>
```

**iOS** — in `ios/Runner/Info.plist`, add:
```xml
<key>NSCameraUsageDescription</key>
<string>Used to take photos for service reports</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Used to attach photos to service reports</string>
```

## 3. Connect SharePoint (no Azure app registration needed)

Since you already have SharePoint access, the simplest way to get data in from a mobile app is a **Power Automate flow** — it handles the Microsoft auth for you, and the app just POSTs plain JSON to a URL.

1. Go to https://make.powerautomate.com → **Create → Instant cloud flow**.
2. Trigger: **"When an HTTP request is received"**.
3. Add a **SharePoint → Create file** action, pointed at your Site + document library.
   - File name: use an expression like `concat(triggerBody()?['projectName'], '_', utcNow(), '.json')`
   - File content: the raw request body (or just the fields you want logged).
4. To save the photo/signature as actual image files, add two more **Create file** actions and use the expression `base64ToBinary(triggerBody()?['photoBase64'])` (and the same for `signatureBase64`) as the file content.
5. Save the flow — Power Automate will show you the generated **HTTP POST URL**.
6. Paste that URL into `sharepoint_service.dart`:
   ```dart
   static const String webhookUrl = "https://paste-your-url-here";
   ```

That's it — no client ID/tenant ID/OAuth needed on the app side, since the flow runs under your Microsoft 365 account.

**Note:** until you paste in a real URL, the app will show "SharePoint link not configured yet" instead of failing silently.
