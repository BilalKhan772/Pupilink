
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

  Future<List<Student>> getStudents(String schoolId) async {
    final snapshot =
        await _students.where('schoolId', isEqualTo: schoolId).get();

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
    final snapshot = await _students
        .where('schoolId', isEqualTo: schoolId)
        .where('sectionId', isEqualTo: sectionId)
        .count()
        .get();

    return snapshot.count ?? 0;
  }

  Future<Student?> findByAdmissionNumber({
    required String schoolId,
    required String admissionNumber,
  }) async {
    final normalized = admissionNumber.trim().toLowerCase();

    final snapshot = await _students
        .where('schoolId', isEqualTo: schoolId)
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
    final normalizedName = name.trim();
    final normalizedAdmission = admissionNumber.trim();

    if (schoolId.trim().isEmpty) {
      throw ArgumentError('School ID available nahi hai.');
    }

    if (normalizedName.isEmpty ||
        normalizedAdmission.isEmpty ||
        city.trim().isEmpty ||
        schoolName.trim().isEmpty) {
      throw ArgumentError('Tamam required fields fill karein.');
    }

    final duplicate = await findByAdmissionNumber(
      schoolId: schoolId,
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
      schoolId: schoolId,
      schoolName: schoolName.trim(),
      className: className,
      section: sectionName,
      isActive: true,
    );

    final data = student.toMap()
      ..['classId'] = classId
      ..['sectionId'] = sectionId
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
    final normalizedName = name.trim();
    final normalizedAdmission = admissionNumber.trim();

    if (normalizedName.isEmpty || normalizedAdmission.isEmpty) {
      throw ArgumentError('Student name aur admission number required hain.');
    }

    final ref = _students.doc(studentId);
    final current = await ref.get();

    if (!current.exists || current.data()?['schoolId'] != schoolId) {
      throw Exception('Student nahi mila ya school access match nahi karta.');
    }

    final duplicate = await findByAdmissionNumber(
      schoolId: schoolId,
      admissionNumber: normalizedAdmission,
    );

    if (duplicate != null && duplicate.id != studentId) {
      throw Exception('Yeh admission number kisi doosray student ka hai.');
    }

    await ref.update({
      'name': normalizedName,
      'admissionNumber': normalizedAdmission,
      'city': city.trim(),
      'schoolName': schoolName.trim(),
      'classId': classId,
      'className': className,
      'sectionId': sectionId,
      'section': sectionName,
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> setStudentActive({
    required String studentId,
    required String schoolId,
    required bool isActive,
  }) async {
    final ref = _students.doc(studentId);
    final snapshot = await ref.get();

    if (!snapshot.exists || snapshot.data()?['schoolId'] != schoolId) {
      throw Exception('Student nahi mila ya school access match nahi karta.');
    }

    await ref.update({
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
