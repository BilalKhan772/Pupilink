import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_core/school_core.dart';
import 'package:school_models/school_models.dart';

final subjectTeacherWorkRepositoryProvider =
    Provider<SubjectTeacherWorkRepository>((ref) {
  return SubjectTeacherWorkRepository(
    firestore: FirebaseFirestore.instance,
  );
});

class SubjectTeacherWorkRepository {
  SubjectTeacherWorkRepository({
    required FirebaseFirestore firestore,
  }) : _db = firestore;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _students =>
      _db.collection(FirestoreCollections.students);

  CollectionReference<Map<String, dynamic>> get _sections =>
      _db.collection(FirestoreCollections.sections);

  CollectionReference<Map<String, dynamic>> get _subjects =>
      _db.collection(FirestoreCollections.subjects);

  CollectionReference<Map<String, dynamic>> get _tests =>
      _db.collection(FirestoreCollections.tests);

  CollectionReference<Map<String, dynamic>> get _marks =>
      _db.collection(FirestoreCollections.studentMarks);

  // ------------------------------------------------------------
  // VALIDATION HELPERS
  // ------------------------------------------------------------

  String _requiredValue(String value, String label) {
    final normalized = value.trim();

    if (normalized.isEmpty) {
      throw ArgumentError('$label is missing.');
    }

    return normalized;
  }

  /// Reads a section and verifies that it belongs to the requested school.
  Future<Map<String, dynamic>> _getVerifiedSection({
    required String schoolId,
    required String sectionId,
  }) async {
    final normalizedSchoolId =
        _requiredValue(schoolId, 'School ID');

    final normalizedSectionId =
        _requiredValue(sectionId, 'Section ID');

    final snapshot =
        await _sections.doc(normalizedSectionId).get();

    final data = snapshot.data();

    if (!snapshot.exists ||
        data == null ||
        data['schoolId'] != normalizedSchoolId) {
      throw StateError(
        'The selected section was not found in this school.',
      );
    }

    final classId = data['classId'];

    if (classId is! String || classId.trim().isEmpty) {
      throw StateError(
        'The selected section does not have a valid class assignment.',
      );
    }

    if (data['isActive'] == false) {
      throw StateError(
        'The selected section is inactive.',
      );
    }

    return data;
  }

  /// Verifies the test document currently stored in Firestore.
  ///
  /// This prevents a stale or mismatched SchoolTest object from being
  /// used to save marks for a different class, section or subject.
  Future<Map<String, dynamic>> _getVerifiedTest({
    required String schoolId,
    required SchoolTest test,
  }) async {
    final normalizedSchoolId =
        _requiredValue(schoolId, 'School ID');

    final testId = _requiredValue(test.id, 'Test ID');

    final snapshot = await _tests.doc(testId).get();
    final data = snapshot.data();

    if (!snapshot.exists || data == null) {
      throw StateError(
        'This test no longer exists. Refresh and try again.',
      );
    }

    if (data['schoolId'] != normalizedSchoolId ||
        test.schoolId != normalizedSchoolId) {
      throw StateError(
        'This test does not belong to the current school.',
      );
    }

    if (data['classId'] != test.classId ||
        data['sectionId'] != test.sectionId ||
        data['subjectId'] != test.subjectId) {
      throw StateError(
        'The test class, section or subject has changed. '
        'Refresh the test list and try again.',
      );
    }

    final sectionData = await _getVerifiedSection(
      schoolId: normalizedSchoolId,
      sectionId: test.sectionId,
    );

    if (sectionData['classId'] != test.classId) {
      throw StateError(
        'The selected test does not belong to this class section.',
      );
    }

    return data;
  }

  /// Verifies every selected student against the actual Firestore record.
  Future<void> _validateStudentsForTest({
    required String schoolId,
    required SchoolTest test,
    required List<Student> students,
  }) async {
    if (students.isEmpty) {
      throw StateError(
        'There are no active students in this section.',
      );
    }

    final studentIds = students.map((student) => student.id).toList();

    if (studentIds.any((id) => id.trim().isEmpty)) {
      throw StateError(
        'A student record has a missing ID. Refresh the student list.',
      );
    }

    if (studentIds.toSet().length != studentIds.length) {
      throw StateError(
        'The student list contains duplicate records. Refresh and try again.',
      );
    }

    final snapshots = await Future.wait(
      students.map((student) => _students.doc(student.id).get()),
    );

    for (var index = 0; index < students.length; index++) {
      final student = students[index];
      final snapshot = snapshots[index];
      final data = snapshot.data();

      if (!snapshot.exists || data == null) {
        throw StateError(
          'Student "${student.name}" no longer exists. Refresh the list.',
        );
      }

      if (data['schoolId'] != schoolId) {
        throw StateError(
          'Student "${student.name}" belongs to another school.',
        );
      }

      if (data['classId'] != test.classId ||
          data['sectionId'] != test.sectionId) {
        throw StateError(
          'Student "${student.name}" is not assigned to the class '
          'and section of this test. No marks were saved.',
        );
      }

      if (data['isActive'] != true) {
        throw StateError(
          'Student "${student.name}" is inactive. Refresh the list.',
        );
      }
    }
  }

  // ------------------------------------------------------------
  // SUBJECT
  // ------------------------------------------------------------

  Future<String> getSubjectName({
    required String schoolId,
    required String subjectId,
  }) async {
    final normalizedSchoolId =
        _requiredValue(schoolId, 'School ID');

    if (subjectId.trim().isEmpty) {
      return 'Subject not set';
    }

    final doc = await _subjects.doc(subjectId.trim()).get();
    final data = doc.data();

    if (!doc.exists ||
        data == null ||
        data['schoolId'] != normalizedSchoolId) {
      return 'Subject not found';
    }

    final name = (data['name'] as String? ?? '').trim();

    return name.isEmpty ? subjectId.trim() : name;
  }

  // ------------------------------------------------------------
  // STUDENTS
  // ------------------------------------------------------------

  /// Returns active students from the selected section only.
  ///
  /// The classId is obtained from the section document, then applied
  /// to the student query as an additional scope restriction.
  Future<List<Student>> getSectionStudents({
    required String schoolId,
    required String sectionId,
  }) async {
    final normalizedSchoolId =
        _requiredValue(schoolId, 'School ID');

    final normalizedSectionId =
        _requiredValue(sectionId, 'Section ID');

    final sectionData = await _getVerifiedSection(
      schoolId: normalizedSchoolId,
      sectionId: normalizedSectionId,
    );

    final sectionClassId =
        sectionData['classId'] as String;

    final result = await _students
        .where('schoolId', isEqualTo: normalizedSchoolId)
        .where('classId', isEqualTo: sectionClassId)
        .where('sectionId', isEqualTo: normalizedSectionId)
        .where('isActive', isEqualTo: true)
        .get();

    final students = result.docs
        .map((doc) => Student.fromMap(doc.id, doc.data()))
        .toList();

    students.sort(
      (a, b) => a.name.toLowerCase().compareTo(
            b.name.toLowerCase(),
          ),
    );

    return students;
  }

  // ------------------------------------------------------------
  // TESTS
  // ------------------------------------------------------------

  Future<List<SchoolTest>> getTests({
    required String schoolId,
    required String sectionId,
    required String subjectId,
  }) async {
    final normalizedSchoolId =
        _requiredValue(schoolId, 'School ID');

    final normalizedSectionId =
        _requiredValue(sectionId, 'Section ID');

    final normalizedSubjectId =
        _requiredValue(subjectId, 'Subject ID');

    final sectionData = await _getVerifiedSection(
      schoolId: normalizedSchoolId,
      sectionId: normalizedSectionId,
    );

    final sectionClassId =
        sectionData['classId'] as String;

    final result = await _tests
        .where('schoolId', isEqualTo: normalizedSchoolId)
        .where('sectionId', isEqualTo: normalizedSectionId)
        .where('subjectId', isEqualTo: normalizedSubjectId)
        .get();

    // Apply the class check as well, so any old or inconsistent test
    // document cannot appear under another class section.
    final tests = result.docs
        .where((doc) {
          final data = doc.data();

          return data['classId'] == sectionClassId &&
              data['schoolId'] == normalizedSchoolId &&
              data['sectionId'] == normalizedSectionId &&
              data['subjectId'] == normalizedSubjectId;
        })
        .map(
          (doc) => SchoolTest.fromMap(doc.id, doc.data()),
        )
        .toList();

    tests.sort((a, b) => b.testDate.compareTo(a.testDate));

    return tests;
  }

  Future<String> createTest({
    required String schoolId,
    required String teacherId,
    required TeacherAssignment assignment,
    required String subjectName,
    required String title,
    required DateTime testDate,
    required double totalMarks,
    required double passingMarks,
    String description = '',
  }) async {
    final normalizedSchoolId =
        _requiredValue(schoolId, 'School ID');

    final normalizedTeacherId =
        _requiredValue(teacherId, 'Teacher ID');

    final normalizedTitle =
        _requiredValue(title, 'Test title');

    final sectionId = _requiredValue(
      assignment.sectionId ?? '',
      'Assignment section ID',
    );

    final subjectId = _requiredValue(
      assignment.subjectId ?? '',
      'Assignment subject ID',
    );

    final classId = _requiredValue(
      assignment.classId,
      'Assignment class ID',
    );

    if (assignment.schoolId != normalizedSchoolId) {
      throw StateError(
        'This assignment does not belong to the current school.',
      );
    }

    if (totalMarks <= 0 ||
        passingMarks < 0 ||
        passingMarks > totalMarks) {
      throw ArgumentError(
        'Please check the total and passing marks.',
      );
    }

    final sectionData = await _getVerifiedSection(
      schoolId: normalizedSchoolId,
      sectionId: sectionId,
    );

    if (sectionData['classId'] != classId) {
      throw StateError(
        'The selected assignment does not match its section class.',
      );
    }

    // Verify that the subject exists within the same school.
    final subjectSnapshot = await _subjects.doc(subjectId).get();
    final subjectData = subjectSnapshot.data();

    if (!subjectSnapshot.exists ||
        subjectData == null ||
        subjectData['schoolId'] != normalizedSchoolId) {
      throw StateError(
        'The selected subject was not found in this school.',
      );
    }

    final testRef = _tests.doc();

    final test = SchoolTest(
      id: testRef.id,
      schoolId: normalizedSchoolId,
      title: normalizedTitle,
      description: description.trim(),
      classId: classId,
      sectionId: sectionId,
      subjectId: subjectId,
      subjectName: subjectName.trim(),
      academicYearId: assignment.academicYearId,
      testType: 'classTest',
      testDate: DateTime(
        testDate.year,
        testDate.month,
        testDate.day,
      ),
      startTime: '09:00',
      endTime: '10:00',
      totalMarks: totalMarks,
      passingMarks: passingMarks,
      status: 'scheduled',
      createdBy: normalizedTeacherId,
    );

    final data = test.toMap()
      ..['schoolId'] = normalizedSchoolId
      ..['classId'] = classId
      ..['sectionId'] = sectionId
      ..['subjectId'] = subjectId
      ..['createdAt'] = FieldValue.serverTimestamp()
      ..['updatedAt'] = FieldValue.serverTimestamp();

    await testRef.set(data);

    return testRef.id;
  }

  // ------------------------------------------------------------
  // EXISTING MARKS
  // ------------------------------------------------------------

  Future<Map<String, double>> getExistingMarks({
    required String schoolId,
    required String testId,
    required List<Student> students,
  }) async {
    final normalizedSchoolId =
        _requiredValue(schoolId, 'School ID');

    final normalizedTestId =
        _requiredValue(testId, 'Test ID');

    if (students.isEmpty) return {};

    final allowedStudentIds =
        students.map((student) => student.id).toSet();

    final result = await _marks
        .where('schoolId', isEqualTo: normalizedSchoolId)
        .where('examId', isEqualTo: normalizedTestId)
        .get();

    final marks = <String, double>{};

    for (final doc in result.docs) {
      final data = doc.data();
      final studentId = data['studentId'] as String? ?? '';

      // Ignore any record whose saved scope does not identify this test.
      if (data['schoolId'] != normalizedSchoolId ||
          data['examId'] != normalizedTestId ||
          !allowedStudentIds.contains(studentId)) {
        continue;
      }

      final value = data['obtainedMarks'];

      if (value is num) {
        marks[studentId] = value.toDouble();
      }
    }

    return marks;
  }

  // ------------------------------------------------------------
  // SAVE / PUBLISH MARKS
  // ------------------------------------------------------------

  Future<void> saveStudentMarks({
    required String schoolId,
    required String teacherId,
    required SchoolTest test,
    required List<Student> students,
    required Map<String, double> enteredMarks,
  }) async {
    final normalizedSchoolId =
        _requiredValue(schoolId, 'School ID');

    final normalizedTeacherId =
        _requiredValue(teacherId, 'Teacher ID');

    // Verify the current test and its section before any writes.
    final testData = await _getVerifiedTest(
      schoolId: normalizedSchoolId,
      test: test,
    );

    if (testData['classId'] != test.classId ||
        testData['sectionId'] != test.sectionId ||
        testData['subjectId'] != test.subjectId) {
      throw StateError(
        'The test scope is invalid. Refresh the test list and try again.',
      );
    }

    // Verify every student in Firestore before committing any marks.
    await _validateStudentsForTest(
      schoolId: normalizedSchoolId,
      test: test,
      students: students,
    );

    // Validate every entered score before starting any writes.
    for (final student in students) {
      final value = enteredMarks[student.id] ?? 0.0;

      if (!value.isFinite ||
          value < 0 ||
          value > test.totalMarks) {
        throw ArgumentError(
          '${student.name}: marks must be between 0 and '
          '${test.totalMarks}.',
        );
      }
    }

    final batch = _db.batch();
    final now = FieldValue.serverTimestamp();

    // Read existing documents first, so createdAt is not overwritten
    // when the teacher edits marks for the same test.
    final markRefs = students
        .map((student) => _marks.doc('${test.id}_${student.id}'))
        .toList();

    final existingSnapshots = await Future.wait(
      markRefs.map((markRef) => markRef.get()),
    );

    for (var index = 0; index < students.length; index++) {
      final student = students[index];
      final markRef = markRefs[index];
      final oldMark = existingSnapshots[index];
      final value = enteredMarks[student.id] ?? 0.0;

      final mark = StudentMark(
        id: markRef.id,
        schoolId: normalizedSchoolId,
        studentId: student.id,
        examId: test.id,
        classId: test.classId,
        sectionId: test.sectionId,
        subjectId: test.subjectId,
        subjectName: test.subjectName,
        academicYearId: test.academicYearId,
        obtainedMarks: value,
        totalMarks: test.totalMarks,
        status: 'published',
        enteredBy: normalizedTeacherId,
      );

      final data = mark.toMap()
        ..['schoolId'] = normalizedSchoolId
        ..['studentId'] = student.id
        ..['examId'] = test.id
        ..['classId'] = test.classId
        ..['sectionId'] = test.sectionId
        ..['subjectId'] = test.subjectId
        ..['status'] = 'published'
        ..['updatedAt'] = now;

      if (!oldMark.exists) {
        data['createdAt'] = now;
      } else {
        data.remove('createdAt');
      }

      batch.set(
        markRef,
        data,
        SetOptions(merge: true),
      );
    }

    await batch.commit();
  }
}