import 'package:flutter/material.dart';
import 'sales_requests.dart';
import 'app_core.dart';

class NewProjectFormPage extends StatefulWidget {
  const NewProjectFormPage({super.key});

  @override
  State<NewProjectFormPage> createState() => _NewProjectFormPageState();
}

class _NewProjectFormPageState extends State<NewProjectFormPage> {
  final customerNameController = TextEditingController();
  final companyNameController = TextEditingController();
  final contactPersonController = TextEditingController();
  final contactNumberController = TextEditingController(text: "+66 ");
  final lineIdController = TextEditingController();

  DateTime _receivedDate = DateTime.now();
  String _referralSource = referralSources.first;
  bool _submitting = false;

  @override
  void dispose() {
    customerNameController.dispose();
    companyNameController.dispose();
    contactPersonController.dispose();
    contactNumberController.dispose();
    lineIdController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _receivedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _receivedDate = picked);
  }

  Future<void> _submit() async {
    if (customerNameController.text.trim().isEmpty) {
      _warn(tr("Please enter the customer's name"));
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
    if (contactNumberController.text.trim().length < 5) {
      _warn(tr("Please enter a valid contact number"));
      return;
    }

    setState(() => _submitting = true);

    SalesRequests.submitNewProject(
      customerName: customerNameController.text.trim(),
      companyName: companyNameController.text.trim(),
      contactPerson: contactPersonController.text.trim(),
      contactNumber: contactNumberController.text.trim(),
      lineId: lineIdController.text.trim().isEmpty ? null : lineIdController.text.trim(),
      receivedDate: _receivedDate,
      referralSource: _referralSource,
    );

    setState(() => _submitting = false);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(tr("Project information saved"))),
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
            title: Text(tr("New Project Information"), style: const TextStyle(color: Colors.white)),
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
                _label(tr("Company Name")),
                _field(companyNameController, tr("Company name"), Icons.apartment_outlined),
                const SizedBox(height: 16),
                _label(tr("Contact Person")),
                _field(contactPersonController, tr("Contact person"), Icons.badge_outlined),
                const SizedBox(height: 16),
                _label(tr("Contact Number")),
                _field(contactNumberController, "+66 ...", Icons.call_outlined, keyboardType: TextInputType.phone),
                const SizedBox(height: 16),
                _label(tr("LINE ID (optional)")),
                _field(lineIdController, tr("LINE ID"), Icons.chat_bubble_outline),
                const SizedBox(height: 16),
                _label(tr("Received Date")),
                InkWell(
                  onTap: _pickDate,
                  child: _cardBox(
                    child: Row(
                      children: [
                        const Icon(Icons.event_outlined, color: navy, size: 20),
                        const SizedBox(width: 10),
                        Text(formatDate(_receivedDate), style: const TextStyle(fontSize: 14)),
                      ],
                    ),
                  ),
                ),
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

  Widget _field(TextEditingController controller, String hint, IconData icon, {TextInputType? keyboardType}) {
    return _cardBox(
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
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

String formatDate(DateTime d) {
  const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
  return "${d.day.toString().padLeft(2, '0')}-${months[d.month - 1]}-${d.year}";
}