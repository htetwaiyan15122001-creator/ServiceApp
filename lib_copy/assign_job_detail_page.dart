import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'job_history_page.dart';
import 'date_range_picker.dart';
import 'app_core.dart';

/// The set of workflow actions a manager can set for a job.
const List<String> assignActions = [
  "Site Survey",
  "Piping & Cabling",
  "Install Equipment",
  "Testing Product",
  "Commissioning",
  "Pre-Handover",
  "Completed",
];

/// When Job Type is "Service", the Action dropdown is restricted to just
/// these two — Service jobs only ever go through testing/commissioning.
const List<String> serviceActions = ["Testing Product", "Commissioning"];


const Map<String, List<String>> actionTasks = {
  "Piping & Cabling": [
    "Checking LCs Wiring & Back Box", "Checking LCs Marking & ACB Position", "Checking All Light Bulbs Are Installed", "Piping and Cabling Checking", "Piping Test", "PO Confirmed", "Control Panel Installation", "Control Panel to Site", "Siam Wellness Group", "Control Panel Light Circuits Termination",
  ],

  "Commissioning": ["Pre-Commissioning" , "Final Commissioning" , "Testing" , "Programming KNX" , "Setting Scene" , "Meeting with Owner"],
  "Pre-Handover": ["Pre-Handover"],
  "Completed": ["Final Handover"],
  "Install Equipment": ["Cable Termination"],
  "Testing Product": ["Testing "],
};

const List<String> productBrands = ["KNX", "Conventional", "JUNGHome"];

const Map<String, List<String>> brandModels = {
  "KNX": [
    "F10SW", "F40SW", "F50SW", "Interface", "KNX Actuator", "KNX Dimmer", "Power Supply", "Visualization", "Programming", "Wiring", "KNX Display",
  ],

  "Conventional": ["Dimmer" ,"Switch"],
  "JUNGHome": ["JUNG Home Socket", "JUNG Home Push Buttons2" , "JUNG Home Push Buttons Battery" , "JUNG Home Motion Detector", "JUNG Home Presence Detector" , "JUNG Home Thermostat" , "Jung Home Gateway" , "JUNG Home Programming" , "Jung Home Wiring" ],
};

const Map<String, List<String>> modelItems = {
  "F10SW": ["F10 Insert SW.", "F10 Rocker"],
  "F40SW": ["F40 Insert Sw", "F40 Cover SW.", "F40 Room Controller Cover Kit", "F40 Room COntroller Display"],
  "F50SW": ["F50 Insert Sw", "F50 Cover SW.", "F50 Room Controller Display"],
  "Interface": ["IP interface", "IP Router", "USB interface", "Line Coupler", "Motion Sensor", "Intesis"],
  "KNX Actuator": ["KNX Switch 6 gang", "KNX Switch 16 gang", "KNX Switch / Blinds 24/12 gang"],
  "KNX Dimmer": ["KNX Dimmer 1 gang", "KNX Dimmer 2 gang", "KNX Dimmer 4 gang", "KNX 1-10V Dimmer 4 gang", "KNX LED controller 5 gang", "KNX DALI Gateway"],
  "Power Supply": ["KNX Power Supply 160mA", "KNX Power Supply 320mA", "KNX Power Supply 640mA", "KNX Power Supply 1280mA", "KNX Power Supply with IP interface"],
  "Visualization": ["AY Control", "Smart VISU", "JVP", "Smart Panel"],
  "Cytech": ["UCM / Logic", "Intelligent Remote I/O", "Infrared submodule for IRIO", "Infrared Cable Assy , round LED", "Current Trasnformer , wire type", "UCM / KNX2 (B)"],
  "Seidal": ["Door Station", "Controller", "Power Supply KNX", "Intercom"],
  "Programming": ["ETS", "KNX Scene", "KNX TImer", "KNX Additional"],
  "Wiring": ["KNX Disconnect", "KNX Loose", "KNX Amend"],
  "KNX Display": ["LS Touch", "KNX Smart Panel_8"],
  "Dimmer": ["Rotary","Touch" , "DALI" , "1-10V" , "Phase Dim" ],
  "Switch":  ["One way Switch " , "Two way Switch" , "Push Button " , "Intermediate" , "Speed Rotary"],
  "JUNG Home Motion Detector": ["1.1M " , "1.1M(IP44)" , "2.2M"],
  "JUNG Home Thermostat": ["Thermostat" ],
  "JUNG Home Actuator": ["Actuator" ],
  "JUNG Home Programming": ["JUNG Home" , "JH Scenes" , "JH Timer" , "JH Additional"],
  "JUNG Home Wiring": ["JUNG Home Disconnect" , "JUNG Home Loose" , "JUNG Home Amend"],
};

const List<String> hourOptions = [
 "09", "10", "11","12", "13", "14", "15", "16", "17", "18"
];
const List<String> minuteOptions = ["00", "15", "30", "45"];

class AssignJobDetailPage extends StatefulWidget {
  final HistoryJob? existing;
  final List<String> engineers;
  // Pre-fills the expected date — used when a manager taps a day on the
  // Calendar view to schedule a job for that specific date.
  final DateTime? initialDate;

  const AssignJobDetailPage({
    super.key,
    this.existing,
    required this.engineers,
    this.initialDate,
  });

  @override
  State<AssignJobDetailPage> createState() => _AssignJobDetailPageState();
}

class _AssignJobDetailPageState extends State<AssignJobDetailPage> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _locationController;

  String _jobType = jobTypeProject;
  String? _selectedServiceSubType;
  String? _brand;
  String? _model;
  List<String> _selectedItems = [];
  DateTime? _startDate;
  DateTime? _endDate;
  String _hour = "09";
  String _minute = "00";
  List<String> _selectedEngineers = [];
  String? _selectedAction;
  String? _selectedTask;

  bool get _isEditing => widget.existing != null;

  /// Service jobs only offer Testing Product / Commissioning as an action;
  /// Project jobs keep the full workflow list.
  List<String> get _availableActions =>
      _jobType == jobTypeService ? serviceActions : assignActions;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _titleController = TextEditingController(text: existing?.title ?? "");
    _descriptionController = TextEditingController(text: existing?.description ?? "");
    _locationController = TextEditingController(text: existing?.location ?? "");
    _startDate = existing?.expectedDate ?? widget.initialDate;
    _endDate = existing?.endDate;
    _jobType = existing?.jobType ?? jobTypeProject;
    _selectedServiceSubType = existing?.serviceSubType ??
        (_jobType == jobTypeService ? serviceSubTypeAfterService : null);
    if (existing?.product != null) {
      final parts = existing!.product!.split(" ");
      _brand = parts.isNotEmpty ? parts.first : null;
      _model = parts.length > 1 ? parts.sublist(1).join(" ") : null;
    }
    _selectedEngineers = (existing?.assignedTo ?? "")
        .split(",")
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    _selectedAction = existing?.action;
    _selectedTask = existing?.task;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await pickDateRange(
      context,
      initialRange: _startDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate ?? _startDate!)
          : null,
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.start == picked.end ? null : picked.end;
      });
    }
  }

  Future<void> _openMaps() async {
    final query = _locationController.text.trim();
    if (query.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr("Enter a location first"))),
      );
      return;
    }

    final uri = Uri.https(
      "www.google.com",
      "/maps/search/",
      {"api": "1", "query": query},
    );

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr("Could not open Maps"))),
      );
    }
  }

  void _save() {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    final location = _locationController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr("Please enter a job title"))),
      );
      return;
    }
    if (description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr("Please enter a description"))),
      );
      return;
    }
    if (_startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr("Please select an expected date"))),
      );
      return;
    }
    if (location.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr("Please enter a location"))),
      );
      return;
    }

    final expectedDateTime = DateTime(
      _startDate!.year,
      _startDate!.month,
      _startDate!.day,
      int.parse(_hour),
      int.parse(_minute),
    );
    final endDateTime = _endDate != null
        ? DateTime(_endDate!.year, _endDate!.month, _endDate!.day)
        : null;
    final product = [
      if (_brand != null) _brand!,
      if (_model != null) _model!,
      if (_selectedItems.isNotEmpty) _selectedItems.join(", "),
    ].join(" ");

    final assignedTo = _selectedEngineers.isEmpty ? null : _selectedEngineers.join(", ");

    final subType = _jobType == jobTypeService ? _selectedServiceSubType : null;

    if (_isEditing) {
      JobHistoryPage.updateJob(
        widget.existing!.id,
        title: title,
        jobType: _jobType,
        serviceSubType: subType,
        product: product.isEmpty ? null : product,
        description: description,
        expectedDate: expectedDateTime,
        endDate: endDateTime,
        location: location,
        assignedTo: assignedTo,
        action: _selectedAction,
        task: _selectedTask,
      );
    } else {
      JobHistoryPage.addJob(
        title: title,
        jobType: _jobType,
        serviceSubType: subType,
        product: product.isEmpty ? null : product,
        description: description,
        expectedDate: expectedDateTime,
        endDate: endDateTime,
        location: location,
        assignedTo: assignedTo,
        action: _selectedAction,
        task: _selectedTask,
      );
    }

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLanguage>(
      valueListenable: AppLocale.languageNotifier,
      builder: (context, _, __) => _buildScaffold(context),
    );
  }

  Widget _buildScaffold(BuildContext context) {
    return Scaffold(
      backgroundColor: bgGray,
      appBar: AppBar(
        backgroundColor: navy,
        elevation: 0,
        title: Text(_isEditing ? tr("Edit Job") : tr("Create Job"), style: const TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr("Job Title"),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: navy),
            ),
            const SizedBox(height: 10),
            _textField(controller: _titleController, hint: tr("e.g. Kansi"), icon: Icons.badge_outlined),

            const SizedBox(height: 24),
            Text(
              tr("Job Type"),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: navy),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _jobTypeOption(
                    value: jobTypeProject,
                    icon: Icons.home_rounded,
                    label: tr("Project"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _jobTypeOption(
                    value: jobTypeService,
                    icon: Icons.build,
                    label: tr("Service"),
                  ),
                ),
              ],
            ),
            if (_jobType == jobTypeService) ...[
              const SizedBox(height: 24),
              Text(
                tr("Service Type"),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: navy),
              ),
              const SizedBox(height: 10),
              _serviceSubTypeSelector(),
            ],

            const SizedBox(height: 24),
            Text(
              tr("Product"),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: navy),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _simpleDropdown(
                    value: _brand,
                    hint: tr("Brand"),
                    items: productBrands,
                    onChanged: (v) => setState(() {
                      _brand = v;
                      // Model list depends on Brand — drop any model that
                      // doesn't belong to the newly-selected brand.
                      if (!(brandModels[v] ?? const []).contains(_model)) {
                        _model = null;
                      }
                      // Item list depends on Model, so prune anything stale.
                      final validItems = modelItems[_model] ?? const [];
                      _selectedItems = _selectedItems.where(validItems.contains).toList();
                    }),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _simpleDropdown(
                    value: _model,
                    hint: tr("Model"),
                    items: brandModels[_brand] ?? const [],
                    onChanged: (v) => setState(() {
                      _model = v;
                      final validItems = modelItems[v] ?? const [];
                      _selectedItems = _selectedItems.where(validItems.contains).toList();
                    }),
                  ),
                ),
              ],
            ),
            if ((modelItems[_model] ?? const []).isNotEmpty) ...[
              const SizedBox(height: 10),
              _multiSelectCard(
                icon: Icons.search,
                hint: tr("Find items"),
                selected: _selectedItems,
                items: modelItems[_model]!,
                onChanged: (v) => setState(() => _selectedItems = v),
              ),
            ],

            const SizedBox(height: 24),
            _requiredLabel(tr("Description")),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: navy.withValues(alpha: 0.4)),
              ),
              child: TextField(
                controller: _descriptionController,
                maxLines: 5,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(14),
                  hintText: tr("Describe the job"),
                ),
              ),
            ),

            const SizedBox(height: 24),
            _requiredLabel(tr("Scheduled Dates")),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: _pickDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: navy.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _startDate != null
                                  ? (_endDate != null
                                      ? "${formatJobDate(_startDate!)} \u2192 ${formatJobDate(_endDate!)}"
                                      : formatJobDate(_startDate!))
                                  : tr("Select dates"),
                              style: TextStyle(
                                fontSize: 14,
                                color: _startDate != null ? Colors.black87 : Colors.black38,
                              ),
                            ),
                          ),
                          const Icon(Icons.calendar_today, size: 18, color: navy),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: _timeDropdown(
                    value: _hour,
                    items: hourOptions,
                    onChanged: (v) => setState(() => _hour = v!),
                  ),
                ),
                const SizedBox(width: 4),
                const Text(":", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 4),
                Expanded(
                  flex: 2,
                  child: _timeDropdown(
                    value: _minute,
                    items: minuteOptions,
                    onChanged: (v) => setState(() => _minute = v!),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
            _requiredLabel(tr("Location")),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _textField(
                    controller: _locationController,
                    hint: tr("Enter location"),
                    icon: Icons.location_on_outlined,
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: navy,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    onPressed: _openMaps,
                    icon: const Icon(Icons.map_outlined, color: Colors.white, size: 18),
                    label: Text(tr("Open\nMaps"), textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 11, height: 1.1)),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
            Text(
              tr("Engineer"),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: navy),
            ),
            const SizedBox(height: 10),
            _multiSelectCard(
              icon: Icons.engineering_outlined,
              hint: tr("Select engineer"),
              selected: _selectedEngineers,
              items: widget.engineers,
              onChanged: (v) => setState(() => _selectedEngineers = v),
              useCheckboxes: false,
            ),

            const SizedBox(height: 24),
            Text(
              tr("Action"),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: navy),
            ),
            const SizedBox(height: 10),
            _dropdownCard(
              icon: Icons.checklist_outlined,
              hint: tr("Select action"),
              value: _selectedAction,
              items: _availableActions,
              onChanged: (v) => setState(() {
                _selectedAction = v;
                // The task list depends on the action, so clear any task
                // that doesn't belong to the newly-selected action.
                if (!(actionTasks[v] ?? const []).contains(_selectedTask)) {
                  _selectedTask = null;
                }
              }),
            ),

            if ((actionTasks[_selectedAction] ?? const []).isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                tr("Task"),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: navy),
              ),
              const SizedBox(height: 10),
              _dropdownCard(
                icon: Icons.assignment_turned_in_outlined,
                hint: tr("Select task"),
                value: _selectedTask,
                items: actionTasks[_selectedAction]!,
                onChanged: (v) => setState(() => _selectedTask = v),
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          height: 58,
          decoration: BoxDecoration(
            color: navy,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.chevron_left, color: Colors.white),
                  label: Text(tr("Back"), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              Container(width: 1, height: 28, color: Colors.white24),
              Expanded(
                child: TextButton(
                  onPressed: _save,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(tr("Save"), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 6),
                      const Icon(Icons.check, color: Colors.white, size: 18),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _jobTypeOption({
    required String value,
    required IconData icon,
    required String label,
  }) {
    final selected = _jobType == value;
    void select() => setState(() {
          _jobType = value;
          if (_jobType != jobTypeService) {
            _selectedServiceSubType = null;
          } else if (_selectedServiceSubType == null) {
            _selectedServiceSubType = serviceSubTypeAfterService;
          }
          // The action list depends on Job Type — drop any action/task
          // that no longer belongs to the newly-selected type.
          if (!_availableActions.contains(_selectedAction)) {
            _selectedAction = null;
            _selectedTask = null;
          }
        });
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: select,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: selected ? navy.withValues(alpha: 0.08) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? navy : Colors.black12, width: selected ? 2 : 1),
        ),
        child: Column(
          children: [
            Icon(icon, color: navy, size: 26),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Radio<String>(
              value: value,
              groupValue: _jobType,
              activeColor: navy,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              onChanged: (_) => select(),
            ),
          ],
        ),
      ),
    );
  }

  /// Sub-choice shown under Job Type only when "Service" is selected —
  /// one bordered box containing both segments, with the active one
  /// highlighted inside it.
  Widget _serviceSubTypeSelector() {
  return Container(
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: navy.withValues(alpha: 0.4)),
    ),
    child: Row(
      children: [
        Expanded(child: _serviceSubTypeSegment(serviceSubTypeService)),
        const SizedBox(width: 4),
        Expanded(child: _serviceSubTypeSegment(serviceSubTypeAfterService)),
      ],
    ),
  );
}

  Widget _serviceSubTypeSegment(String value) {
    final selected = _selectedServiceSubType == value;
    return InkWell(
      borderRadius: BorderRadius.circular(11),
      onTap: () => setState(() => _selectedServiceSubType = value),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? navy : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Center(
          child: Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? Colors.white : Colors.black54,
            ),
          ),
        ),
      ),
    );
  }

  Widget _requiredLabel(String text) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: navy),
        children: [
          const TextSpan(text: "* ", style: TextStyle(color: Colors.red)),
          TextSpan(text: text),
        ],
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: navy.withValues(alpha: 0.4)),
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.black38, fontSize: 14),
          prefixIcon: Icon(icon, color: navy, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        ),
      ),
    );
  }

  Widget _simpleDropdown({
    required String? value,
    required String hint,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      height: 52,
      decoration: BoxDecoration(
        color: navy,
        borderRadius: BorderRadius.circular(14),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: value,
          itemHeight: 56,
          hint: Text(hint, style: const TextStyle(color: Colors.white70, fontSize: 14)),
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
          dropdownColor: Colors.white,
          style: const TextStyle(fontSize: 14, color: Colors.white),
          selectedItemBuilder: (context) => items
              .map((e) => Align(
                    alignment: Alignment.centerLeft,
                    child: Text(e, style: const TextStyle(color: Colors.white)),
                  ))
              .toList(),
          items: items
              .map((e) => DropdownMenuItem(
                    value: e,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(e, style: const TextStyle(color: Colors.black87)),
                    ),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _timeDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      height: 52,
      decoration: BoxDecoration(
        color: navy,
        borderRadius: BorderRadius.circular(14),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: value,
          itemHeight: 56,
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
          dropdownColor: Colors.white,
          style: const TextStyle(fontSize: 14, color: Colors.white),
          selectedItemBuilder: (context) => items
              .map((e) => Align(
                    alignment: Alignment.center,
                    child: Text(e, style: const TextStyle(color: Colors.white)),
                  ))
              .toList(),
          items: items
              .map((e) => DropdownMenuItem(
                    value: e,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(e, style: const TextStyle(color: Colors.black87)),
                    ),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  /// A field that looks like the other dropdown cards but opens a
  /// bottom sheet and lets more than one item be picked.
  /// Selected items are shown as chips inside the field itself.
  /// [useCheckboxes] controls the picker style: true (default) shows a
  /// checkbox per row (used for "Find items"); false shows plain rows
  /// that highlight navy when tapped, with no checkbox (used for engineer
  /// selection).
  Widget _multiSelectCard({
    required IconData icon,
    required String hint,
    required List<String> selected,
    required List<String> items,
    required ValueChanged<List<String>> onChanged,
    bool useCheckboxes = true,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => useCheckboxes
          ? _openMultiSelectSheet(
              title: hint,
              items: items,
              selected: selected,
              onChanged: onChanged,
            )
          : _openTapSelectSheet(
              title: hint,
              items: items,
              selected: selected,
              onChanged: onChanged,
            ),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 52),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: navy.withValues(alpha: 0.4)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, color: navy, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: selected.isEmpty
                  ? Text(hint, style: const TextStyle(color: Colors.black45, fontSize: 14))
                  : Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: selected
                          .map(
                            (e) => Chip(
                              label: Text(e, style: const TextStyle(fontSize: 12)),
                              backgroundColor: navy.withValues(alpha: 0.08),
                              visualDensity: VisualDensity.compact,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                            ),
                          )
                          .toList(),
                    ),
            ),
            const Icon(Icons.keyboard_arrow_down, color: Colors.black45),
          ],
        ),
      ),
    );
  }

  /// Bottom sheet with plain, tappable rows instead of checkboxes — tapping
  /// a row toggles its selection and highlights it navy, with a check icon
  /// on the right instead of a checkbox on the left. Same commit-on-"Done"
  /// behavior as [_openMultiSelectSheet] so backing out doesn't silently
  /// change anything. Used for engineer selection.
  Future<void> _openTapSelectSheet({
    required String title,
    required List<String> items,
    required List<String> selected,
    required ValueChanged<List<String>> onChanged,
  }) async {
    final tempSelected = List<String>.from(selected);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: navy),
                    ),
                    const Divider(height: 20),
                    Flexible(
                      child: ListView(
                        shrinkWrap: true,
                        children: items.map((item) {
                          final selectedNow = tempSelected.contains(item);
                          return InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => setSheetState(() {
                              if (selectedNow) {
                                tempSelected.remove(item);
                              } else {
                                tempSelected.add(item);
                              }
                            }),
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 3),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: selectedNow ? navy.withValues(alpha: 0.08) : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      item,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: selectedNow ? navy : Colors.black87,
                                        fontWeight: selectedNow ? FontWeight.w600 : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                  if (selectedNow) const Icon(Icons.check_rounded, color: navy, size: 20),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: navy,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        onPressed: () {
                          onChanged(tempSelected);
                          Navigator.pop(sheetContext);
                        },
                        child: Text(
                          tr("Done"),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Bottom sheet with a checkbox per item. Selections are only committed
  /// (via [onChanged]) when "Done" is tapped, so backing out doesn't
  /// silently change anything.
  Future<void> _openMultiSelectSheet({
    required String title,
    required List<String> items,
    required List<String> selected,
    required ValueChanged<List<String>> onChanged,
  }) async {
    final tempSelected = List<String>.from(selected);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: navy),
                    ),
                    const Divider(height: 20),
                    Flexible(
                      child: ListView(
                        shrinkWrap: true,
                        children: items.map((item) {
                          final checked = tempSelected.contains(item);
                          return CheckboxListTile(
                            value: checked,
                            title: Text(item, style: const TextStyle(fontSize: 14)),
                            activeColor: navy,
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: EdgeInsets.zero,
                            onChanged: (v) => setSheetState(() {
                              if (v == true) {
                                tempSelected.add(item);
                              } else {
                                tempSelected.remove(item);
                              }
                            }),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: navy,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        onPressed: () {
                          onChanged(tempSelected);
                          Navigator.pop(sheetContext);
                        },
                        child: Text(
                          tr("Done"),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _dropdownCard({
    required IconData icon,
    required String hint,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: navy.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(icon, color: navy, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: value,
                itemHeight: 56,
                hint: Text(hint, style: const TextStyle(color: Colors.black45, fontSize: 14)),
                icon: const Icon(Icons.keyboard_arrow_down),
                style: const TextStyle(fontSize: 14, color: Colors.black87),
                items: items
                    .map((e) => DropdownMenuItem(
                          value: e,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Text(e),
                          ),
                        ))
                    .toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}