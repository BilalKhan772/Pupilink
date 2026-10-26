
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/school_reports_repository.dart';
import 'school_reports_state.dart';

final schoolReportsControllerProvider = Provider.family<
    SchoolReportsController,
    String>(
  (ref, schoolId) {
    return SchoolReportsController(
      ref: ref,
      schoolId: schoolId,
    );
  },
);

class SchoolReportsController {
  SchoolReportsController({
    required Ref ref,
    required String schoolId,
  })  : _ref = ref,
        _schoolId = schoolId;

  final Ref _ref;
  final String _schoolId;

  late final SchoolReportsRepository _repository =
      _ref.read(schoolReportsRepositoryProvider);

  SchoolReportsState _state = const SchoolReportsState();

  SchoolReportsState get state => _state;

  final List<void Function()> _listeners = [];

  void addListener(void Function() listener) {
    _listeners.add(listener);
  }

  void removeListener(void Function() listener) {
    _listeners.remove(listener);
  }

  void _setState(SchoolReportsState newState) {
    _state = newState;

    for (final listener in List<void Function()>.from(_listeners)) {
      listener();
    }
  }

  Future<void> loadClasses() async {
    _setState(
      _state.copyWith(
        isLoadingClasses: true,
        clearError: true,
      ),
    );

    try {
      final classes = await _repository.getClasses(_schoolId);

      _setState(
        _state.copyWith(
          classes: classes,
          isLoadingClasses: false,
          clearSelectedClassId: true,
          clearSelectedSectionId: true,
          sections: const [],
          clearReport: true,
        ),
      );
    } catch (e) {
      _setState(
        _state.copyWith(
          isLoadingClasses: false,
          errorMessage: 'Classes load nahi ho sakin: $e',
        ),
      );
    }
  }

  Future<void> selectClass(String classId) async {
    _setState(
      _state.copyWith(
        selectedClassId: classId,
        clearSelectedSectionId: true,
        sections: const [],
        clearReport: true,
        clearError: true,
        isLoadingSections: true,
      ),
    );

    try {
      final sections = await _repository.getSections(
        schoolId: _schoolId,
        classId: classId,
      );

      _setState(
        _state.copyWith(
          sections: sections,
          isLoadingSections: false,
        ),
      );
    } catch (e) {
      _setState(
        _state.copyWith(
          isLoadingSections: false,
          errorMessage: 'Sections load nahi ho sake: $e',
        ),
      );
    }
  }

  void selectSection(String sectionId) {
    _setState(
      _state.copyWith(
        selectedSectionId: sectionId,
        clearReport: true,
        clearError: true,
      ),
    );
  }

  Future<void> loadSectionReport() async {
    final classId = _state.selectedClassId;
    final sectionId = _state.selectedSectionId;

    if (classId == null || sectionId == null) {
      _setState(
        _state.copyWith(
          errorMessage: 'Pehle class aur section select karein.',
        ),
      );
      return;
    }

    await _loadReport(
      classId: classId,
      sectionId: sectionId,
    );
  }

  Future<void> loadClassReport() async {
    final classId = _state.selectedClassId;

    if (classId == null) {
      _setState(
        _state.copyWith(
          errorMessage: 'Pehle class select karein.',
        ),
      );
      return;
    }

    await _loadReport(classId: classId);
  }

  Future<void> _loadReport({
    required String classId,
    String? sectionId,
  }) async {
    _setState(
      _state.copyWith(
        isLoadingReport: true,
        clearError: true,
        clearReport: true,
      ),
    );

    try {
      final report = await _repository.getPerformanceReport(
        schoolId: _schoolId,
        classId: classId,
        sectionId: sectionId,
      );

      _setState(
        _state.copyWith(
          report: report,
          isLoadingReport: false,
        ),
      );
    } catch (e) {
      _setState(
        _state.copyWith(
          isLoadingReport: false,
          errorMessage: 'Report load nahi ho saki: $e',
        ),
      );
    }
  }
}