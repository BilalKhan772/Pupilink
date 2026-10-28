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

  CollectionReference<Map<String, dynamic>> get _sections =>
      _db.collection(FirestoreCollections.sections);

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
      throw ArgumentError('School ID and section ID are required.');
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

  /// Loads active teacher accounts from this school.
  ///
  /// The user's profile role is the account's base role. A teacher may still
  /// be assigned as a Class Teacher in one section and a Subject Teacher in
  /// another; those section-specific responsibilities are stored separately.
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

  /// Loads active subject assignments for one section.
  Future<List<TeacherAssignment>> getAssignments({
    required String schoolId,
    required String sectionId,
  }) async {
    if (schoolId.trim().isEmpty || sectionId.trim().isEmpty) {
      throw ArgumentError('School ID and section ID are required.');
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
        'School, section, and subject name are required.',
      );
    }

    final sectionDoc = await _sections.doc(cleanSectionId).get();
    final sectionData = sectionDoc.data();

    if (!sectionDoc.exists ||
        sectionData == null ||
        sectionData['schoolId'] != cleanSchoolId ||
        sectionData['isActive'] == false) {
      throw StateError('The selected section is invalid or inactive.');
    }

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
        'A subject with this name already exists in this section.',
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

  /// Updates the name/code of an existing subject without changing its ID,
  /// active state, section scope, or any teacher assignments.
  Future<void> updateSubject({
    required String schoolId,
    required String sectionId,
    required String subjectId,
    required String name,
    String? code,
  }) async {
    final cleanSchoolId = schoolId.trim();
    final cleanSectionId = sectionId.trim();
    final cleanSubjectId = subjectId.trim();
    final cleanName = name.trim();
    final cleanCode = code?.trim();

    if (cleanSchoolId.isEmpty ||
        cleanSectionId.isEmpty ||
        cleanSubjectId.isEmpty ||
        cleanName.isEmpty) {
      throw ArgumentError(
        'School, section, subject ID, and subject name are required.',
      );
    }

    // Confirm that this section belongs to the selected school.
    final sectionDoc = await _sections.doc(cleanSectionId).get();
    final sectionData = sectionDoc.data();

    if (!sectionDoc.exists ||
        sectionData == null ||
        sectionData['schoolId'] != cleanSchoolId ||
        sectionData['isActive'] == false) {
      throw StateError('The selected section is invalid or inactive.');
    }

    final subjectRef = _subjects.doc(cleanSubjectId);
    final subjectDoc = await subjectRef.get();
    final subjectData = subjectDoc.data();

    if (!subjectDoc.exists ||
        subjectData == null ||
        subjectData['schoolId'] != cleanSchoolId ||
        subjectData['isActive'] == false) {
      throw StateError('The selected subject is invalid or inactive.');
    }

    // Do not let a section-specific screen edit a subject belonging to
    // another section. Legacy school-wide subjects remain editable for
    // backward compatibility; editing one changes that shared record.
    final existingSectionId = subjectData['sectionId'];
    if (existingSectionId is String &&
        existingSectionId.trim().isNotEmpty &&
        existingSectionId != cleanSectionId) {
      throw StateError(
        'This subject belongs to a different section.',
      );
    }

    // Prevent duplicate active subject names within this section.
    // Existing school-wide/legacy subjects are included because they may
    // already be assigned to this section.
    final subjectsSnapshot = await _subjects
        .where('schoolId', isEqualTo: cleanSchoolId)
        .get();

    final duplicate = subjectsSnapshot.docs.any((doc) {
      if (doc.id == cleanSubjectId) return false;

      final data = doc.data();
      if (data['isActive'] == false) return false;

      final otherSectionId = data['sectionId'];
      final belongsToSection = otherSectionId == cleanSectionId ||
          otherSectionId == null ||
          (otherSectionId is String && otherSectionId.trim().isEmpty);

      return belongsToSection &&
          (data['name'] as String? ?? '').trim().toLowerCase() ==
              cleanName.toLowerCase();
    });

    if (duplicate) {
      throw StateError(
        'An active subject with this name already exists in this section.',
      );
    }

    // Do not replace the document ID or touch teacher assignments.
    await subjectRef.update({
      'name': cleanName,
      'code': cleanCode == null || cleanCode.isEmpty ? null : cleanCode,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Creates a teacher's Authentication account and profile through a
  /// trusted callable function. The current admin session is retained.
  Future<StaffMember> createTeacherAccount({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    final cleanName = name.trim();
    final cleanEmail = email.trim().toLowerCase();

    if (cleanName.isEmpty) {
      throw ArgumentError('Enter the teacher name.');
    }

    if (!cleanEmail.contains('@')) {
      throw ArgumentError('Enter a valid email address.');
    }

    if (password.length < 8 || password.length > 128) {
      throw ArgumentError(
        'The password must contain between 8 and 128 characters.',
      );
    }

    if (!['classTeacher', 'subjectTeacher'].contains(role)) {
      throw ArgumentError('The selected teacher role is invalid.');
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
          'The account creation function did not return a valid response.',
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
        '${e.message ?? 'Unable to create the teacher account.'}',
      );
    }
  }

  /// Assigns a teacher to a subject in one section.
  ///
  /// The section/subject pair has one active teacher assignment. Assigning a
  /// different teacher updates that document rather than creating a duplicate.
  Future<void> assignTeacher({
    required String schoolId,
    required String teacherId,
    required String classId,
    required String sectionId,
    required String subjectId,
    String? academicYearId,
  }) async {
    final cleanSchoolId = schoolId.trim();
    final cleanTeacherId = teacherId.trim();
    final cleanClassId = classId.trim();
    final cleanSectionId = sectionId.trim();
    final cleanSubjectId = subjectId.trim();

    if (cleanSchoolId.isEmpty ||
        cleanTeacherId.isEmpty ||
        cleanClassId.isEmpty ||
        cleanSectionId.isEmpty ||
        cleanSubjectId.isEmpty) {
      throw ArgumentError(
        'School, teacher, class, section, and subject are required.',
      );
    }

    final teacherDoc = await _users.doc(cleanTeacherId).get();
    final teacherData = teacherDoc.data();

    if (!teacherDoc.exists ||
        teacherData == null ||
        teacherData['schoolId'] != cleanSchoolId ||
        !['classTeacher', 'subjectTeacher'].contains(teacherData['role']) ||
        teacherData['isActive'] == false) {
      throw StateError('The selected teacher is invalid or inactive.');
    }

    final sectionDoc = await _sections.doc(cleanSectionId).get();
    final sectionData = sectionDoc.data();

    if (!sectionDoc.exists ||
        sectionData == null ||
        sectionData['schoolId'] != cleanSchoolId ||
        sectionData['classId'] != cleanClassId ||
        sectionData['isActive'] == false) {
      throw StateError('The selected section does not match this class/school.');
    }

    final subjectDoc = await _subjects.doc(cleanSubjectId).get();
    final subjectData = subjectDoc.data();

    if (!subjectDoc.exists ||
        subjectData == null ||
        subjectData['schoolId'] != cleanSchoolId ||
        subjectData['isActive'] == false) {
      throw StateError('The selected subject is invalid or inactive.');
    }

    final subjectSectionId = subjectData['sectionId'];
    if (subjectSectionId is String &&
        subjectSectionId.isNotEmpty &&
        subjectSectionId != cleanSectionId) {
      throw StateError('This subject belongs to a different section.');
    }

    final assignmentId = '${cleanSectionId}_$cleanSubjectId';
    final reference = _assignments.doc(assignmentId);
    final existing = await reference.get();
    final now = FieldValue.serverTimestamp();

    await reference.set({
      'schoolId': cleanSchoolId,
      'teacherId': cleanTeacherId,
      'classId': cleanClassId,
      'sectionId': cleanSectionId,
      'subjectId': cleanSubjectId,
      'academicYearId': academicYearId,
      'assignmentType': 'subjectTeacher',
      'isActive': true,
      if (!existing.exists) 'assignedAt': now,
      'updatedAt': now,
      if (!existing.exists) 'createdAt': now,
    }, SetOptions(merge: true));
  }

  /// Assigns a Class Teacher to a section.
  ///
  /// IMPORTANT: a user's profile role is not used to decide their role in
  /// every section. Existing classTeacher and subjectTeacher accounts may
  /// both be assigned as the Class Teacher of a specific section. Their
  /// subject assignments in other sections are not modified.
  Future<void> assignClassTeacher({
    required String schoolId,
    required String teacherId,
    required String classId,
    required String sectionId,
  }) async {
    final cleanSchoolId = schoolId.trim();
    final cleanTeacherId = teacherId.trim();
    final cleanClassId = classId.trim();
    final cleanSectionId = sectionId.trim();

    if (cleanSchoolId.isEmpty ||
        cleanTeacherId.isEmpty ||
        cleanClassId.isEmpty ||
        cleanSectionId.isEmpty) {
      throw ArgumentError(
        'School, teacher, class, and section are required.',
      );
    }

    final teacherDoc = await _users.doc(cleanTeacherId).get();
    final teacherData = teacherDoc.data();

    if (!teacherDoc.exists ||
        teacherData == null ||
        teacherData['schoolId'] != cleanSchoolId ||
        !['classTeacher', 'subjectTeacher'].contains(teacherData['role']) ||
        teacherData['isActive'] == false) {
      throw StateError('The selected teacher is invalid or inactive.');
    }

    final sectionRef = _sections.doc(cleanSectionId);
    final sectionDoc = await sectionRef.get();
    final sectionData = sectionDoc.data();

    if (!sectionDoc.exists ||
        sectionData == null ||
        sectionData['schoolId'] != cleanSchoolId ||
        sectionData['classId'] != cleanClassId ||
        sectionData['isActive'] == false) {
      throw StateError('The selected section does not match this class/school.');
    }

    await sectionRef.update({
      'classTeacherId': cleanTeacherId,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Removes a teacher's Class Teacher assignment only if that teacher is
  /// currently assigned to the specified section.
  ///
  /// This deliberately does not touch any other section and does not modify
  /// the user's global profile role or subject assignment documents.
  Future<void> removeClassTeacherIfAssigned({
    required String schoolId,
    required String sectionId,
    required String teacherId,
  }) async {
    final cleanSchoolId = schoolId.trim();
    final cleanSectionId = sectionId.trim();
    final cleanTeacherId = teacherId.trim();

    if (cleanSchoolId.isEmpty ||
        cleanSectionId.isEmpty ||
        cleanTeacherId.isEmpty) {
      throw ArgumentError(
        'School, section, and teacher are required.',
      );
    }

    final sectionRef = _sections.doc(cleanSectionId);
    final sectionDoc = await sectionRef.get();
    final sectionData = sectionDoc.data();

    if (!sectionDoc.exists ||
        sectionData == null ||
        sectionData['schoolId'] != cleanSchoolId) {
      throw StateError('The selected section does not belong to this school.');
    }

    // Do not clear a different teacher's class-teacher assignment.
    if (sectionData['classTeacherId'] != cleanTeacherId) return;

    await sectionRef.update({
      'classTeacherId': FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Soft-deactivates an assignment while preserving its document/history.
  Future<void> removeAssignment(String assignmentId) async {
    final cleanAssignmentId = assignmentId.trim();
    if (cleanAssignmentId.isEmpty) {
      throw ArgumentError('Assignment ID is required.');
    }

    await _assignments.doc(cleanAssignmentId).update({
      'isActive': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
