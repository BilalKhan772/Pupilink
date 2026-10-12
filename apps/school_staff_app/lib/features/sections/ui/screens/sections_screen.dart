
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_models/school_models.dart';

import '../../../auth/logic/staff_auth_controller.dart';
import '../../logic/sections_controller.dart';
import '../../logic/sections_state.dart';
import '../widgets/section_card.dart';
import '../widgets/section_summary_card.dart';
import 'add_section_screen.dart';
import 'edit_section_screen.dart';
import 'section_details_screen.dart';

class SectionsScreen extends ConsumerStatefulWidget {
  const SectionsScreen({super.key});

  @override
  ConsumerState<SectionsScreen> createState() => _SectionsScreenState();
}

class _SectionsScreenState extends ConsumerState<SectionsScreen> {
  final _searchController = TextEditingController();
  String? _loadedSchoolId;

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      if (!mounted) return;

      final schoolId =
          ref.read(staffAuthControllerProvider).schoolId.trim();

      if (schoolId.isNotEmpty) {
        _loadedSchoolId = schoolId;
        ref.read(sectionsControllerProvider.notifier).load(schoolId);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh(String schoolId) async {
    await ref.read(sectionsControllerProvider.notifier).load(schoolId);
  }

  String _className(SectionsState state, String classId) {
    for (final schoolClass in state.classes) {
      if (schoolClass.id == classId) return schoolClass.name;
    }
    return '';
  }

  Future<void> _addSection(String schoolId) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => AddSectionScreen(schoolId: schoolId),
      ),
    );

    if (result == true && mounted) {
      await _refresh(schoolId);
    }
  }

  Future<void> _editSection(SchoolSection section) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => EditSectionScreen(section: section),
      ),
    );

    if (result == true && mounted) {
      final schoolId =
          ref.read(staffAuthControllerProvider).schoolId.trim();
      if (schoolId.isNotEmpty) await _refresh(schoolId);
    }
  }

  Future<void> _toggleSection(SchoolSection section) async {
    final activate = !section.isActive;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(activate ? 'Activate section?' : 'Deactivate section?'),
        content: Text(
          'Kya aap "${section.name}" section ko '
          '${activate ? 'activate' : 'deactivate'} karna chahte hain?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(activate ? 'Activate' : 'Deactivate'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final success = await ref
        .read(sectionsControllerProvider.notifier)
        .setActive(section, activate);

    if (!mounted) return;

    final state = ref.read(sectionsControllerProvider);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Section ${activate ? 'activated' : 'deactivated'} successfully.'
              : state.errorMessage ?? 'Section update nahi ho saka.',
        ),
      ),
    );
  }

  Future<void> _openDetails(
    SchoolSection section,
    String className,
  ) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => SectionDetailsScreen(
          section: section,
          className: className,
          onEdit: () {
            Navigator.of(context).pop();
            _editSection(section);
          },
          onToggleActive: () {
            Navigator.of(context).pop();
            _toggleSection(section);
          },
        ),
      ),
    );

    if (result == true && mounted) {
      final schoolId =
          ref.read(staffAuthControllerProvider).schoolId.trim();
      if (schoolId.isNotEmpty) await _refresh(schoolId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(staffAuthControllerProvider);
    final SectionsState state = ref.watch(sectionsControllerProvider);
    final schoolId = auth.schoolId.trim();

    if (!auth.isLoggedIn || schoolId.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Sections')),
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
          ref.read(sectionsControllerProvider.notifier).load(schoolId);
        }
      });
    }

    final sections = state.filteredSections;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sections'),
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
        onPressed: state.isSaving || state.classes.isEmpty
            ? null
            : () => _addSection(schoolId),
        icon: const Icon(Icons.add),
        label: const Text('Add Section'),
      ),
      body: RefreshIndicator(
        onRefresh: () => _refresh(schoolId),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'School sections',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Apni classes ke sections manage karein.',
              style: TextStyle(color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 20),
            LayoutBuilder(
              builder: (context, constraints) {
                final cards = [
                  const SectionSummaryCard(
                    title: 'Total sections',
                    value: 0,
                    icon: Icons.meeting_room_outlined,
                    color: Color(0xFF2563EB),
                  ),
                  SectionSummaryCard(
                    title: 'Active',
                    value: state.activeCount,
                    icon: Icons.check_circle_outline,
                    color: const Color(0xFF16A34A),
                  ),
                  SectionSummaryCard(
                    title: 'Inactive',
                    value: state.inactiveCount,
                    icon: Icons.pause_circle_outline,
                    color: const Color(0xFF64748B),
                  ),
                ];

                final actualCards = [
                  SectionSummaryCard(
                    title: 'Total sections',
                    value: state.sections.length,
                    icon: Icons.meeting_room_outlined,
                    color: const Color(0xFF2563EB),
                  ),
                  cards[1],
                  cards[2],
                ];

                if (constraints.maxWidth < 520) {
                  return Column(
                    children: [
                      for (final card in actualCards) ...[
                        card,
                        const SizedBox(height: 10),
                      ],
                    ],
                  );
                }

                return Row(
                  children: [
                    for (var i = 0; i < actualCards.length; i++) ...[
                      Expanded(child: actualCards[i]),
                      if (i < actualCards.length - 1)
                        const SizedBox(width: 12),
                    ],
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _searchController,
              onChanged: ref.read(sectionsControllerProvider.notifier).search,
              decoration: InputDecoration(
                hintText: 'Search sections or classes...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _searchController.clear();
                          ref
                              .read(sectionsControllerProvider.notifier)
                              .search('');
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
            if (state.isLoading && state.sections.isEmpty)
              const Padding(
                padding: EdgeInsets.all(48),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (sections.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  children: [
                    const Icon(
                      Icons.meeting_room_outlined,
                      size: 54,
                      color: Color(0xFF94A3B8),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      state.searchQuery.isNotEmpty
                          ? 'Koi matching section nahi mila.'
                          : 'Abhi koi section add nahi kiya gaya.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Add Section button se pehla section create karein.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF64748B)),
                    ),
                    if (state.classes.isEmpty) ...[
                      const SizedBox(height: 8),
                      const Text(
                        'Pehle Classes module mein active class create karein.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Color(0xFF64748B)),
                      ),
                    ],
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
                      (constraints.maxWidth - ((columns - 1) * 12)) /
                          columns;

                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      for (final section in sections)
                        SizedBox(
                          width: itemWidth,
                          child: SectionCard(
                            section: section,
                            className: _className(state, section.classId),
                            onEdit: () => _editSection(section),
                            onToggleActive: () => _toggleSection(section),
                            onOpen: () => _openDetails(
                              section,
                              _className(state, section.classId),
                            ),
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
