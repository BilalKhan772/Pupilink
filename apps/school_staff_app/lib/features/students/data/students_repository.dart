
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_firebase/school_firebase.dart';
import 'package:school_models/school_models.dart';

final studentsRepositoryProvider = Provider<StudentsRepository>((ref) {
  return StudentsRepository(firestore: FirestoreClient());
});

class StudentsRepository {
  StudentsRepository({required FirestoreClient firestore})
      : _firestore = firestore;

  final FirestoreClient _firestore;

  CollectionReference<Map<String, dynamic>> get _students =>
      _firestore.collection(FirestorePaths.students);

  /// sectionId null/empty ho to school ke tamam students.
  /// sectionId diya ho to sirf us section ke students.
  Future<List<Student>> getStudents(
    String schoolId, {
    String? sectionId,
  }) async {
    final normalizedSchoolId = schoolId.trim();
    final normalizedSectionId = sectionId?.trim() ?? '';

    if (normalizedSchoolId.isEmpty) {
      return <Student>[];
    }

    Query<Map<String, dynamic>> query = _students.where(
      'schoolId',
      isEqualTo: normalizedSchoolId,
    );

    if (normalizedSectionId.isNotEmpty) {
      query = query.where(
        'sectionId',
        isEqualTo: normalizedSectionId,
      );
    }

    final snapshot = await query.get();

    final students = snapshot.docs
        .map((doc) => Student.fromMap(doc.id, doc.data()))
        .toList();

    students.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );

    return students;
  }

  /// Counts students assigned to one specific section.
  Future<int> getStudentCountForSection({
    required String schoolId,
    required String sectionId,
  }) async {
    final normalizedSchoolId = schoolId.trim();
    final normalizedSectionId = sectionId.trim();

    if (normalizedSchoolId.isEmpty || normalizedSectionId.isEmpty) {
      return 0;
    }

    final snapshot = await _students
        .where('schoolId', isEqualTo: normalizedSchoolId)
        .where('sectionId', isEqualTo: normalizedSectionId)
        .count()
        .get();

    return snapshot.count ?? 0;
  }

  Future<Student?> findByAdmissionNumber({
    required String schoolId,
    required String admissionNumber,
  }) async {
    final normalizedSchoolId = schoolId.trim();
    final normalized = admissionNumber.trim().toLowerCase();

    if (normalizedSchoolId.isEmpty || normalized.isEmpty) {
      return null;
    }

    final snapshot = await _students
        .where('schoolId', isEqualTo: normalizedSchoolId)
        .get();

    for (final doc in snapshot.docs) {
      final student = Student.fromMap(doc.id, doc.data());

      if (student.admissionNumber.trim().toLowerCase() == normalized) {
        return student;
      }
    }

    return null;
  }

  Future<void> addStudent({
    required String schoolId,
    required String name,
    required String admissionNumber,
    required String city,
    required String schoolName,
    required String classId,
    required String className,
    required String sectionId,
    required String sectionName,
  }) async {
    final normalizedSchoolId = schoolId.trim();
    final normalizedName = name.trim();
    final normalizedAdmission = admissionNumber.trim();
    final normalizedSectionId = sectionId.trim();

    if (normalizedSchoolId.isEmpty) {
      throw ArgumentError('School ID available nahi hai.');
    }

    if (normalizedName.isEmpty ||
        normalizedAdmission.isEmpty ||
        city.trim().isEmpty ||
        schoolName.trim().isEmpty ||
        classId.trim().isEmpty ||
        className.trim().isEmpty ||
        normalizedSectionId.isEmpty ||
        sectionName.trim().isEmpty) {
      throw ArgumentError('Tamam required fields fill karein.');
    }

    final duplicate = await findByAdmissionNumber(
      schoolId: normalizedSchoolId,
      admissionNumber: normalizedAdmission,
    );

    if (duplicate != null) {
      throw Exception('Yeh admission number pehle se mojood hai.');
    }

    final student = Student(
      id: '',
      name: normalizedName,
      admissionNumber: normalizedAdmission,
      city: city.trim(),
      schoolId: normalizedSchoolId,
      schoolName: schoolName.trim(),
      className: className.trim(),
      section: sectionName.trim(),
      isActive: true,
    );

    final data = student.toMap()
      ..['classId'] = classId.trim()
      ..['sectionId'] = normalizedSectionId
      ..['createdAt'] = FieldValue.serverTimestamp()
      ..['updatedAt'] = FieldValue.serverTimestamp();

    await _students.add(data);
  }

  Future<void> updateStudent({
    required String studentId,
    required String schoolId,
    required String name,
    required String admissionNumber,
    required String city,
    required String schoolName,
    required String classId,
    required String className,
    required String sectionId,
    required String sectionName,
    required bool isActive,
  }) async {
    final normalizedSchoolId = schoolId.trim();
    final normalizedName = name.trim();
    final normalizedAdmission = admissionNumber.trim();

    if (normalizedSchoolId.isEmpty ||
        normalizedName.isEmpty ||
        normalizedAdmission.isEmpty) {
      throw ArgumentError(
        'School ID, student name aur admission number required hain.',
      );
    }

    final studentRef = _students.doc(studentId);
    final current = await studentRef.get();

    if (!current.exists ||
        current.data()?['schoolId'] != normalizedSchoolId) {
      throw Exception(
        'Student nahi mila ya school access match nahi karta.',
      );
    }

    final duplicate = await findByAdmissionNumber(
      schoolId: normalizedSchoolId,
      admissionNumber: normalizedAdmission,
    );

    if (duplicate != null && duplicate.id != studentId) {
      throw Exception('Yeh admission number kisi doosray student ka hai.');
    }

    await studentRef.update({
      'name': normalizedName,
      'admissionNumber': normalizedAdmission,
      'city': city.trim(),
      'schoolName': schoolName.trim(),
      'classId': classId.trim(),
      'className': className.trim(),
      'sectionId': sectionId.trim(),
      'section': sectionName.trim(),
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> setStudentActive({
    required String studentId,
    required String schoolId,
    required bool isActive,
  }) async {
    final normalizedSchoolId = schoolId.trim();
    final studentRef = _students.doc(studentId);
    final snapshot = await studentRef.get();

    if (!snapshot.exists ||
        snapshot.data()?['schoolId'] != normalizedSchoolId) {
      throw Exception(
        'Student nahi mila ya school access match nahi karta.',
      );
    }

    await studentRef.update({
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
