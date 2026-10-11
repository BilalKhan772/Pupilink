
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_firebase/school_firebase.dart';
import 'package:school_models/school_models.dart';

final classesRepositoryProvider = Provider<ClassesRepository>((ref) {
  return ClassesRepository(firestore: FirestoreClient());
});

class ClassesRepository {
  ClassesRepository({required FirestoreClient firestore})
      : _firestore = firestore;

  final FirestoreClient _firestore;

  CollectionReference<Map<String, dynamic>> get _classes =>
      _firestore.collection(FirestorePaths.classes);

  CollectionReference<Map<String, dynamic>> get _academicYears =>
      _firestore.collection(FirestorePaths.academicYears);

  Future<List<SchoolClass>> getClasses(String schoolId) async {
    final snapshot =
        await _classes.where('schoolId', isEqualTo: schoolId).get();

    final result = snapshot.docs
        .map((doc) => SchoolClass.fromMap(doc.id, doc.data()))
        .toList();

    result.sort((a, b) {
      final order = (a.sortOrder ?? 999999).compareTo(b.sortOrder ?? 999999);
      return order != 0
          ? order
          : a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    return result;
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

  Future<void> addClass({
    required String schoolId,
    required String name,
    String? academicYearId,
    int? sortOrder,
  }) async {
    final normalizedName = name.trim();

    if (normalizedName.isEmpty) {
      throw ArgumentError('Class ka naam enter karein.');
    }

    final existing =
        await _classes.where('schoolId', isEqualTo: schoolId).get();

    final duplicate = existing.docs.any((doc) {
      return (doc.data()['name'] as String? ?? '')
              .trim()
              .toLowerCase() ==
          normalizedName.toLowerCase();
    });

    if (duplicate) {
      throw Exception('Is naam ki class pehle se mojood hai.');
    }

    final now = DateTime.now();

    final schoolClass = SchoolClass(
      id: '',
      schoolId: schoolId,
      name: normalizedName,
      academicYearId: academicYearId,
      sortOrder: sortOrder,
      isActive: true,
      createdAt: now,
      updatedAt: now,
    );

    await _classes.add(schoolClass.toMap());
  }

  Future<void> updateClass({
    required String classId,
    required String schoolId,
    required String name,
    String? academicYearId,
    int? sortOrder,
    required bool isActive,
  }) async {
    final normalizedName = name.trim();

    if (normalizedName.isEmpty) {
      throw ArgumentError('Class ka naam enter karein.');
    }

    final existing =
        await _classes.where('schoolId', isEqualTo: schoolId).get();

    final duplicate = existing.docs.any((doc) {
      if (doc.id == classId) return false;

      return (doc.data()['name'] as String? ?? '')
              .trim()
              .toLowerCase() ==
          normalizedName.toLowerCase();
    });

    if (duplicate) {
      throw Exception('Is naam ki doosri class pehle se mojood hai.');
    }

    final doc = _classes.doc(classId);
    final snapshot = await doc.get();

    if (!snapshot.exists || snapshot.data()?['schoolId'] != schoolId) {
      throw Exception('Class nahi mili ya school access match nahi karta.');
    }

    await doc.update({
      'name': normalizedName,
      'academicYearId': academicYearId,
      'sortOrder': sortOrder,
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> setClassActive({
    required String classId,
    required bool isActive,
    required String schoolId,
  }) async {
    final doc = _classes.doc(classId);
    final snapshot = await doc.get();

    if (!snapshot.exists || snapshot.data()?['schoolId'] != schoolId) {
      throw Exception('Class nahi mili ya school access match nahi karta.');
    }

    await doc.update({
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
