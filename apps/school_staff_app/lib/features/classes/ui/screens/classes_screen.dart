
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

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      if (!mounted) return;

      final auth = ref.read(staffAuthControllerProvider);
      final schoolId = auth.schoolId.trim();

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

  Future<void> _editClass(BuildContext context, dynamic schoolClass) async {
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
        title: Text('${isActive ? 'Deactivate' : 'Activate'} class?'),
        content: Text(
          'Kya aap "${schoolClass.name}" class ko $action karna chahte hain?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
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

    // Agar account ka school ID change ho, to us school ki list reload karein.
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
      appBar: AppBar(
        title: const Text('Classes'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: state.isLoading ? null : () => _refresh(schoolId),
            icon: const Icon(Icons.refresh),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addClass(context, schoolId),
        icon: const Icon(Icons.add),
        label: const Text('Add Class'),
      ),
      body: RefreshIndicator(
        onRefresh: () => _refresh(schoolId),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'School classes',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Apne school ki classes manage karein.',
              style: TextStyle(color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 20),
            LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 520;

                final cards = [
                  ClassSummaryCard(
                    title: 'Total classes',
                    value: state.classes.length,
                    icon: Icons.class_rounded,
                    color: const Color(0xFF2563EB),
                  ),
                  ClassSummaryCard(
                    title: 'Active',
                    value: state.activeCount,
                    icon: Icons.check_circle_outline,
                    color: const Color(0xFF16A34A),
                  ),
                  ClassSummaryCard(
                    title: 'Inactive',
                    value: state.inactiveCount,
                    icon: Icons.pause_circle_outline,
                    color: const Color(0xFF64748B),
                  ),
                ];

                if (compact) {
                  return Column(
                    children: [
                      for (final card in cards) ...[
                        card,
                        const SizedBox(height: 10),
                      ],
                    ],
                  );
                }

                return Row(
                  children: [
                    for (var i = 0; i < cards.length; i++) ...[
                      Expanded(child: cards[i]),
                      if (i < cards.length - 1) const SizedBox(width: 12),
                    ],
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _searchController,
              onChanged: ref.read(classesControllerProvider.notifier).search,
              decoration: InputDecoration(
                hintText: 'Search classes...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _searchController.clear();
                          ref.read(classesControllerProvider.notifier).search('');
                        },
                        icon: const Icon(Icons.close),
                      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            if (state.errorMessage != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  state.errorMessage!,
                  style: const TextStyle(color: Color(0xFFB91C1C)),
                ),
              ),
            if (state.isLoading && state.classes.isEmpty)
              const Padding(
                padding: EdgeInsets.all(48),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (classes.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  children: [
                    const Icon(
                      Icons.class_outlined,
                      size: 54,
                      color: Color(0xFF94A3B8),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      state.searchQuery.isNotEmpty
                          ? 'Koi matching class nahi mili.'
                          : 'Abhi koi class add nahi ki gayi.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Add Class button se apni pehli class create karein.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              )
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 1050
                      ? 3
                      : constraints.maxWidth >= 650
                          ? 2
                          : 1;

                  final itemWidth =
                      (constraints.maxWidth - ((columns - 1) * 12)) / columns;

                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      for (final schoolClass in classes)
                        SizedBox(
                          width: itemWidth,
                          child: ClassCard(
                            schoolClass: schoolClass,
                            academicYearName: state.academicYears
                                .where((year) =>
                                    year.id == schoolClass.academicYearId)
                                .map((year) => year.name)
                                .firstOrNull ?? '',
                            onEdit: () => _editClass(context, schoolClass),
                            onToggleActive: () =>
                                _toggleClass(context, schoolClass),
                            onOpen: () {
                              final yearName = state.academicYears
                                  .where((year) =>
                                      year.id == schoolClass.academicYearId)
                                  .map((year) => year.name)
                                  .firstOrNull ?? '';

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
            const SizedBox(height: 88),
          ],
        ),
      ),
    );
  }
}
