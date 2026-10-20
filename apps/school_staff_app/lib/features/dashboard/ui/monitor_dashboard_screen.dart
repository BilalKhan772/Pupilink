
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
  static const Color _background = Color(0xFFF7F9F7);

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
    final classes = await ref
        .read(classesRepositoryProvider)
        .getClasses(schoolId);

    for (final schoolClass in classes) {
      if (schoolClass.id == classId) {
        return schoolClass.name;
      }
    }

    return null;
  }

  Future<void> _logout() async {
    if (_isLoggingOut) return;

    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Logout'),
        content: const Text(
          'Kya aap waqai apne account se logout karna chahte hain?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Logout'),
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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Logout nahi ho saka: ${error.toString().replaceFirst('Exception: ', '')}',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
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

    final name = profile?['name'] as String? ?? 'Monitor';
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
          ),
        ),
        backgroundColor: _background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Logout',
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
                : const Icon(
                    Icons.logout_rounded,
                    color: _green,
                  ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF138A4B),
                    Color(0xFF105C3B),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.waving_hand_rounded,
                    color: Colors.white,
                    size: 34,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Welcome, $name!',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 23,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Yahan aap apne assigned section ke liye '
                    'school information dekh sakte hain.',
                    style: TextStyle(
                      color: Colors.white,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              'My Assigned Section',
              style: TextStyle(
                color: _darkGreen,
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: const Color(0xFFE4ECE6),
                ),
              ),
              child: Column(
                children: [
                  _InfoRow(
                    icon: Icons.class_outlined,
                    label: 'Class',
                    value: schoolId.isEmpty || classId.isEmpty
                        ? 'Not assigned'
                        : null,
                    valueBuilder: schoolId.isEmpty || classId.isEmpty
                        ? null
                        : (context) => FutureBuilder<String?>(
                              future: _classNameFuture,
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
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
                                    'Class load nahi hui',
                                    textAlign: TextAlign.end,
                                    style: TextStyle(
                                      color: _darkGreen,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  );
                                }

                                final className = snapshot.data;

                                return Text(
                                  className == null || className.isEmpty
                                      ? 'Class not found'
                                      : className,
                                  textAlign: TextAlign.end,
                                  style: const TextStyle(
                                    color: Color(0xFF172B24),
                                    fontWeight: FontWeight.w700,
                                  ),
                                );
                              },
                            ),
                  ),
                  const Divider(height: 24),
                  _InfoRow(
                    icon: Icons.groups_outlined,
                    label: 'Section',
                    value: sectionName.isNotEmpty
                        ? sectionName
                        : sectionId.isNotEmpty
                            ? sectionId
                            : 'Not assigned',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              'Homework Management',
              style: TextStyle(
                color: _darkGreen,
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: const Color(0xFFE4ECE6),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.menu_book_rounded,
                        color: _green,
                        size: 28,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Upload Homework',
                          style: TextStyle(
                            color: _darkGreen,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Apni assigned section ke students ke liye '
                    'homework, subject, instructions aur due date '
                    'set karein.',
                    style: TextStyle(
                      color: Color(0xFF758078),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _openHomeworkUpload,
                      style: FilledButton.styleFrom(
                        backgroundColor: _green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.upload_file_rounded),
                      label: const Text(
                        'Upload Homework',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
    return Row(
      children: [
        Icon(
          icon,
          color: const Color(0xFF138A4B),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF758078),
            ),
          ),
        ),
        Flexible(
          child: valueBuilder != null
              ? valueBuilder!(context)
              : Text(
                  value ?? '',
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                    color: Color(0xFF172B24),
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
      ],
    );
  }
}
