import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../logic/parent_homework_controller.dart';
import '../logic/parent_homework_state.dart';
import 'homework_detail_screen.dart';
import 'widgets/homework_date_group.dart';

class HomeworkScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> child;

  const HomeworkScreen({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<HomeworkScreen> createState() => _HomeworkScreenState();
}

class _HomeworkScreenState extends ConsumerState<HomeworkScreen> {
  static const Color _green = Color(0xFF138A4B);
  static const Color _darkGreen = Color(0xFF105C3B);
  static const Color _background = Color(0xFFF4F8F5);
  static const Color _border = Color(0xFFDDE9E1);
  static const Color _text = Color(0xFF202B25);
  static const Color _muted = Color(0xFF68766E);

  String get _studentId => widget.child['studentId'] as String? ?? '';

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) _loadHomework();
    });
  }

  Future<void> _loadHomework() {
    return ref
        .read(parentHomeworkControllerProvider.notifier)
        .loadHomework(studentId: _studentId);
  }

  void _openHomeworkDetail(Map<String, dynamic> homework) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => HomeworkDetailScreen(homework: homework),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ParentHomeworkState state = ref.watch(parentHomeworkControllerProvider);
    final studentName = (widget.child['name'] as String? ?? '').trim().isEmpty
        ? 'Student'
        : (widget.child['name'] as String).trim();

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _darkGreen,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 20,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Homework',
              style: TextStyle(
                color: _darkGreen,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'View assigned work and due dates',
              style: TextStyle(
                color: _muted,
                fontSize: 11,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh homework',
            onPressed: state.isLoading ? null : _loadHomework,
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 8),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: _border),
        ),
      ),
      body: SafeArea(
        child: state.isLoading && state.records.isEmpty
            ? const _LoadingView()
            : LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final maxContentWidth = width >= 1200 ? 1080.0 : width;
                  final horizontalPadding = width < 600 ? 16.0 : 24.0;

                  return Align(
                    alignment: Alignment.topCenter,
                    child: SizedBox(
                      width: maxContentWidth,
                      child: RefreshIndicator(
                        onRefresh: _loadHomework,
                        color: _green,
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: EdgeInsets.fromLTRB(
                            horizontalPadding,
                            22,
                            horizontalPadding,
                            36,
                          ),
                          children: [
                            _buildStudentHeader(studentName),
                            if (state.isLoading) ...[
                              const SizedBox(height: 12),
                              const LinearProgressIndicator(
                                minHeight: 3,
                                color: _green,
                                backgroundColor: Color(0xFFDCEBE1),
                              ),
                            ],
                            if (state.error != null) ...[
                              const SizedBox(height: 16),
                              _buildErrorCard(state.error!),
                            ],
                            const SizedBox(height: 24),
                            _buildSectionHeading(
                              title: 'Homework Overview',
                              subtitle: 'A summary of the work assigned to your child.',
                              count: state.totalCount,
                            ),
                            const SizedBox(height: 14),
                            _buildSummaryCards(state),
                            if (state.records.isNotEmpty) ...[
                              const SizedBox(height: 26),
                              _buildSectionHeading(
                                title: 'Assigned Homework',
                                subtitle: 'Select an item to view its full instructions.',
                                count: state.records.length,
                              ),
                              const SizedBox(height: 13),
                              ..._buildGroups(state.records),
                            ] else if (state.error == null) ...[
                              const SizedBox(height: 22),
                              _buildEmptyHomework(),
                            ],
                            const SizedBox(height: 10),
                            const _InformationNote(
                              message:
                                  'Open any homework card to read the complete instructions and due date.',
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildStudentHeader(String studentName) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.white, Color(0xFFEAF6EF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFDDF1E4),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.person_outline_rounded,
              color: _darkGreen,
              size: 30,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  studentName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _text,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Homework & Assignments',
                  style: TextStyle(color: _muted, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.85),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.menu_book_rounded,
              color: _green,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeading({
    required String title,
    required String subtitle,
    int? count,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: _text,
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
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
        if (count != null) ...[
          const SizedBox(width: 10),
          Container(
            constraints: const BoxConstraints(minWidth: 30),
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
            decoration: const BoxDecoration(
              color: Color(0xFFE2F2E7),
              shape: BoxShape.circle,
            ),
            child: Text(
              '$count',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _darkGreen,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSummaryCards(ParentHomeworkState state) {
    // Show only the overall homework count. Status-specific summaries
    // and filter controls are intentionally omitted from this screen.
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF163B28).withValues(alpha: 0.025),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 46,
            width: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFE4F3E9),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.menu_book_outlined,
              color: _darkGreen,
              size: 24,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total Homework',
                  style: TextStyle(
                    color: _muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${state.totalCount}',
                  style: const TextStyle(
                    color: _darkGreen,
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.assignment_outlined,
            color: _green,
            size: 23,
          ),
        ],
      ),
    );
  }

  List<Widget> _buildGroups(List<Map<String, dynamic>> records) {
    final groups = <String, List<Map<String, dynamic>>>{};

    for (final record in records) {
      final rawDate = record['dueDate']?.toString().trim() ?? '';
      final parsedDate = DateTime.tryParse(rawDate);
      final dateKey = parsedDate == null
          ? rawDate
          : '${parsedDate.year.toString().padLeft(4, '0')}-'
              '${parsedDate.month.toString().padLeft(2, '0')}-'
              '${parsedDate.day.toString().padLeft(2, '0')}';

      groups.putIfAbsent(dateKey, () => <Map<String, dynamic>>[]).add(record);
    }

    return groups.entries.map((entry) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: HomeworkDateGroup(
          date: entry.key,
          homework: entry.value,
          onHomeworkTap: _openHomeworkDetail,
        ),
      );
    }).toList();
  }

  Widget _buildErrorCard(String message) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F0),
        border: Border.all(color: const Color(0xFFF3C6C2)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded, color: Color(0xFFB42318)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Unable to Load Homework',
                  style: TextStyle(
                    color: Color(0xFF912018),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  message,
                  style: const TextStyle(
                    color: Color(0xFF912018),
                    fontSize: 12,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: _loadHomework,
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF912018),
                    ),
                    icon: const Icon(Icons.refresh_rounded, size: 17),
                    label: const Text('Try Again'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyHomework() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
      ),
      child: const Column(
        children: [
          CircleAvatar(
            radius: 31,
            backgroundColor: Color(0xFFE4F3E9),
            child: Icon(
              Icons.menu_book_outlined,
              color: _darkGreen,
              size: 31,
            ),
          ),
          SizedBox(height: 15),
          Text(
            'No Homework Available',
            style: TextStyle(
              color: _text,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'New homework assigned by the school will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _muted,
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }


}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: Color(0xFF138A4B)),
          SizedBox(height: 14),
          Text(
            'Loading homework...',
            style: TextStyle(
              color: Color(0xFF68766E),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _InformationNote extends StatelessWidget {
  const _InformationNote({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF5ED),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFFD8EBDD)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: Color(0xFF267344),
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFF315B40),
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
