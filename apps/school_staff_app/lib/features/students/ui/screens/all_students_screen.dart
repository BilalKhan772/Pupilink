
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/logic/staff_auth_controller.dart';
import '../../logic/students_controller.dart';
import 'add_student_screen.dart';
import 'edit_student_screen.dart';
import 'student_overview_screen.dart';
import 'student_search_screen.dart';

class AllStudentsScreen extends ConsumerStatefulWidget {
  const AllStudentsScreen({
    super.key,
    this.sectionId,
    this.sectionName,
    this.className,
  });

  /// Null ya empty ho to school ke tamam students show honge.
  /// Value ho to sirf selected section ke students show honge.
  final String? sectionId;
  final String? sectionName;
  final String? className;

  bool get isSectionFiltered =>
      sectionId != null && sectionId!.trim().isNotEmpty;

  @override
  ConsumerState<AllStudentsScreen> createState() =>
      _AllStudentsScreenState();
}

class _AllStudentsScreenState extends ConsumerState<AllStudentsScreen> {
  final TextEditingController _searchController = TextEditingController();

  String? _loadedSchoolId;

  static const Color _green = Color(0xFF087F46);
  static const Color _lightGreen = Color(0xFFEAF5EF);
  static const Color _pageBackground = Color(0xFFF7FAF8);
  static const Color _textColor = Color(0xFF172B25);
  static const Color _mutedColor = Color(0xFF7A8581);
  static const Color _borderColor = Color(0xFFE7EEEA);

  String? get _sectionId {
    final value = widget.sectionId?.trim();
    return value == null || value.isEmpty ? null : value;
  }

  String get _pageTitle {
    if (widget.isSectionFiltered) {
      final section = widget.sectionName?.trim();

      if (section != null && section.isNotEmpty) {
        return 'Section $section Students';
      }

      return 'Section Students';
    }

    return 'All Students';
  }

  String get _directoryTitle {
    if (widget.isSectionFiltered) {
      final section = widget.sectionName?.trim() ?? '';
      final className = widget.className?.trim() ?? '';

      if (className.isNotEmpty && section.isNotEmpty) {
        return 'Class $className • Section $section';
      }

      if (section.isNotEmpty) {
        return 'Students of Section $section';
      }

      return 'Section Student Directory';
    }

    return 'Student Directory';
  }

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      if (!mounted) return;

      final schoolId =
          ref.read(staffAuthControllerProvider).schoolId.trim();

      if (schoolId.isNotEmpty) {
        _loadedSchoolId = schoolId;
        _refresh(schoolId);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Selected section ka ID pass hoga to list section-filtered hogi.
  /// Section ID null ho to existing school-wide list load hogi.
  Future<void> _refresh(String schoolId) async {
    await ref.read(studentsControllerProvider.notifier).load(
          schoolId,
          sectionId: _sectionId,
        );
  }

  Future<void> _add(String schoolId) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const AddStudentScreen(),
      ),
    );

    if (result == true && mounted) {
      await _refresh(schoolId);
    }
  }

  Future<void> _edit(dynamic student, String schoolId) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => EditStudentScreen(student: student),
      ),
    );

    if (result == true && mounted) {
      await _refresh(schoolId);
    }
  }

  Future<void> _toggle(dynamic student, String schoolId) async {
    final bool nextActive = !student.isActive;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          nextActive ? 'Activate student?' : 'Deactivate student?',
        ),
        content: Text(
          'Kya aap "${student.name}" ka status change karna chahte hain?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final success = await ref
        .read(studentsControllerProvider.notifier)
        .setActive(student, nextActive);

    if (!mounted) return;

    // Controller status update ke baad school-wide data load karta hai.
    // Is refresh se selected section ka filter dobara apply hoga.
    if (success) {
      await _refresh(schoolId);
    }

    if (!mounted) return;

    final error = ref.read(studentsControllerProvider).errorMessage;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Student status update ho gaya.'
              : error ?? 'Student status update nahi ho saka.',
        ),
      ),
    );
  }

  void _clearSearch() {
    _searchController.clear();
    ref.read(studentsControllerProvider.notifier).search('');
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(staffAuthControllerProvider);
    final state = ref.watch(studentsControllerProvider);
    final schoolId = auth.schoolId.trim();

    if (!auth.isLoggedIn || schoolId.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(_pageTitle)),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'School profile ya School ID nahi mili. '
              'Please dobara login karein.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    if (_loadedSchoolId != schoolId) {
      _loadedSchoolId = schoolId;

      Future.microtask(() {
        if (mounted) {
          _refresh(schoolId);
        }
      });
    }

    final students = state.filteredStudents;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isCompact = screenWidth < 650;

    return Scaffold(
      backgroundColor: _pageBackground,
      appBar: AppBar(
        backgroundColor: _pageBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back, color: _green),
        ),
        title: Text(
          _pageTitle,
          style: const TextStyle(
            color: _green,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Search by admission number',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const StudentSearchScreen(),
                ),
              );
            },
            icon: const Icon(Icons.manage_search),
          ),
          IconButton(
            tooltip: 'Refresh students',
            onPressed: state.isLoading ? null : () => _refresh(schoolId),
            icon: const Icon(Icons.refresh),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: state.isSaving ? null : () => _add(schoolId),
        backgroundColor: _green,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text(
          'Add Student',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => _refresh(schoolId),
        color: _green,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 12 : 28,
            vertical: 20,
          ),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1450),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(isCompact: isCompact),
                    const SizedBox(height: 22),

                    // Search field existing position par hi rakha gaya hai.
                    _buildSearchField(),
                    const SizedBox(height: 18),

                    if (state.errorMessage != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF1F0),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFFFD6D2),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: Colors.red,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                state.errorMessage!,
                                style: const TextStyle(
                                  color: Color(0xFFB42318),
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Retry',
                              onPressed: () => _refresh(schoolId),
                              icon: const Icon(Icons.refresh),
                            ),
                          ],
                        ),
                      ),

                    if (state.isLoading && state.students.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(56),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: _green,
                          ),
                        ),
                      )
                    else if (students.isEmpty)
                      _buildEmptyState()
                    else ...[
                      _buildListHeading(students.length),
                      const SizedBox(height: 10),
                      for (int i = 0; i < students.length; i++) ...[
                        _StudentListTile(
                          student: students[i],
                          serialNumber: i + 1,
                          compact: isCompact,
                          onOpen: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => StudentOverviewScreen(
                                  student: students[i],
                                ),
                              ),
                            );
                          },
                          onEdit: () => _edit(students[i], schoolId),
                          onToggleActive: () =>
                              _toggle(students[i], schoolId),
                        ),
                        const SizedBox(height: 10),
                      ],
                      const SizedBox(height: 12),
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: _borderColor),
                          ),
                          child: Text(
                            'Total Students: ${students.length}',
                            style: const TextStyle(
                              color: _mutedColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 90),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader({required bool isCompact}) {
    return Container(
      padding: EdgeInsets.all(isCompact ? 16 : 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFF0F8F3),
            Color(0xFFE5F3EA),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDCEDE2)),
      ),
      child: isCompact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _directoryTitle,
                  style: const TextStyle(
                    color: _green,
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.isSectionFiltered
                      ? 'Is section ke students dekhein aur manage karein.'
                      : 'Apne school ke students dekhein aur manage karein.',
                  style: const TextStyle(
                    color: Color(0xFF65756C),
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 14),
                _studentCountChip(),
              ],
            )
          : Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(17),
                  ),
                  child: const Icon(
                    Icons.school_outlined,
                    color: _green,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _directoryTitle,
                        style: const TextStyle(
                          color: _green,
                          fontSize: 27,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        widget.isSectionFiltered
                            ? 'Is section ke students dekhein aur manage karein.'
                            : 'Apne school ke students dekhein aur manage karein.',
                        style: const TextStyle(
                          color: Color(0xFF65756C),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _studentCountChip(),
              ],
            ),
    );
  }

  Widget _studentCountChip() {
    final count = ref.watch(studentsControllerProvider).students.length;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDCEDE2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.groups_outlined,
            color: _green,
            size: 19,
          ),
          const SizedBox(width: 8),
          Text(
            '$count students',
            style: const TextStyle(
              color: _green,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      onChanged: (query) {
        ref.read(studentsControllerProvider.notifier).search(query);
        setState(() {});
      },
      decoration: InputDecoration(
        hintText: 'Name, admission number, class...',
        hintStyle: const TextStyle(color: _mutedColor),
        prefixIcon: const Icon(Icons.search, color: _green),
        suffixIcon: _searchController.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Clear search',
                onPressed: _clearSearch,
                icon: const Icon(Icons.close),
              ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 17,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: _borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: _borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: _green, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildListHeading(int visibleCount) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 4),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Students',
              style: TextStyle(
                color: _textColor,
                fontSize: 19,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            '$visibleCount shown',
            style: const TextStyle(
              color: _mutedColor,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final hasSearch = _searchController.text.trim().isNotEmpty;

    final title = hasSearch
        ? 'No matching students'
        : widget.isSectionFiltered
            ? 'No students in this section'
            : 'No students found';

    final message = hasSearch
        ? 'Search text change karein ya clear kar dein.'
        : widget.isSectionFiltered
            ? 'Is section mein abhi koi student nahi hai. '
                'Add Student par click karke student add karein.'
            : 'Add Student par click karke naya student add karein.';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 45,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        children: [
          Container(
            width: 66,
            height: 66,
            decoration: const BoxDecoration(
              color: _lightGreen,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_search_outlined,
              color: _green,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _textColor,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _mutedColor,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _StudentListTile extends StatelessWidget {
  const _StudentListTile({
    required this.student,
    required this.serialNumber,
    required this.compact,
    required this.onOpen,
    required this.onEdit,
    required this.onToggleActive,
  });

  final dynamic student;
  final int serialNumber;
  final bool compact;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onToggleActive;

  static const Color _green = Color(0xFF087F46);
  static const Color _lightGreen = Color(0xFFEAF5EF);
  static const Color _borderColor = Color(0xFFE7EEEA);
  static const Color _textColor = Color(0xFF172B25);
  static const Color _mutedColor = Color(0xFF7A8581);

  @override
  Widget build(BuildContext context) {
    final name = (student.name as String?)?.trim() ?? '';
    final admissionNumber =
        (student.admissionNumber as String?)?.trim() ?? '';
    final className = (student.className as String?)?.trim() ?? '';
    final section = (student.section as String?)?.trim() ?? '';
    final isActive = student.isActive == true;
    final serial = serialNumber.toString().padLeft(2, '0');

    final details = [
      if (className.isNotEmpty) 'Class $className',
      if (section.isNotEmpty) 'Section $section',
    ].join('  •  ');

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(17),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 12 : 20,
            vertical: compact ? 14 : 17,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: _borderColor),
          ),
          child: Row(
            children: [
              Container(
                width: compact ? 45 : 54,
                height: compact ? 45 : 54,
                decoration: const BoxDecoration(
                  color: _lightGreen,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_outline,
                  color: _green,
                  size: 29,
                ),
              ),
              SizedBox(width: compact ? 9 : 16),
              Container(
                width: compact ? 36 : 46,
                height: compact ? 36 : 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _lightGreen,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Text(
                  serial,
                  style: TextStyle(
                    color: _green,
                    fontWeight: FontWeight.w700,
                    fontSize: compact ? 13 : 17,
                  ),
                ),
              ),
              SizedBox(width: compact ? 10 : 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.isEmpty ? 'Unnamed Student' : name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _textColor,
                        fontSize: compact ? 15 : 19,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 7),
                    if (admissionNumber.isNotEmpty)
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 5,
                        runSpacing: 4,
                        children: [
                          const Text(
                            'Admission No.',
                            style: TextStyle(
                              color: _mutedColor,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            admissionNumber,
                            style: const TextStyle(
                              color: _green,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    if (details.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        details,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _mutedColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: isActive
                                ? const Color(0xFF16A34A)
                                : const Color(0xFF9CA3AF),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isActive ? 'Active' : 'Inactive',
                          style: TextStyle(
                            color: isActive
                                ? const Color(0xFF168044)
                                : _mutedColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 5),
              IconButton(
                tooltip: 'Edit student',
                onPressed: onEdit,
                visualDensity: VisualDensity.compact,
                icon: const Icon(
                  Icons.edit_outlined,
                  color: _green,
                  size: 23,
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'More options',
                onSelected: (value) {
                  if (value == 'status') onToggleActive();
                },
                itemBuilder: (context) => [
                  PopupMenuItem<String>(
                    value: 'status',
                    child: Row(
                      children: [
                        Icon(
                          isActive
                              ? Icons.pause_circle_outline
                              : Icons.check_circle_outline,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Text(isActive ? 'Deactivate' : 'Activate'),
                      ],
                    ),
                  ),
                ],
                icon: const Icon(
                  Icons.more_vert,
                  color: _mutedColor,
                  size: 22,
                ),
              ),
              IconButton(
                tooltip: 'View student details',
                onPressed: onOpen,
                visualDensity: VisualDensity.compact,
                icon: const Icon(
                  Icons.chevron_right,
                  color: _mutedColor,
                  size: 26,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
