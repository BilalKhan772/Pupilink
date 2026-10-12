
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/logic/staff_auth_controller.dart';
import '../../logic/classes_controller.dart';
import '../widgets/class_card.dart';
import '../widgets/class_summary_card.dart';
import 'add_class_screen.dart';
import 'class_overview_screen.dart';
import 'edit_class_screen.dart';

class ClassesScreen extends ConsumerStatefulWidget {
  const ClassesScreen({super.key});

  @override
  ConsumerState<ClassesScreen> createState() => _ClassesScreenState();
}

class _ClassesScreenState extends ConsumerState<ClassesScreen> {
  final _searchController = TextEditingController();
  String? _loadedSchoolId;

  static const Color _green = Color(0xFF15803D);
  static const Color _background = Color(0xFFF7F9F8);

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      if (!mounted) return;

      final schoolId =
          ref.read(staffAuthControllerProvider).schoolId.trim();

      if (schoolId.isNotEmpty) {
        _loadedSchoolId = schoolId;
        ref.read(classesControllerProvider.notifier).load(schoolId);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh(String schoolId) async {
    await ref.read(classesControllerProvider.notifier).load(schoolId);
  }

  Future<void> _addClass(
    BuildContext context,
    String schoolId,
  ) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => AddClassScreen(schoolId: schoolId),
      ),
    );

    if (result == true && mounted) {
      await _refresh(schoolId);
    }
  }

  Future<void> _editClass(
    BuildContext context,
    dynamic schoolClass,
  ) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => EditClassScreen(schoolClass: schoolClass),
      ),
    );

    if (result == true && mounted) {
      await _refresh(schoolClass.schoolId as String);
    }
  }

  Future<void> _toggleClass(
    BuildContext context,
    dynamic schoolClass,
  ) async {
    final isActive = schoolClass.isActive as bool;
    final action = isActive ? 'deactivate' : 'activate';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          '${isActive ? 'Deactivate' : 'Activate'} class?',
        ),
        content: Text(
          'Kya aap "${schoolClass.name}" class ko $action karna chahte hain?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: _green,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(isActive ? 'Deactivate' : 'Activate'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final controller = ref.read(classesControllerProvider.notifier);
    final success = await controller.setActive(schoolClass, !isActive);

    if (!mounted) return;

    final state = ref.read(classesControllerProvider);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(
          success
              ? 'Class ${isActive ? 'deactivated' : 'activated'} successfully.'
              : state.errorMessage ?? 'Class update nahi ho saki.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(staffAuthControllerProvider);
    final state = ref.watch(classesControllerProvider);
    final schoolId = auth.schoolId.trim();

    if (!auth.isLoggedIn || schoolId.isEmpty) {
      return Scaffold(
        backgroundColor: _background,
        appBar: AppBar(title: const Text('Classes')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'School profile ya School ID nahi mili. Please dobara login karein.',
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
          ref.read(classesControllerProvider.notifier).load(schoolId);
        }
      });
    }

    final classes = state.filteredClasses;

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 20,
        title: const Text(
          'Classes',
          style: TextStyle(
            color: Color(0xFF172B24),
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh classes',
            onPressed: state.isLoading ? null : () => _refresh(schoolId),
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 8),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFE8EEEA)),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addClass(context, schoolId),
        backgroundColor: _green,
        foregroundColor: Colors.white,
        elevation: 3,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Add Class',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: RefreshIndicator(
        color: _green,
        onRefresh: () => _refresh(schoolId),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
          children: [
            const Text(
              'School classes',
              style: TextStyle(
                fontSize: 26,
                height: 1.2,
                fontWeight: FontWeight.w800,
                color: Color(0xFF172B24),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Manage your classes and academic years in one place.',
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 24),

            // Summary cards
            LayoutBuilder(
              builder: (context, constraints) {
                final cards = [
                  ClassSummaryCard(
                    title: 'Total classes',
                    value: state.classes.length,
                    icon: Icons.menu_book_rounded,
                    color: const Color(0xFF15803D),
                  ),
                  ClassSummaryCard(
                    title: 'Active classes',
                    value: state.activeCount,
                    icon: Icons.check_circle_outline_rounded,
                    color: const Color(0xFF16A34A),
                  ),
                  ClassSummaryCard(
                    title: 'Inactive classes',
                    value: state.inactiveCount,
                    icon: Icons.pause_circle_outline_rounded,
                    color: const Color(0xFF64748B),
                  ),
                ];

                final columns = constraints.maxWidth >= 1000
                    ? 3
                    : constraints.maxWidth >= 600
                        ? 2
                        : 1;

                if (columns == 1) {
                  return Column(
                    children: [
                      for (var i = 0; i < cards.length; i++) ...[
                        cards[i],
                        if (i < cards.length - 1)
                          const SizedBox(height: 12),
                      ],
                    ],
                  );
                }

                final itemWidth =
                    (constraints.maxWidth - (columns - 1) * 12) / columns;

                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final card in cards)
                      SizedBox(
                        width: itemWidth,
                        child: card,
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 28),

            // Search heading
            const Text(
              'All classes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF172B24),
              ),
            ),
            const SizedBox(height: 12),

            // Search field
            TextField(
              controller: _searchController,
              onChanged: ref.read(classesControllerProvider.notifier).search,
              decoration: InputDecoration(
                hintText: 'Search classes...',
                hintStyle: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 14,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: _green,
                ),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        onPressed: () {
                          _searchController.clear();
                          ref
                              .read(classesControllerProvider.notifier)
                              .search('');
                          setState(() {});
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(
                    color: Color(0xFFE2E8F0),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(
                    color: Color(0xFFE2E8F0),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(
                    color: _green,
                    width: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Error message
            if (state.errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFFFECACA),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: Color(0xFFB91C1C),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        state.errorMessage!,
                        style: const TextStyle(
                          color: Color(0xFFB91C1C),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Loading state
            if (state.isLoading && state.classes.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 56),
                child: Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(color: _green),
                      SizedBox(height: 16),
                      Text(
                        'Loading classes...',
                        style: TextStyle(color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
              )

            // Empty state
            else if (classes.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 36,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 68,
                      height: 68,
                      decoration: const BoxDecoration(
                        color: Color(0xFFDCFCE7),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.menu_book_rounded,
                        size: 32,
                        color: _green,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      state.searchQuery.isNotEmpty
                          ? 'No matching classes'
                          : 'No classes yet',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF172B24),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.searchQuery.isNotEmpty
                          ? 'Try another search term.'
                          : 'Create your first class using the Add Class button.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    if (state.searchQuery.isEmpty) ...[
                      const SizedBox(height: 18),
                      OutlinedButton.icon(
                        onPressed: () => _addClass(context, schoolId),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Create first class'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _green,
                          side: const BorderSide(color: _green),
                        ),
                      ),
                    ],
                  ],
                ),
              )

            // Classes grid
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 1050
                      ? 3
                      : constraints.maxWidth >= 650
                          ? 2
                          : 1;

                  final itemWidth =
                      (constraints.maxWidth - (columns - 1) * 14) / columns;

                  return Wrap(
                    spacing: 14,
                    runSpacing: 14,
                    children: [
                      for (final schoolClass in classes)
                        SizedBox(
                          width: itemWidth,
                          child: ClassCard(
                            schoolClass: schoolClass,
                            academicYearName: state.academicYears
                                    .where(
                                      (year) =>
                                          year.id ==
                                          schoolClass.academicYearId,
                                    )
                                    .map((year) => year.name)
                                    .firstOrNull ??
                                '',
                            onEdit: () =>
                                _editClass(context, schoolClass),
                            onToggleActive: () =>
                                _toggleClass(context, schoolClass),
                            onOpen: () {
                              final yearName = state.academicYears
                                      .where(
                                        (year) =>
                                            year.id ==
                                            schoolClass.academicYearId,
                                      )
                                      .map((year) => year.name)
                                      .firstOrNull ??
                                  '';

                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => ClassOverviewScreen(
                                    schoolClass: schoolClass,
                                    academicYearName: yearName,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
