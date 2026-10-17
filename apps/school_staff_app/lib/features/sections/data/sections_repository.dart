
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_firebase/school_firebase.dart';
import 'package:school_models/school_models.dart';

final sectionsRepositoryProvider = Provider<SectionsRepository>((ref) {
  return SectionsRepository(firestore: FirestoreClient());
});

class SectionsRepository {
  SectionsRepository({required FirestoreClient firestore})
      : _firestore = firestore;

  final FirestoreClient _firestore;

  CollectionReference<Map<String, dynamic>> get _sections =>
      _firestore.collection(FirestorePaths.sections);

  CollectionReference<Map<String, dynamic>> get _classes =>
      _firestore.collection(FirestorePaths.classes);

  CollectionReference<Map<String, dynamic>> get _academicYears =>
      _firestore.collection(FirestorePaths.academicYears);

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  Future<List<SchoolSection>> getSections(String schoolId) async {
    final snapshot =
        await _sections.where('schoolId', isEqualTo: schoolId).get();

    final sections = snapshot.docs
        .map((doc) => SchoolSection.fromMap(doc.id, doc.data()))
        .toList();

    sections.sort((a, b) {
      final classComparison = a.classId.compareTo(b.classId);

      if (classComparison != 0) {
        return classComparison;
      }

      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    return sections;
  }

  Future<List<SchoolClass>> getClasses(String schoolId) async {
    final snapshot =
        await _classes.where('schoolId', isEqualTo: schoolId).get();

    final classes = snapshot.docs
        .map((doc) => SchoolClass.fromMap(doc.id, doc.data()))
        .toList();

    classes.sort((a, b) {
      final order =
          (a.sortOrder ?? 999999).compareTo(b.sortOrder ?? 999999);

      return order != 0
          ? order
          : a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    return classes;
  }

  Future<List<AcademicYear>> getAcademicYears(String schoolId) async {
    final snapshot = await _academicYears
        .where('schoolId', isEqualTo: schoolId)
        .get();

    final years = snapshot.docs
        .map((doc) => AcademicYear.fromMap(doc.id, doc.data()))
        .toList();

    years.sort((a, b) => b.startDate.compareTo(a.startDate));

    return years;
  }

  Future<void> addSection({
    required String schoolId,
    required String classId,
    required String name,
    String? academicYearId,
    String? classTeacherId,
    int? capacity,
  }) async {
    final normalizedName = name.trim();

    _validateSectionInput(
      schoolId: schoolId,
      classId: classId,
      name: normalizedName,
      capacity: capacity,
    );

    await _verifyClass(
      schoolId: schoolId,
      classId: classId,
    );

    await _verifyClassTeacher(
      schoolId: schoolId,
      classTeacherId: classTeacherId,
    );

    final existing = await _sections
        .where('schoolId', isEqualTo: schoolId)
        .where('classId', isEqualTo: classId)
        .get();

    final duplicate = existing.docs.any((doc) {
      return (doc.data()['name'] as String? ?? '')
              .trim()
              .toLowerCase() ==
          normalizedName.toLowerCase();
    });

    if (duplicate) {
      throw Exception('Is class mein yeh section pehle se mojood hai.');
    }

    final now = DateTime.now();

    final section = SchoolSection(
      id: '',
      schoolId: schoolId,
      classId: classId,
      name: normalizedName,
      academicYearId: academicYearId,
      classTeacherId: _normalizeTeacherId(classTeacherId),
      capacity: capacity,
      isActive: true,
      createdAt: now,
      updatedAt: now,
    );

    await _sections.add(section.toMap());
  }

  Future<void> updateSection({
    required String sectionId,
    required String schoolId,
    required String classId,
    required String name,
    String? academicYearId,
    String? classTeacherId,
    int? capacity,
    required bool isActive,
  }) async {
    final normalizedName = name.trim();

    _validateSectionInput(
      schoolId: schoolId,
      classId: classId,
      name: normalizedName,
      capacity: capacity,
    );

    final sectionRef = _sections.doc(sectionId);
    final currentSnapshot = await sectionRef.get();

    if (!currentSnapshot.exists ||
        currentSnapshot.data()?['schoolId'] != schoolId) {
      throw Exception(
        'Section nahi mila ya school access match nahi karta.',
      );
    }

    await _verifyClass(
      schoolId: schoolId,
      classId: classId,
    );

    await _verifyClassTeacher(
      schoolId: schoolId,
      classTeacherId: classTeacherId,
    );

    final existing = await _sections
        .where('schoolId', isEqualTo: schoolId)
        .where('classId', isEqualTo: classId)
        .get();

    final duplicate = existing.docs.any((doc) {
      if (doc.id == sectionId) return false;

      return (doc.data()['name'] as String? ?? '')
              .trim()
              .toLowerCase() ==
          normalizedName.toLowerCase();
    });

    if (duplicate) {
      throw Exception('Is class mein yeh section pehle se mojood hai.');
    }

    await sectionRef.update({
      'classId': classId,
      'name': normalizedName,
      'academicYearId': academicYearId,
      'classTeacherId': _normalizeTeacherId(classTeacherId),
      'capacity': capacity,
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Assigns or changes the Class Teacher for an existing section.
  ///
  /// [classTeacherId] must be the teacher's Firebase Authentication UID,
  /// which is also the document ID in the users collection.
  Future<void> assignClassTeacher({
    required String schoolId,
    required String sectionId,
    required String classTeacherId,
  }) async {
    final normalizedSchoolId = schoolId.trim();
    final normalizedSectionId = sectionId.trim();
    final normalizedTeacherId = classTeacherId.trim();

    if (normalizedSchoolId.isEmpty) {
      throw ArgumentError('School ID available nahi hai.');
    }

    if (normalizedSectionId.isEmpty) {
      throw ArgumentError('Section select karein.');
    }

    if (normalizedTeacherId.isEmpty) {
      throw ArgumentError('Class Teacher select karein.');
    }

    final sectionRef = _sections.doc(normalizedSectionId);
    final sectionSnapshot = await sectionRef.get();

    if (!sectionSnapshot.exists ||
        sectionSnapshot.data()?['schoolId'] != normalizedSchoolId) {
      throw Exception(
        'Section nahi mila ya school se belong nahi karta.',
      );
    }

    await _verifyClassTeacher(
      schoolId: normalizedSchoolId,
      classTeacherId: normalizedTeacherId,
    );

    await sectionRef.update({
      'classTeacherId': normalizedTeacherId,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Removes the Class Teacher from a section without deleting the account.
  Future<void> removeClassTeacher({
    required String schoolId,
    required String sectionId,
  }) async {
    final normalizedSchoolId = schoolId.trim();
    final normalizedSectionId = sectionId.trim();

    if (normalizedSchoolId.isEmpty ||
        normalizedSectionId.isEmpty) {
      throw ArgumentError('School ID aur section ID zaroori hain.');
    }

    final sectionRef = _sections.doc(normalizedSectionId);
    final snapshot = await sectionRef.get();

    if (!snapshot.exists ||
        snapshot.data()?['schoolId'] != normalizedSchoolId) {
      throw Exception(
        'Section nahi mila ya school se belong nahi karta.',
      );
    }

    await sectionRef.update({
      'classTeacherId': FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> setSectionActive({
    required String sectionId,
    required bool isActive,
    required String schoolId,
  }) async {
    final sectionRef = _sections.doc(sectionId);
    final snapshot = await sectionRef.get();

    if (!snapshot.exists ||
        snapshot.data()?['schoolId'] != schoolId) {
      throw Exception(
        'Section nahi mila ya school access match nahi karta.',
      );
    }

    await sectionRef.update({
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _verifyClass({
    required String schoolId,
    required String classId,
  }) async {
    final snapshot = await _classes.doc(classId).get();

    if (!snapshot.exists ||
        snapshot.data()?['schoolId'] != schoolId) {
      throw Exception(
        'Selected class nahi mili ya school se belong nahi karti.',
      );
    }
  }

  Future<void> _verifyClassTeacher({
    required String schoolId,
    required String? classTeacherId,
  }) async {
    final teacherId = _normalizeTeacherId(classTeacherId);

    // No teacher is also a valid option while creating/editing a section.
    if (teacherId == null) return;

    final teacherSnapshot = await _users.doc(teacherId).get();

    if (!teacherSnapshot.exists) {
      throw Exception(
        'Selected teacher ka Firebase user profile nahi mila.',
      );
    }

    final teacher = teacherSnapshot.data()!;

    if (teacher['schoolId'] != schoolId) {
      throw Exception(
        'Selected teacher is school se belong nahi karta.',
      );
    }

    if (teacher['role'] != 'classTeacher') {
      throw Exception(
        'Selected staff member ka role Class Teacher nahi hai.',
      );
    }

    if (teacher['isActive'] == false) {
      throw Exception(
        'Selected Class Teacher ka account inactive hai.',
      );
    }
  }

  String? _normalizeTeacherId(String? value) {
    final normalized = value?.trim();

    if (normalized == null || normalized.isEmpty) {
      return null;
    }

    return normalized;
  }

  void _validateSectionInput({
    required String schoolId,
    required String classId,
    required String name,
    required int? capacity,
  }) {
    if (schoolId.trim().isEmpty) {
      throw ArgumentError('School ID available nahi hai.');
    }

    if (classId.trim().isEmpty) {
      throw ArgumentError('Class select karein.');
    }

    if (name.isEmpty) {
      throw ArgumentError('Section ka naam enter karein.');
    }

    if (capacity != null && capacity <= 0) {
      throw ArgumentError('Capacity zero se zyada honi chahiye.');
    }
  }
}
