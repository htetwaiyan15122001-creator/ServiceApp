import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'signature_pad.dart';
import 'sharepoint_service.dart';
import 'job_history_page.dart';
import 'app_core.dart';

class SurveyPage extends StatefulWidget {
  final String? jobId;
  const SurveyPage({super.key, this.jobId});

  @override
  State<SurveyPage> createState() => _SurveyPageState();
}

class _SurveyPageState extends State<SurveyPage> {
  final remarksController = TextEditingController();
  final callToActionController = TextEditingController();
  final authorizedByController = TextEditingController();

  // LINE-based remote signing (replaces the old email-link flow).
  List<LineCustomer> _lineCustomers = [];
  String? _selectedCustomerName;
  bool _loadingCustomers = false;

  // Same list of engineers used in the Assign form, so Service By always
  // matches who a manager can actually assign a job to.
  String? _selectedServiceBy;
  bool _customerNotOnSite = false;

  final GlobalKey<SignaturePadState> _sigKey = GlobalKey<SignaturePadState>();
  final ImagePicker _picker = ImagePicker();

  // Stored as raw bytes (not dart:io File) so previews work identically on
  // mobile and Flutter Web.
  final List<Uint8List> _photoBytes = [];
  final List<String> _photoNames = [];
  bool _submitting = false;

  static const int minPhotos = 3;

  @override
  void initState() {
    super.initState();
    AppLocale.languageNotifier.addListener(_onLanguageChanged);
    _loadLineCustomers();
  }

  Future<void> _loadLineCustomers() async {
    setState(() => _loadingCustomers = true);
    final customers = await SharePointService.fetchLineCustomers();
    if (!mounted) return;
    setState(() {
      _lineCustomers = customers;
      _loadingCustomers = false;
    });
  }

  Future<void> _registerNewCustomer() async {
    final nameController = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(tr("Register new LINE customer")),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: InputDecoration(hintText: tr("Customer name")),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr("Cancel")),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, nameController.text.trim()),
            child: Text(tr("Next"), style: const TextStyle(color: navy, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty || !mounted) return;

    final result = await SharePointService.registerLineCustomer(name);
    if (!mounted) return;
    if (!result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.error ?? tr("Something went wrong."))),
      );
      return;
    }

    // Guard against the QR dialog ever opening with nothing to show — a
    // blank/missing qrLink is exactly what triggers qr_flutter's
    // "Cannot hit test a render box with no size" crash, which leaves the
    // screen darkened (dialog barrier up) with no way to dismiss it.
    if (result.qrLink == null || result.qrLink!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr("Registered, but no QR link came back — check the backend logs."))),
      );
      await _loadLineCustomers();
      setState(() => _selectedCustomerName = name);
      return;
    }

    // Show the QR code for the customer to scan.
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(tr("Scan to link LINE")),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              tr("Ask the customer to scan this with their phone's camera, then just tap Send once LINE opens."),
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 16),
            // Wrapped in a fixed-size SizedBox on purpose — qr_flutter's
            // QrImageView can throw a "RenderBox with no size" layout
            // error if its parent doesn't hand it hard constraints before
            // it tries to paint. This forces that regardless of package
            // version quirks.
            SizedBox(
              width: 200,
              height: 200,
              child: QrImageView(data: result.qrLink!, size: 200),
            ),
            const SizedBox(height: 8),
            Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr("Done"), style: const TextStyle(color: navy, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    // Refresh the dropdown — the new row exists now, even though it won't
    // show as "linked" until the customer actually taps send in LINE.
    await _loadLineCustomers();
    setState(() => _selectedCustomerName = name);
  }

  void _onLanguageChanged() => setState(() {});

  @override
  void dispose() {
    AppLocale.languageNotifier.removeListener(_onLanguageChanged);
    remarksController.dispose();
    callToActionController.dispose();
    authorizedByController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final choice = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: navy),
              title: Text(tr("Take Photo")),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: navy),
              title: Text(tr("Choose from Gallery (select multiple)")),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (choice == null) return;

    if (choice == ImageSource.gallery) {
      // Gallery supports picking many photos at once.
      final picked = await _picker.pickMultiImage(imageQuality: 80);
      for (final x in picked) {
        final bytes = await x.readAsBytes();
        setState(() {
          _photoBytes.add(bytes);
          _photoNames.add(x.name);
        });
      }
    } else {
      // Camera only ever returns one photo per tap — user can tap again to add more.
      final picked = await _picker.pickImage(source: choice, imageQuality: 80);
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _photoBytes.add(bytes);
          _photoNames.add(picked.name);
        });
      }
    }
  }

  Future<void> _submit() async {
    // ---- Required field validation ----
    if (_photoBytes.length < minPhotos) {
      final msg = AppLocale.isThai
          ? "กรุณาเพิ่มรูปภาพอย่างน้อย $minPhotos รูป (ตอนนี้มี ${_photoBytes.length} รูป)"
          : "Please add at least $minPhotos photos (you have ${_photoBytes.length}).";
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
      return;
    }
    if (_selectedServiceBy == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr("Please select who performed the service"))),
      );
      return;
    }
    if (remarksController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr("Please enter remarks"))),
      );
      return;
    }
    if (callToActionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr("Please enter a call to action for the next visit"))),
      );
      return;
    }
    if (authorizedByController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr("Please enter who authorized this service"))),
      );
      return;
    }
    if (_customerNotOnSite && _selectedCustomerName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr("Please select or register a customer to send the signing link via LINE"))),
      );
      return;
    }
    final sigIsEmpty = _sigKey.currentState?.isEmpty ?? true;
    if (!_customerNotOnSite && sigIsEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr("Please collect a signature before submitting"))),
      );
      return;
    }

    setState(() => _submitting = true);

    final photoBase64List = _photoBytes.map(base64Encode).toList();
    final photoFileNames = List<String>.from(_photoNames);

    String? signatureBase64;
    if (!sigIsEmpty) {
      final sigBytes = await _sigKey.currentState?.exportPng();
      if (sigBytes != null) {
        signatureBase64 = base64Encode(sigBytes);
      }
    }

    // Job Type was already chosen when the job was created/assigned —
    // no need to ask for it again here.
    final linkedJob = widget.jobId != null ? JobHistoryPage.findJob(widget.jobId!) : null;

    // Save the report locally FIRST so the photos and signature are never
    // lost, regardless of whether the SharePoint backend is configured or
    // reachable. This also updates the job's status right away instead of
    // waiting on (and depending on) the network call below.
    if (widget.jobId != null) {
      JobHistoryPage.attachReportPhotos(
        widget.jobId!,
        photoBase64: photoBase64List,
        photoFileNames: photoFileNames,
        signatureBase64: signatureBase64,
      );
      if (_customerNotOnSite) {
        JobHistoryPage.markPendingSignature(widget.jobId!);
      } else {
        JobHistoryPage.markCompleted(widget.jobId!);
      }
    }

    final result = await SharePointService.uploadServiceReport(
      jobId: widget.jobId,
      jobType: linkedJob?.jobType,
      photoBase64List: photoBase64List,
      photoFileNames: photoFileNames,
      signatureBase64: signatureBase64,
      serviceBy: _selectedServiceBy,
      serviceByEmail: null,
      remarks: remarksController.text.trim(),
      callToAction: callToActionController.text.trim(),
      authorizedBy: authorizedByController.text.trim(),
      customerNotOnSite: _customerNotOnSite,
    );

    if (result.success && widget.jobId != null && _customerNotOnSite && _selectedCustomerName != null) {
      final job = JobHistoryPage.findJob(widget.jobId!);
      await SharePointService.sendSignatureLinkLine(
        jobId: widget.jobId!,
        jobTitle: job?.title ?? tr("your service job"),
        customerName: _selectedCustomerName!,
      );
    }

    setState(() => _submitting = false);

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              result.success ? Icons.check_circle : Icons.cloud_off,
              color: result.success ? Colors.green : Colors.orange,
            ),
            const SizedBox(width: 8),
            Text(result.success ? tr("Success") : tr("Saved locally")),
          ],
        ),
        content: Text(
          result.success
              ? (_customerNotOnSite
                  ? tr("Submitted. A signing link has been sent to the customer via LINE.")
                  : tr("Survey submitted successfully!"))
              : tr("Report, photos, and signature are saved on this device. They'll sync to SharePoint once the backend is connected."),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Text(
              tr("OK"),
              style: const TextStyle(color: navy, fontWeight: FontWeight.w600),
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgGray,
      appBar: AppBar(
        backgroundColor: navy,
        elevation: 0,
        title: Text(
          tr("Service Form"),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _requiredLabel(tr("Photos")),
            const SizedBox(height: 12),
            _photoBox(),

            const SizedBox(height: 24),
            _requiredLabel(tr("Service By")),
            const SizedBox(height: 12),
            _serviceByDropdown(),

            const SizedBox(height: 24),
            _requiredLabel(tr("Remarks")),
            const SizedBox(height: 12),
            _buildField(
              controller: remarksController,
              label: tr("Remarks"),
              icon: Icons.notes_outlined,
              maxLines: 3,
            ),

            const SizedBox(height: 16),
            _requiredLabel(tr("Call to Action (next visit)")),
            const SizedBox(height: 12),
            _buildField(
              controller: callToActionController,
              label: tr("Call to Action (next visit)"),
              icon: Icons.event_repeat_outlined,
              maxLines: 3,
            ),

            const SizedBox(height: 16),
            _requiredLabel(tr("Authorized By")),
            const SizedBox(height: 12),
            _buildField(
              controller: authorizedByController,
              label: tr("Authorized By"),
              icon: Icons.verified_user_outlined,
            ),

            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: CheckboxListTile(
                value: _customerNotOnSite,
                onChanged: (v) => setState(() => _customerNotOnSite = v ?? false),
                activeColor: navy,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(
                  tr("Customer not on-site"),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  tr("Submit now and send them a link via LINE to sign remotely"),
                  style: const TextStyle(fontSize: 11, color: Colors.black45),
                ),
              ),
            ),
            if (_customerNotOnSite) ...[
              const SizedBox(height: 12),
              _lineCustomerPicker(),
            ],

            if (!_customerNotOnSite) ...[
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _requiredLabel(tr("Signature")),
                  TextButton.icon(
                    onPressed: () => _sigKey.currentState?.clear(),
                    icon: const Icon(Icons.refresh, size: 16, color: Color.fromARGB(255, 0, 0, 0)),
                    label: Text(tr("Clear"), style: const TextStyle(color: Color.fromARGB(255, 0, 0, 0))),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              SizedBox(
                height: 160,
                width: double.infinity,
                child: SignaturePad(key: _sigKey),
              ),
              const SizedBox(height: 4),
              Text(
                tr("Sign above using your finger or stylus"),
                style: const TextStyle(fontSize: 11, color: Colors.black38),
              ),
            ],

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: navy,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.4,
                        ),
                      )
                    : Text(
                        tr("SUBMIT"),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _requiredLabel(String text) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
        children: [
          const TextSpan(text: "* ", style: TextStyle(color: Colors.red)),
          TextSpan(text: text),
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: label,
          hintStyle: const TextStyle(color: Colors.black38, fontSize: 14),
          prefixIcon: Icon(icon, color: navy, size: 20),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        ),
      ),
    );
  }

  Widget _serviceByDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.engineering_outlined, color: navy, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: _selectedServiceBy,
                itemHeight: 56,
                hint: Text(
                  tr("Select engineer"),
                  style: const TextStyle(color: Colors.black45, fontSize: 14),
                ),
                items: engineerNames
                    .map((name) => DropdownMenuItem(
                          value: name,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Text(name),
                          ),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => _selectedServiceBy = value),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _lineCustomerPicker() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.chat_bubble_outline, color: navy, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: _loadingCustomers
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: LinearProgressIndicator(),
                      )
                    : DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: _selectedCustomerName,
                          itemHeight: 56,
                          hint: Text(
                            tr("Select customer"),
                            style: const TextStyle(color: Colors.black45, fontSize: 14),
                          ),
                          items: _lineCustomers
                              .map((c) => DropdownMenuItem(
                                    value: c.customerName,
                                    enabled: c.linked,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 4),
                                      child: Text(
                                        c.linked ? c.customerName : "${c.customerName} ${tr("(not linked yet)")}",
                                        style: TextStyle(color: c.linked ? Colors.black87 : Colors.black38),
                                      ),
                                    ),
                                  ))
                              .toList(),
                          onChanged: (value) => setState(() => _selectedCustomerName = value),
                        ),
                      ),
              ),
            ],
          ),
          const Divider(height: 1),
          TextButton.icon(
            onPressed: _registerNewCustomer,
            icon: const Icon(Icons.qr_code, size: 18, color: navy),
            label: Text(
              tr("Register new LINE customer"),
              style: const TextStyle(color: navy, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _photoBox() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _photoBytes.length + 1,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1,
          ),
          itemBuilder: (context, index) {
            if (index == _photoBytes.length) {
              // "Add photo" tile, always shown last.
              return InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: _pickPhoto,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.black12, width: 1.2),
                  ),
                  child: const Center(
                    child: Icon(Icons.add_a_photo_outlined, color: navy, size: 26),
                  ),
                ),
              );
            }
            final bytes = _photoBytes[index];
            return Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  // Image.memory works the same on mobile and Flutter Web —
                  // unlike Image.file, which isn't supported on web.
                  child: Image.memory(bytes, fit: BoxFit.cover),
                ),
                Positioned(
                  right: 4,
                  top: 4,
                  child: GestureDetector(
                    onTap: () => setState(() {
                      _photoBytes.removeAt(index);
                      _photoNames.removeAt(index);
                    }),
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, color: Colors.white, size: 14),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 8),
        Text(
          _photoBytes.length < minPhotos
              ? (AppLocale.isThai
                  ? "${_photoBytes.length} / $minPhotos รูป (ขั้นต่ำ)"
                  : "${_photoBytes.length} / $minPhotos photos minimum")
              : (AppLocale.isThai
                  ? "เพิ่มแล้ว ${_photoBytes.length} รูป"
                  : "${_photoBytes.length} photos added"),
          style: TextStyle(
            fontSize: 12,
            color: _photoBytes.length < minPhotos ? Colors.redAccent : Colors.green,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}