
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:school_models/school_models.dart';
import 'package:school_core/school_core.dart';

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

  // Load active subjects belonging to this school.
  Future<List<Subject>> getSubjects(String schoolId) async {
    final result = await _subjects
        .where('schoolId', isEqualTo: schoolId)
        .get();

    final subjects = result.docs
        .map((doc) => Subject.fromMap(doc.id, doc.data()))
        .where((subject) => subject.isActive)
        .toList();

    subjects.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );

    return subjects;
  }

  // Load active class and subject teachers from users.
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

  // Load active assignments for a particular section.
  Future<List<TeacherAssignment>> getAssignments({
    required String schoolId,
    required String sectionId,
  }) async {
    final result = await _assignments
        .where('schoolId', isEqualTo: schoolId)
        .where('sectionId', isEqualTo: sectionId)
        .where('isActive', isEqualTo: true)
        .get();

    return result.docs
        .map((doc) => TeacherAssignment.fromMap(doc.id, doc.data()))
        .toList();
  }

  // Create a subject.
  Future<void> addSubject({
    required String schoolId,
    required String name,
    String? code,
  }) async {
    final cleanName = name.trim();

    if (schoolId.trim().isEmpty || cleanName.isEmpty) {
      throw ArgumentError(
        'School aur subject name required hain.',
      );
    }

    await _subjects.add({
      'schoolId': schoolId,
      'name': cleanName,
      'code': code?.trim().isEmpty == true
          ? null
          : code?.trim(),
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Create a staff login account through the trusted Firebase Function.
  // The function creates both Firebase Authentication and users profile.
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
      final callable =
          _functions.httpsCallable('createStaffAccount');

      final result = await callable.call<Map<String, dynamic>>({
        'name': cleanName,
        'email': cleanEmail,
        'password': password,
        'role': role,
      });

      final data = result.data;
      final uid = data['uid'] as String?;

      if (data['success'] != true ||
          uid == null ||
          uid.isEmpty) {
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

  // Assign or change a teacher for a subject in a section.
  Future<void> assignTeacher({
    required String schoolId,
    required String teacherId,
    required String classId,
    required String sectionId,
    required String subjectId,
    String? academicYearId,
  }) async {
    if (schoolId.isEmpty ||
        teacherId.isEmpty ||
        classId.isEmpty ||
        sectionId.isEmpty ||
        subjectId.isEmpty) {
      throw ArgumentError(
        'Assignment ki tamam required values select karein.',
      );
    }

    final teacherDoc = await _users.doc(teacherId).get();
    final teacherData = teacherDoc.data();

    if (!teacherDoc.exists ||
        teacherData == null ||
        teacherData['schoolId'] != schoolId ||
        !['classTeacher', 'subjectTeacher']
            .contains(teacherData['role']) ||
        teacherData['isActive'] == false) {
      throw StateError(
        'Selected teacher valid ya active nahi hai.',
      );
    }

    final subjectDoc = await _subjects.doc(subjectId).get();
    final subjectData = subjectDoc.data();

    if (!subjectDoc.exists ||
        subjectData == null ||
        subjectData['schoolId'] != schoolId ||
        subjectData['isActive'] == false) {
      throw StateError(
        'Selected subject is school ka valid subject nahi hai.',
      );
    }

    // One assignment document per section and subject.
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
    });
  }

  // Soft-delete an assignment so its history is retained.
  Future<void> removeAssignment(String assignmentId) async {
    await _assignments.doc(assignmentId).update({
      'isActive': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}