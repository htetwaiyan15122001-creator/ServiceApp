import 'package:flutter/material.dart';
import 'sales_requests.dart';
import 'app_core.dart';

class AfterSaleServiceRequestPage extends StatefulWidget {
  const AfterSaleServiceRequestPage({super.key});

  @override
  State<AfterSaleServiceRequestPage> createState() => _AfterSaleServiceRequestPageState();
}

class _AfterSaleServiceRequestPageState extends State<AfterSaleServiceRequestPage> {
  final customerNameController = TextEditingController();
  final contactNumberController = TextEditingController(text: "+66 ");
  final lineUsernameController = TextEditingController();
  final companyNameController = TextEditingController();
  final contactPersonController = TextEditingController();
  final descriptionController = TextEditingController();

  String _referralSource = referralSources.first;
  String _issueCategory = issueCategories.first;
  bool _submitting = false;

  @override
  void dispose() {
    customerNameController.dispose();
    contactNumberController.dispose();
    lineUsernameController.dispose();
    companyNameController.dispose();
    contactPersonController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (customerNameController.text.trim().isEmpty) {
      _warn(tr("Please enter the customer's name"));
      return;
    }
    if (contactNumberController.text.trim().length < 5) {
      _warn(tr("Please enter a valid contact number"));
      return;
    }
    if (companyNameController.text.trim().isEmpty) {
      _warn(tr("Please enter the company name"));
      return;
    }
    if (contactPersonController.text.trim().isEmpty) {
      _warn(tr("Please enter the contact person"));
      return;
    }
    if (descriptionController.text.trim().isEmpty) {
      _warn(tr("Please describe the issue"));
      return;
    }

    setState(() => _submitting = true);

    SalesRequests.submitAfterSaleServiceRequest(
      customerName: customerNameController.text.trim(),
      contactNumber: contactNumberController.text.trim(),
      lineUsername: lineUsernameController.text.trim().isEmpty ? null : lineUsernameController.text.trim(),
      referralSource: _referralSource,
      companyName: companyNameController.text.trim(),
      contactPerson: contactPersonController.text.trim(),
      issueCategory: _issueCategory,
      description: descriptionController.text.trim(),
    );

    setState(() => _submitting = false);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(tr("Request sent to the manager"))),
    );
    Navigator.pop(context);
  }

  void _warn(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLanguage>(
      valueListenable: AppLocale.languageNotifier,
      builder: (context, _, __) {
        return Scaffold(
          backgroundColor: bgGray,
          appBar: AppBar(
            backgroundColor: navy,
            elevation: 0,
            title: Text(tr("After Sale Service Request"), style: const TextStyle(color: Colors.white)),
            iconTheme: const IconThemeData(color: Colors.white),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
            ),
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _label(tr("Customer Name")),
                _field(customerNameController, tr("Customer name"), Icons.person_outline),
                const SizedBox(height: 16),
                _label(tr("Contact Number")),
                _field(contactNumberController, "+66 ...", Icons.call_outlined, keyboardType: TextInputType.phone),
                const SizedBox(height: 16),
                _label(tr("LINE Username (optional)")),
                _field(lineUsernameController, tr("LINE username"), Icons.chat_bubble_outline),
                const SizedBox(height: 16),
                _label(tr("Referral Source")),
                _cardBox(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _referralSource,
                      isExpanded: true,
                      itemHeight: 56,
                      dropdownColor: Colors.white,
                      icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: navy),
                      items: referralSources
                          .map((s) => DropdownMenuItem(
                                value: s,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Text(tr(s)),
                                ),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _referralSource = v ?? _referralSource),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _label(tr("Company Name")),
                _field(companyNameController, tr("Company name"), Icons.apartment_outlined),
                const SizedBox(height: 16),
                _label(tr("Contact Person")),
                _field(contactPersonController, tr("Contact person"), Icons.badge_outlined),
                const SizedBox(height: 16),
                _label(tr("Issue Category")),
                _cardBox(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _issueCategory,
                      isExpanded: true,
                      itemHeight: 56,
                      dropdownColor: Colors.white,
                      icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: navy),
                      items: issueCategories
                          .map((s) => DropdownMenuItem(
                                value: s,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Text(tr(s)),
                                ),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _issueCategory = v ?? _issueCategory),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _label(tr("Description")),
                _field(descriptionController, tr("Describe the issue"), Icons.notes_outlined, maxLines: 4),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: navy,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    onPressed: _submitting ? null : _submit,
                    child: _submitting
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(tr("Submit"), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black54)),
      );

  Widget _cardBox({required Widget child}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: child,
      );

  Widget _field(TextEditingController controller, String hint, IconData icon, {TextInputType? keyboardType, int maxLines = 1}) {
    return _cardBox(
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.black38, fontSize: 14),
          prefixIcon: Icon(icon, color: navy, size: 20),
          border: InputBorder.none,
          isDense: true,
        ),
      ),
    );
  }
}