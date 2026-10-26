
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

  CollectionReference<Map<String, dynamic>> get _subjects =>
      _db.collection(FirestoreCollections.subjects);

  CollectionReference<Map<String, dynamic>> get _tests =>
      _db.collection(FirestoreCollections.tests);

  CollectionReference<Map<String, dynamic>> get _marks =>
      _db.collection(FirestoreCollections.studentMarks);

  Future<String> getSubjectName({
    required String schoolId,
    required String subjectId,
  }) async {
    if (subjectId.trim().isEmpty) return 'Subject not set';

    final doc = await _subjects.doc(subjectId).get();
    final data = doc.data();

    if (!doc.exists ||
        data == null ||
        data['schoolId'] != schoolId) {
      return 'Subject not found';
    }

    final name = (data['name'] as String? ?? '').trim();
    return name.isEmpty ? subjectId : name;
  }

  Future<List<Student>> getSectionStudents({
    required String schoolId,
    required String sectionId,
  }) async {
    if (schoolId.trim().isEmpty || sectionId.trim().isEmpty) {
      throw ArgumentError('School aur section required hain.');
    }

    final result = await _students
        .where('schoolId', isEqualTo: schoolId)
        .where('sectionId', isEqualTo: sectionId)
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

  Future<List<SchoolTest>> getTests({
    required String schoolId,
    required String sectionId,
    required String subjectId,
  }) async {
    final result = await _tests
        .where('schoolId', isEqualTo: schoolId)
        .where('sectionId', isEqualTo: sectionId)
        .where('subjectId', isEqualTo: subjectId)
        .get();

    final tests = result.docs
        .map((doc) => SchoolTest.fromMap(doc.id, doc.data()))
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
    if (title.trim().isEmpty) {
      throw ArgumentError('Test ka naam enter karein.');
    }

    if (assignment.sectionId == null ||
        assignment.sectionId!.trim().isEmpty ||
        (assignment.subjectId ?? '').trim().isEmpty) {
      throw ArgumentError(
        'Assignment mein subject ya section missing hai.',
      );
    }

    if (totalMarks <= 0 ||
        passingMarks < 0 ||
        passingMarks > totalMarks) {
      throw ArgumentError('Total aur passing marks check karein.');
    }

    final ref = _tests.doc();

    final test = SchoolTest(
      id: ref.id,
      schoolId: schoolId,
      title: title.trim(),
      description: description.trim(),
      classId: assignment.classId,
      sectionId: assignment.sectionId!,
      subjectId: assignment.subjectId!,
      subjectName: subjectName,
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
      createdBy: teacherId,
    );

    final data = test.toMap();
    data['createdAt'] = FieldValue.serverTimestamp();
    data['updatedAt'] = FieldValue.serverTimestamp();

    await ref.set(data);
    return ref.id;
  }

  Future<Map<String, double>> getExistingMarks({
    required String schoolId,
    required String testId,
    required List<Student> students,
  }) async {
    if (students.isEmpty) return {};

    final result = await _marks
        .where('schoolId', isEqualTo: schoolId)
        .where('examId', isEqualTo: testId)
        .get();

    final marks = <String, double>{};

    for (final doc in result.docs) {
      final data = doc.data();
      final studentId = data['studentId'] as String? ?? '';

      if (students.any((student) => student.id == studentId)) {
        marks[studentId] =
            (data['obtainedMarks'] as num?)?.toDouble() ?? 0;
      }
    }

    return marks;
  }

  Future<void> saveStudentMarks({
    required String schoolId,
    required String teacherId,
    required SchoolTest test,
    required List<Student> students,
    required Map<String, double> enteredMarks,
  }) async {
    if (test.schoolId != schoolId) {
      throw StateError('Test aapke school ka nahi hai.');
    }

    if (test.createdBy != teacherId) {
      // Existing tests created by an admin may also be assigned to a teacher.
      // Assignment authorization must additionally be enforced by Firestore rules.
    }

    if (students.isEmpty) {
      throw StateError('Is section mein koi active student nahi hai.');
    }

    final batch = _db.batch();
    final now = FieldValue.serverTimestamp();

    for (final student in students) {
      final value = enteredMarks[student.id] ?? 0;

      if (value < 0 || value > test.totalMarks) {
        throw ArgumentError(
          '${student.name}: marks 0 se ${test.totalMarks} ke darmiyan hone chahiye.',
        );
      }

      final markId = '${test.id}_${student.id}';
      final markRef = _marks.doc(markId);
      final oldMark = await markRef.get();

      final mark = StudentMark(
        id: markId,
        schoolId: schoolId,
        studentId: student.id,
        examId: test.id,
        classId: test.classId,
        sectionId: test.sectionId,
        subjectId: test.subjectId,
        subjectName: test.subjectName,
        academicYearId: test.academicYearId,
        obtainedMarks: value,
        totalMarks: test.totalMarks,

        // UPDATED: Teacher ke Save & Upload par result publish hoga.
        status: 'published',

        enteredBy: teacherId,
      );

      final data = mark.toMap();
      data['updatedAt'] = now;

      if (!oldMark.exists) {
        data['createdAt'] = now;
      } else {
        data.remove('createdAt');
      }

      batch.set(markRef, data, SetOptions(merge: true));
    }

    await batch.commit();
  }
}
