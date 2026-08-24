import 'dart:convert';
import 'package:flutter/material.dart';
import 'signature_pad.dart';
import 'job_history_page.dart';
import 'sharepoint_service.dart';
import 'app_core.dart';

/// Opened from the Projects tab when a job is flagged "Awaiting customer
/// signature". Lets the engineer capture the signature once the customer
/// is available, then clears the pending flag on that job.
class CollectSignaturePage extends StatefulWidget {
  final String jobId;
  final String jobTitle;

  const CollectSignaturePage({
    super.key,
    required this.jobId,
    required this.jobTitle,
  });

  @override
  State<CollectSignaturePage> createState() => _CollectSignaturePageState();
}

class _CollectSignaturePageState extends State<CollectSignaturePage> {
  final GlobalKey<SignaturePadState> _sigKey = GlobalKey<SignaturePadState>();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    AppLocale.languageNotifier.addListener(_onLanguageChanged);
  }

  @override
  void dispose() {
    AppLocale.languageNotifier.removeListener(_onLanguageChanged);
    super.dispose();
  }

  void _onLanguageChanged() => setState(() {});

  Future<void> _save() async {
    final isEmpty = _sigKey.currentState?.isEmpty ?? true;
    if (isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr("Please have the customer sign first"))),
      );
      return;
    }

    setState(() => _saving = true);

    // Capture the PNG and save it locally onto the job right away — this
    // always succeeds regardless of the network, so the signature is never
    // lost even if the upload below fails or the backend isn't configured.
    final sigBytes = await _sigKey.currentState?.exportPng();
    final signatureBase64 = sigBytes != null ? base64Encode(sigBytes) : null;

    JobHistoryPage.markSignatureCollected(widget.jobId, signatureBase64: signatureBase64);

    // Now actually try to sync it to the backend/SharePoint too.
    var syncMessage = tr("Signature saved — job marked complete");
    if (signatureBase64 != null) {
      final result = await SharePointService.uploadCollectedSignature(
        jobId: widget.jobId,
        signatureBase64: signatureBase64,
      );
      if (!result.success) {
        syncMessage = tr("Signature saved on this device. It'll sync to SharePoint once the backend is connected.");
      }
    }

    if (!mounted) return;
    setState(() => _saving = false);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(syncMessage)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgGray,
      appBar: AppBar(
        backgroundColor: navy,
        elevation: 0,
        title: Text("${tr("Sign-off")} · ${widget.jobTitle}", style: const TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.orange, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "${tr("This job was submitted without a customer signature. ")}"
                      "${tr("Capture it now to mark the job complete.")}",
                      style: const TextStyle(fontSize: 12, color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  tr("Signature"),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
                ),
                TextButton.icon(
                  onPressed: () => _sigKey.currentState?.clear(),
                  icon: const Icon(Icons.refresh, size: 16, color: Colors.black87),
                  label: Text(tr("Clear"), style: const TextStyle(color: Colors.black87)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            SizedBox(
              height: 200,
              width: double.infinity,
              child: SignaturePad(key: _sigKey),
            ),
            const SizedBox(height: 4),
            Text(
              tr("Sign above using your finger or stylus"),
              style: const TextStyle(fontSize: 11, color: Colors.black38),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: navy,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.4),
                      )
                    : Text(
                        tr("SAVE SIGNATURE"),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}