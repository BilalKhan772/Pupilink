
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:school_core/school_core.dart';
import 'package:school_models/school_models.dart';

class SubjectsTeacherRepository {
  SubjectsTeacherRepository({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFirestore _db;
  final FirebaseFunctions _functions;

  CollectionReference<Map<String, dynamic>> get _subjects =>
      _db.collection(FirestoreCollections.subjects);

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection(FirestoreCollections.users);

  CollectionReference<Map<String, dynamic>> get _assignments =>
      _db.collection(FirestoreCollections.teacherAssignments);

  /// Loads subjects belonging to this section.
  ///
  /// Legacy subjects without sectionId remain visible in a section
  /// if that section already has an assignment for the subject.
  /// Existing Firestore documents are not deleted or migrated.
  Future<List<Subject>> getSubjects(
    String schoolId, {
    required String sectionId,
  }) async {
    if (schoolId.trim().isEmpty || sectionId.trim().isEmpty) {
      throw ArgumentError('School ID aur section ID required hain.');
    }

    final results = await Future.wait([
      _subjects.where('schoolId', isEqualTo: schoolId).get(),
      getAssignments(schoolId: schoolId, sectionId: sectionId),
    ]);

    final subjectSnapshot =
        results[0] as QuerySnapshot<Map<String, dynamic>>;
    final assignments = results[1] as List<TeacherAssignment>;

    final assignedSubjectIds = assignments
        .where((assignment) => assignment.isActive)
        .map((assignment) => assignment.subjectId)
        .whereType<String>()
        .toSet();

    final subjects = subjectSnapshot.docs
        .where((doc) {
          final data = doc.data();

          if (data['isActive'] == false) return false;

          final subjectSectionId = data['sectionId'];

          // Newly created section-specific subjects.
          if (subjectSectionId is String &&
              subjectSectionId.isNotEmpty) {
            return subjectSectionId == sectionId;
          }

          // Backward compatibility for existing school-wide subjects:
          // show them only where an existing assignment is present.
          return assignedSubjectIds.contains(doc.id);
        })
        .map((doc) => Subject.fromMap(doc.id, doc.data()))
        .toList();

    subjects.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );

    return subjects;
  }

  /// Loads active teachers from this school.
  Future<List<StaffMember>> getTeachers(String schoolId) async {
    final result = await _users
        .where('schoolId', isEqualTo: schoolId)
        .where(
          'role',
          whereIn: ['classTeacher', 'subjectTeacher'],
        )
        .get();

    final teachers = result.docs.map((doc) {
      final data = doc.data();

      return StaffMember(
        id: doc.id,
        schoolId: data['schoolId'] as String? ?? '',
        name: data['name'] as String? ?? '',
        email: data['email'] as String? ?? '',
        role: data['role'] as String? ?? '',
        status: data['isActive'] == false ? 'inactive' : 'active',
        phone: data['phone'] as String?,
        designation: data['designation'] as String?,
      );
    }).where((teacher) => teacher.isActive).toList();

    teachers.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );

    return teachers;
  }

  /// Loads active assignments for one section.
  Future<List<TeacherAssignment>> getAssignments({
    required String schoolId,
    required String sectionId,
  }) async {
    if (schoolId.trim().isEmpty || sectionId.trim().isEmpty) {
      throw ArgumentError('School ID aur section ID required hain.');
    }

    final result = await _assignments
        .where('schoolId', isEqualTo: schoolId)
        .where('sectionId', isEqualTo: sectionId)
        .where('isActive', isEqualTo: true)
        .get();

    return result.docs
        .map((doc) => TeacherAssignment.fromMap(doc.id, doc.data()))
        .toList();
  }

  /// Creates a subject specifically for this section.
  ///
  /// Existing school-wide subjects and their assignments remain untouched.
  Future<void> addSubject({
    required String schoolId,
    required String sectionId,
    required String name,
    String? code,
  }) async {
    final cleanSchoolId = schoolId.trim();
    final cleanSectionId = sectionId.trim();
    final cleanName = name.trim();
    final cleanCode = code?.trim();

    if (cleanSchoolId.isEmpty ||
        cleanSectionId.isEmpty ||
        cleanName.isEmpty) {
      throw ArgumentError(
        'School, section aur subject name required hain.',
      );
    }

    // Verify the section belongs to this school before creating a subject.
    final sectionDoc =
        await _db.collection(FirestoreCollections.sections).doc(
              cleanSectionId,
            ).get();

    final sectionData = sectionDoc.data();

    if (!sectionDoc.exists ||
        sectionData == null ||
        sectionData['schoolId'] != cleanSchoolId ||
        sectionData['isActive'] == false) {
      throw StateError('Selected section valid ya active nahi hai.');
    }

    // Avoid duplicate active subject names within the same section.
    final existingSubjects = await _subjects
        .where('schoolId', isEqualTo: cleanSchoolId)
        .where('sectionId', isEqualTo: cleanSectionId)
        .get();

    final duplicate = existingSubjects.docs.any((doc) {
      final data = doc.data();

      return data['isActive'] != false &&
          (data['name'] as String? ?? '').trim().toLowerCase() ==
              cleanName.toLowerCase();
    });

    if (duplicate) {
      throw StateError(
        'Is section mein yeh subject pehle se mojood hai.',
      );
    }

    await _subjects.add({
      'schoolId': cleanSchoolId,
      'sectionId': cleanSectionId,
      'name': cleanName,
      'code': cleanCode == null || cleanCode.isEmpty ? null : cleanCode,
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Creates the teacher's Auth account and profile through a trusted
  /// Firebase callable function. The current admin session is retained.
  Future<StaffMember> createTeacherAccount({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    final cleanName = name.trim();
    final cleanEmail = email.trim().toLowerCase();

    if (cleanName.isEmpty) {
      throw ArgumentError('Teacher ka naam enter karein.');
    }

    if (!cleanEmail.contains('@')) {
      throw ArgumentError('Valid email address enter karein.');
    }

    if (password.length < 8 || password.length > 128) {
      throw ArgumentError(
        'Password 8 se 128 characters ka hona chahiye.',
      );
    }

    if (!['classTeacher', 'subjectTeacher'].contains(role)) {
      throw ArgumentError('Teacher role valid nahi hai.');
    }

    try {
      final callable = _functions.httpsCallable('createStaffAccount');

      final result = await callable.call<Map<String, dynamic>>({
        'name': cleanName,
        'email': cleanEmail,
        'password': password,
        'role': role,
      });

      final data = result.data;
      final uid = data['uid'] as String?;

      if (data['success'] != true || uid == null || uid.isEmpty) {
        throw StateError(
          'Function ne successful account response return nahi kiya.',
        );
      }

      return StaffMember(
        id: uid,
        schoolId: data['schoolId'] as String? ?? '',
        name: data['name'] as String? ?? cleanName,
        email: data['email'] as String? ?? cleanEmail,
        role: data['role'] as String? ?? role,
        status: 'active',
      );
    } on FirebaseFunctionsException catch (e) {
      throw StateError(
        'Firebase Function error (${e.code}): '
        '${e.message ?? 'Teacher account create nahi ho saka.'}',
      );
    }
  }

  /// Assigns or changes a teacher for one subject in one section.
  ///
  /// Assignment IDs remain section-specific. Existing assignment documents
  /// are updated in place instead of creating duplicate assignments.
  Future<void> assignTeacher({
    required String schoolId,
    required String teacherId,
    required String classId,
    required String sectionId,
    required String subjectId,
    String? academicYearId,
  }) async {
    if (schoolId.trim().isEmpty ||
        teacherId.trim().isEmpty ||
        classId.trim().isEmpty ||
        sectionId.trim().isEmpty ||
        subjectId.trim().isEmpty) {
      throw ArgumentError(
        'Assignment ki tamam required values select karein.',
      );
    }

    final teacherDoc = await _users.doc(teacherId).get();
    final teacherData = teacherDoc.data();

    if (!teacherDoc.exists ||
        teacherData == null ||
        teacherData['schoolId'] != schoolId ||
        !['classTeacher', 'subjectTeacher'].contains(teacherData['role']) ||
        teacherData['isActive'] == false) {
      throw StateError('Selected teacher valid ya active nahi hai.');
    }

    final sectionDoc =
        await _db.collection(FirestoreCollections.sections).doc(sectionId).get();
    final sectionData = sectionDoc.data();

    if (!sectionDoc.exists ||
        sectionData == null ||
        sectionData['schoolId'] != schoolId ||
        sectionData['classId'] != classId ||
        sectionData['isActive'] == false) {
      throw StateError('Selected section is class/school ka valid section nahi hai.');
    }

    final subjectDoc = await _subjects.doc(subjectId).get();
    final subjectData = subjectDoc.data();

    if (!subjectDoc.exists ||
        subjectData == null ||
        subjectData['schoolId'] != schoolId ||
        subjectData['isActive'] == false) {
      throw StateError('Selected subject is school ka valid subject nahi hai.');
    }

    // A subject explicitly assigned to another section cannot be used here.
    // Legacy subjects without sectionId remain assignable for compatibility.
    final subjectSectionId = subjectData['sectionId'];
    if (subjectSectionId is String &&
        subjectSectionId.isNotEmpty &&
        subjectSectionId != sectionId) {
      throw StateError('Yeh subject kisi doosre section ka hai.');
    }

    final assignmentId = '${sectionId}_$subjectId';
    final reference = _assignments.doc(assignmentId);
    final existing = await reference.get();
    final now = FieldValue.serverTimestamp();

    await reference.set({
      'schoolId': schoolId,
      'teacherId': teacherId,
      'classId': classId,
      'sectionId': sectionId,
      'subjectId': subjectId,
      'academicYearId': academicYearId,
      'assignmentType': 'subjectTeacher',
      'isActive': true,
      if (!existing.exists) 'assignedAt': now,
      'updatedAt': now,
      if (!existing.exists) 'createdAt': now,
    }, SetOptions(merge: true));
  }

  /// Soft-deletes an assignment, preserving its document/history.
  Future<void> removeAssignment(String assignmentId) async {
    await _assignments.doc(assignmentId).update({
      'isActive': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
