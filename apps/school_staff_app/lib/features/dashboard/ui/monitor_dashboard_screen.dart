import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/logic/staff_auth_controller.dart';
import '../../classes/data/classes_repository.dart';
import '../../homework/ui/screens/monitor_homework_upload_screen.dart';

class MonitorDashboardScreen extends ConsumerStatefulWidget {
  const MonitorDashboardScreen({super.key});

  @override
  ConsumerState<MonitorDashboardScreen> createState() =>
      _MonitorDashboardScreenState();
}

class _MonitorDashboardScreenState
    extends ConsumerState<MonitorDashboardScreen> {
  static const Color _green = Color(0xFF138A4B);
  static const Color _darkGreen = Color(0xFF105C3B);
  static const Color _background = Color(0xFFF4F8F5);
  static const Color _border = Color(0xFFDDE9E1);
  static const Color _text = Color(0xFF202B25);
  static const Color _muted = Color(0xFF68766E);

  Future<String?>? _classNameFuture;
  String? _loadedSchoolId;
  String? _loadedClassId;
  bool _isLoggingOut = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadClassNameIfNeeded();
  }

  void _loadClassNameIfNeeded() {
    final profile = ref.read(staffAuthControllerProvider).profile;
    final schoolId = profile?['schoolId'] as String? ?? '';
    final classId = profile?['classId'] as String? ?? '';

    if (schoolId.isEmpty || classId.isEmpty) {
      _classNameFuture = null;
      _loadedSchoolId = schoolId;
      _loadedClassId = classId;
      return;
    }

    if (_classNameFuture != null &&
        _loadedSchoolId == schoolId &&
        _loadedClassId == classId) {
      return;
    }

    _loadedSchoolId = schoolId;
    _loadedClassId = classId;
    _classNameFuture = _fetchClassName(
      schoolId: schoolId,
      classId: classId,
    );
  }

  Future<String?> _fetchClassName({
    required String schoolId,
    required String classId,
  }) async {
    final repository = ref.read(classesRepositoryProvider);
    final classes = await repository.getClasses(schoolId);

    for (final schoolClass in classes) {
      if (schoolClass.id == classId) return schoolClass.name;
    }
    return null;
  }

  Future<void> _logout() async {
    if (_isLoggingOut) return;

    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        title: const Text('Log out?'),
        content: const Text(
          'Are you sure you want to log out of your monitor account?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: _green,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );

    if (shouldLogout != true || !mounted) return;
    setState(() => _isLoggingOut = true);

    try {
      await ref.read(staffAuthControllerProvider.notifier).signOut();
    } catch (error) {
      if (!mounted) return;
      setState(() => _isLoggingOut = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('Unable to log out: ${_cleanError(error)}'),
            backgroundColor: const Color(0xFFB42318),
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  String _cleanError(Object error) {
    return error.toString().replaceFirst('Exception: ', '').trim();
  }

  void _openHomeworkUpload() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const MonitorHomeworkUploadScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(staffAuthControllerProvider);
    final profile = authState.profile;

    // Refresh the class-name future when the signed-in profile becomes
    // available or its school/class assignment changes.
    _loadClassNameIfNeeded();

    final name = (profile?['name'] as String? ?? '').trim().isEmpty
        ? 'Monitor'
        : (profile?['name'] as String).trim();
    final schoolId = profile?['schoolId'] as String? ?? '';
    final classId = profile?['classId'] as String? ?? '';
    final sectionId = profile?['sectionId'] as String? ?? '';
    final sectionName = profile?['sectionName'] as String? ?? '';

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        title: const Text(
          'Monitor Dashboard',
          style: TextStyle(
            color: _darkGreen,
            fontWeight: FontWeight.w800,
            fontSize: 19,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: _darkGreen,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            tooltip: 'Log out',
            onPressed: _isLoggingOut ? null : _logout,
            icon: _isLoggingOut
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _green,
                    ),
                  )
                : const Icon(Icons.logout_rounded),
          ),
          const SizedBox(width: 8),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: _border),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding = constraints.maxWidth < 600 ? 16.0 : 26.0;
            final contentWidth = constraints.maxWidth >= 1200
                ? 1120.0
                : constraints.maxWidth;

            return Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: contentWidth,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    22,
                    horizontalPadding,
                    36,
                  ),
                  children: [
                    _buildWelcomeCard(name),
                    const SizedBox(height: 26),
                    _sectionHeading(
                      title: 'My Assigned Section',
                      subtitle: 'Your current class and section assignment',
                    ),
                    const SizedBox(height: 13),
                    _buildAssignmentCard(
                      schoolId: schoolId,
                      classId: classId,
                      sectionId: sectionId,
                      sectionName: sectionName,
                    ),
                    const SizedBox(height: 26),
                    _sectionHeading(
                      title: 'Homework Management',
                      subtitle: 'Create and publish work for your assigned students',
                    ),
                    const SizedBox(height: 13),
                    _buildHomeworkCard(),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(String name) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF168C50), Color(0xFF105C3B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: _darkGreen.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.waving_hand_rounded,
              color: Colors.white,
              size: 27,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Welcome, $name!',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Manage homework and view the details of your assigned section.',
            style: TextStyle(
              color: Colors.white,
              height: 1.55,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeading({
    required String title,
    required String subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: _darkGreen,
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          subtitle,
          style: const TextStyle(
            color: _muted,
            fontSize: 12,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildAssignmentCard({
    required String schoolId,
    required String classId,
    required String sectionId,
    required String sectionName,
  }) {
    final hasClassAssignment = schoolId.isNotEmpty && classId.isNotEmpty;
    final sectionDisplay = sectionName.trim().isNotEmpty
        ? sectionName.trim()
        : sectionId.isNotEmpty
            ? sectionId
            : 'Not assigned';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          _InfoRow(
            icon: Icons.school_outlined,
            label: 'Class',
            value: hasClassAssignment ? null : 'Not assigned',
            valueBuilder: hasClassAssignment
                ? (context) => FutureBuilder<String?>(
                      future: _classNameFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: _green,
                            ),
                          );
                        }

                        if (snapshot.hasError) {
                          return const Text(
                            'Unable to load class',
                            textAlign: TextAlign.end,
                            style: TextStyle(
                              color: _muted,
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        }

                        final className = snapshot.data;
                        return Text(
                          className == null || className.trim().isEmpty
                              ? 'Class not found'
                              : className,
                          textAlign: TextAlign.end,
                          style: const TextStyle(
                            color: _text,
                            fontWeight: FontWeight.w700,
                          ),
                        );
                      },
                    )
                : null,
          ),
          const Divider(height: 1, color: _border),
          _InfoRow(
            icon: Icons.groups_outlined,
            label: 'Section',
            value: sectionDisplay,
          ),
        ],
      ),
    );
  }

  Widget _buildHomeworkCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: _darkGreen.withValues(alpha: 0.025),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFE4F3E9),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.menu_book_rounded,
                  color: _green,
                  size: 26,
                ),
              ),
              const SizedBox(width: 13),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Upload Homework',
                      style: TextStyle(
                        color: _darkGreen,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Create homework instructions and set a due date for students in your assigned section.',
                      style: TextStyle(
                        color: _muted,
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _openHomeworkUpload,
              style: FilledButton.styleFrom(
                backgroundColor: _green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 15,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.upload_file_rounded, size: 20),
              label: const Text(
                'Upload Homework',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    this.value,
    this.valueBuilder,
  });

  final IconData icon;
  final String label;
  final String? value;
  final WidgetBuilder? valueBuilder;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: const Color(0xFF138A4B), size: 21),
          const SizedBox(width: 12),
          SizedBox(
            width: 76,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF68766E),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: valueBuilder != null
                ? Align(
                    alignment: Alignment.centerLeft,
                    child: valueBuilder!(context),
                  )
                : Text(
                    value ?? '',
                    textAlign: TextAlign.start,
                    softWrap: true,
                    style: const TextStyle(
                      color: Color(0xFF202B25),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
