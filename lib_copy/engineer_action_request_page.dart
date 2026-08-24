import 'package:flutter/material.dart';
import 'job_history_page.dart';
import 'sales_requests.dart';
import 'app_core.dart';

class EngineerActionRequestPage extends StatefulWidget {
  const EngineerActionRequestPage({super.key});

  @override
  State<EngineerActionRequestPage> createState() => _EngineerActionRequestPageState();
}

class _EngineerActionRequestPageState extends State<EngineerActionRequestPage> {
  HistoryJob? _selectedJob;

  final customerNameController = TextEditingController();
  final companyNameController = TextEditingController();
  final contactPersonController = TextEditingController();
  final phoneNumberController = TextEditingController();
  final lineIdController = TextEditingController();
  final productsController = TextEditingController();
  final descriptionController = TextEditingController();

  String _priority = "Normal";
  bool _submitting = false;

  @override
  void dispose() {
    customerNameController.dispose();
    companyNameController.dispose();
    contactPersonController.dispose();
    phoneNumberController.dispose();
    lineIdController.dispose();
    productsController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickProject() async {
    final jobs = JobHistoryPage.allJobs;
    final picked = await showModalBottomSheet<HistoryJob>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(tr("Select Project"), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: jobs.length,
                  itemBuilder: (context, index) {
                    final job = jobs[index];
                    return ListTile(
                      leading: const Icon(Icons.folder_outlined, color: navy),
                      title: Text(job.title),
                      subtitle: Text(job.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
                      onTap: () => Navigator.pop(context, job),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedJob = picked);
    }
  }

  Future<void> _submit() async {
    if (_selectedJob == null) {
      _warn(tr("Please select a project"));
      return;
    }
    if (productsController.text.trim().isEmpty) {
      _warn(tr("Please describe the products involved"));
      return;
    }
    if (descriptionController.text.trim().isEmpty) {
      _warn(tr("Please describe what's needed"));
      return;
    }

    setState(() => _submitting = true);

    SalesRequests.submitEngineerActionRequest(
      projectId: _selectedJob!.id,
      projectName: _selectedJob!.title,
      customerName: customerNameController.text.trim().isEmpty ? null : customerNameController.text.trim(),
      companyName: companyNameController.text.trim().isEmpty ? null : companyNameController.text.trim(),
      contactPerson: contactPersonController.text.trim().isEmpty ? null : contactPersonController.text.trim(),
      phoneNumber: phoneNumberController.text.trim().isEmpty ? null : phoneNumberController.text.trim(),
      lineId: lineIdController.text.trim().isEmpty ? null : lineIdController.text.trim(),
      projectType: _selectedJob!.jobType,
      location: _selectedJob!.location,
      products: productsController.text.trim(),
      description: descriptionController.text.trim(),
      priority: _priority,
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
    final job = _selectedJob;
    return ValueListenableBuilder<AppLanguage>(
      valueListenable: AppLocale.languageNotifier,
      builder: (context, _, __) {
        return Scaffold(
          backgroundColor: bgGray,
          appBar: AppBar(
            backgroundColor: navy,
            elevation: 0,
            title: Text(tr("Engineer Action Request"), style: const TextStyle(color: Colors.white)),
            iconTheme: const IconThemeData(color: Colors.white),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
            ),
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _label(tr("Project Name")),
                InkWell(
                  onTap: _pickProject,
                  child: _cardBox(
                    child: Row(
                      children: [
                        const Icon(Icons.search, color: navy, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            job?.title ?? tr("Find items"),
                            style: TextStyle(fontSize: 14, color: job == null ? Colors.black38 : Colors.black87),
                          ),
                        ),
                        const Icon(Icons.keyboard_arrow_down, color: navy, size: 20),
                      ],
                    ),
                  ),
                ),
                if (job != null) ...[
                  const SizedBox(height: 20),
                  _sectionHeader(tr("Project Info")),
                  _readOnlyRow(tr("Project Type"), tr(job.jobType)),
                  _readOnlyRow(tr("Location"), job.location ?? "—"),
                  if (job.product != null) _readOnlyRow(tr("Product"), job.product!),
                  if (job.description != null) _readOnlyRow(tr("Notes"), job.description!),
                  const SizedBox(height: 20),
                  _sectionHeader(tr("Customer Info")),
                  Text(
                    tr("Not on file yet — fill in below if known"),
                    style: const TextStyle(fontSize: 11, color: Colors.black38, fontStyle: FontStyle.italic),
                  ),
                  const SizedBox(height: 8),
                  _field(customerNameController, tr("Customer Name"), Icons.person_outline),
                  const SizedBox(height: 10),
                  _field(companyNameController, tr("Company Name"), Icons.apartment_outlined),
                  const SizedBox(height: 10),
                  _field(contactPersonController, tr("Contact Person"), Icons.badge_outlined),
                  const SizedBox(height: 10),
                  _field(phoneNumberController, tr("Phone Number"), Icons.call_outlined, keyboardType: TextInputType.phone),
                  const SizedBox(height: 10),
                  _field(lineIdController, tr("LINE ID"), Icons.chat_bubble_outline),
                  const SizedBox(height: 20),
                  _sectionHeader(tr("Request Details")),
                  _field(productsController, tr("Products"), Icons.inventory_2_outlined),
                  const SizedBox(height: 10),
                  _field(descriptionController, tr("Description"), Icons.notes_outlined, maxLines: 4),
                  const SizedBox(height: 16),
                  _label(tr("Priority")),
                  Row(
                    children: [
                      Expanded(child: _priorityChip("Normal")),
                      const SizedBox(width: 10),
                      Expanded(child: _priorityChip("Urgent")),
                    ],
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
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _priorityChip(String value) {
    final selected = _priority == value;
    final color = value == "Urgent" ? Colors.red : navy;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => setState(() => _priority = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? color : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? color : Colors.black12),
        ),
        child: Center(
          child: Text(
            tr(value),
            style: TextStyle(color: selected ? Colors.white : Colors.black54, fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: navy)),
      );

  Widget _readOnlyRow(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 90, child: Text(label, style: const TextStyle(fontSize: 12, color: Colors.black45))),
            Expanded(child: Text(value, style: const TextStyle(fontSize: 13, color: Colors.black87))),
          ],
        ),
      );

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
