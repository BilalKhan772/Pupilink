
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_models/school_models.dart';

import '../../../sections/logic/sections_controller.dart';
import '../../../sections/logic/sections_state.dart';
import '../../../sections/ui/screens/add_section_screen.dart';
import '../../../sections/ui/screens/edit_section_screen.dart';
import '../../../sections/ui/screens/section_details_screen.dart';

class ClassOverviewScreen extends ConsumerStatefulWidget {
  const ClassOverviewScreen({
    super.key,
    required this.schoolClass,
    required this.academicYearName,
  });

  final SchoolClass schoolClass;
  final String academicYearName;

  @override
  ConsumerState<ClassOverviewScreen> createState() =>
      _ClassOverviewScreenState();
}

class _ClassOverviewScreenState
    extends ConsumerState<ClassOverviewScreen> {
  static const Color _green = Color(0xFF15803D);
  static const Color _dark = Color(0xFF172B24);
  static const Color _muted = Color(0xFF64748B);
  static const Color _background = Color(0xFFF7F9F8);

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      if (!mounted) return;

      ref
          .read(sectionsControllerProvider.notifier)
          .load(widget.schoolClass.schoolId);
    });
  }

  Future<void> _refreshSections() async {
    await ref
        .read(sectionsControllerProvider.notifier)
        .load(widget.schoolClass.schoolId);
  }

  Future<void> _addSection() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => AddSectionScreen(
          schoolId: widget.schoolClass.schoolId,
        ),
      ),
    );

    if (result == true && mounted) {
      await _refreshSections();
    }
  }

  Future<void> _editSection(SchoolSection section) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => EditSectionScreen(section: section),
      ),
    );

    if (result == true && mounted) {
      await _refreshSections();
    }
  }

  Future<void> _toggleSection(SchoolSection section) async {
    final activate = !section.isActive;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        title: Text(
          activate ? 'Activate section?' : 'Deactivate section?',
        ),
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
            style: FilledButton.styleFrom(
              backgroundColor: _green,
            ),
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
        behavior: SnackBarBehavior.floating,
        content: Text(
          success
              ? 'Section ${activate ? 'activated' : 'deactivated'} successfully.'
              : state.errorMessage ?? 'Section update nahi ho saka.',
        ),
      ),
    );
  }

  Future<void> _openSection(SchoolSection section) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => SectionDetailsScreen(
          section: section,
          className: widget.schoolClass.name,
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
      await _refreshSections();
    }
  }

  @override
  Widget build(BuildContext context) {
    final SectionsState state = ref.watch(sectionsControllerProvider);

    final sections = state.sections
        .where(
          (section) =>
              section.schoolId == widget.schoolClass.schoolId &&
              section.classId == widget.schoolClass.id,
        )
        .toList()
      ..sort(
        (a, b) => a.name.toLowerCase().compareTo(
              b.name.toLowerCase(),
            ),
      );

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          widget.schoolClass.name,
          style: const TextStyle(
            color: _dark,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh sections',
            onPressed: state.isLoading ? null : _refreshSections,
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 8),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(
            height: 1,
            color: Color(0xFFE8EEEA),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: state.isSaving ? null : _addSection,
        backgroundColor: _green,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Add Section',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: RefreshIndicator(
        color: _green,
        onRefresh: _refreshSections,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
          children: [
            // Simple class heading
            const Text(
              'Sections',
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.w800,
                color: _dark,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              'Manage sections for ${widget.schoolClass.name}.',
              style: const TextStyle(
                fontSize: 14,
                color: _muted,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),

            // Small class information card
            Container(
              padding: const EdgeInsets.all(17),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(
                      Icons.school_rounded,
                      color: _green,
                      size: 25,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      widget.schoolClass.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: _dark,
                      ),
                    ),
                  ),
                  _StatusBadge(
                    active: widget.schoolClass.isActive,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 26),

            // Sections heading
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'All Sections',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: _dark,
                    ),
                  ),
                ),
                Text(
                  '${sections.length} total',
                  style: const TextStyle(
                    fontSize: 13,
                    color: _muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),
            const Text(
              'Select a section to view its details.',
              style: TextStyle(
                fontSize: 13,
                color: _muted,
              ),
            ),
            const SizedBox(height: 18),

            // Error message
            if (state.errorMessage != null)
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFFECACA),
                  ),
                ),
                child: Text(
                  state.errorMessage!,
                  style: const TextStyle(
                    color: Color(0xFFB91C1C),
                  ),
                ),
              ),

            // Loading
            if (state.isLoading && state.sections.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 45),
                child: Center(
                  child: CircularProgressIndicator(
                    color: _green,
                  ),
                ),
              )

            // Empty state
            else if (sections.isEmpty)
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFE2E8F0),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(
                        color: Color(0xFFDCFCE7),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.meeting_room_outlined,
                        size: 30,
                        color: _green,
                      ),
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      'No sections yet',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: _dark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Add your first section to get started.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _muted,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: state.isSaving ? null : _addSection,
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Add first section'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _green,
                        side: const BorderSide(color: _green),
                      ),
                    ),
                  ],
                ),
              )

            // Only section cards below
            else
              ...sections.map(
                (section) => _SectionCard(
                  section: section,
                  onOpen: () => _openSection(section),
                  onEdit: () => _editSection(section),
                  onToggleActive: () => _toggleSection(section),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active
        ? const Color(0xFF15803D)
        : const Color(0xFF64748B);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: active
            ? const Color(0xFFDCFCE7)
            : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            active
                ? Icons.check_circle_rounded
                : Icons.pause_circle_outline_rounded,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 5),
          Text(
            active ? 'Active' : 'Inactive',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.section,
    required this.onOpen,
    required this.onEdit,
    required this.onToggleActive,
  });

  final SchoolSection section;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onToggleActive;

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF15803D);
    const muted = Color(0xFF64748B);

    final active = section.isActive;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(
          color: Color(0xFFE2E8F0),
        ),
      ),
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: active
                      ? const Color(0xFFDCFCE7)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  Icons.meeting_room_outlined,
                  color: active ? green : muted,
                  size: 23,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      section.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF172B24),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _StatusBadge(active: active),
                        Text(
                          'Capacity: ${section.capacity?.toString() ?? 'Not set'}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: muted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Section actions',
                onSelected: (value) {
                  if (value == 'open') onOpen();
                  if (value == 'edit') onEdit();
                  if (value == 'toggle') onToggleActive();
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'open',
                    child: Text('View details'),
                  ),
                  const PopupMenuItem(
                    value: 'edit',
                    child: Text('Edit section'),
                  ),
                  PopupMenuItem(
                    value: 'toggle',
                    child: Text(
                      active ? 'Deactivate' : 'Activate',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
