import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_core/school_core.dart';
import 'package:school_models/school_models.dart';

final schoolReportsRepositoryProvider =
    Provider<SchoolReportsRepository>((ref) {
  return SchoolReportsRepository(
    firestore: FirebaseFirestore.instance,
  );
});

class SchoolReportsRepository {
  SchoolReportsRepository({
    required FirebaseFirestore firestore,
  }) : _db = firestore;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _classes =>
      _db.collection(FirestoreCollections.classes);

  CollectionReference<Map<String, dynamic>> get _sections =>
      _db.collection(FirestoreCollections.sections);

  CollectionReference<Map<String, dynamic>> get _students =>
      _db.collection(FirestoreCollections.students);

  CollectionReference<Map<String, dynamic>> get _tests =>
      _db.collection(FirestoreCollections.tests);

  CollectionReference<Map<String, dynamic>> get _marks =>
      _db.collection(FirestoreCollections.studentMarks);

  /// Normalizes subject names for grouping in reports.
  ///
  /// Math, Maths, and Mathematics are treated as the same subject.
  /// Other subjects are grouped by their case-insensitive normalized name,
  /// with repeated whitespace collapsed.
  String _subjectGroupKey(String subjectName) {
    final normalized = subjectName
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), ' ');

    final compact = normalized.replaceAll(RegExp(r'[^a-z0-9]'), '');

    if (const {'math', 'maths', 'mathematics'}.contains(compact)) {
      return 'math';
    }

    return normalized;
  }

  /// Provides a consistent display name for known aliases.
  String _subjectDisplayName(String subjectName) {
    final trimmed = subjectName.trim();

    if (trimmed.isEmpty) return 'Unknown Subject';

    final compact = trimmed
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '');

    if (const {'math', 'maths', 'mathematics'}.contains(compact)) {
      return 'Math';
    }

    return trimmed;
  }

  Future<List<SchoolClass>> getClasses(String schoolId) async {
    if (schoolId.trim().isEmpty) {
      throw ArgumentError('School ID missing hai.');
    }

    final snapshot = await _classes
        .where('schoolId', isEqualTo: schoolId)
        .get();

    final classes = snapshot.docs
        .where((doc) => doc.data()['isActive'] != false)
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

  Future<List<Map<String, dynamic>>> getSections({
    required String schoolId,
    required String classId,
  }) async {
    if (schoolId.trim().isEmpty || classId.trim().isEmpty) {
      throw ArgumentError('School aur class select karein.');
    }

    final snapshot = await _sections
        .where('schoolId', isEqualTo: schoolId)
        .where('classId', isEqualTo: classId)
        .get();

    final sections = snapshot.docs
        .where((doc) => doc.data()['isActive'] != false)
        .map((doc) => <String, dynamic>{
              'id': doc.id,
              ...doc.data(),
            })
        .toList();

    sections.sort((a, b) {
      final aName = (a['name'] as String? ??
              a['sectionName'] as String? ??
              '')
          .toLowerCase();

      final bName = (b['name'] as String? ??
              b['sectionName'] as String? ??
              '')
          .toLowerCase();

      return aName.compareTo(bName);
    });

    return sections;
  }

  /// Class report mein tamam sections ke same-name subjects combine hote hain.
  /// sectionId diya ho to sirf us section ka data return hota hai.
  /// Sirf published marks report mein shamil hote hain.
  Future<Map<String, dynamic>> getPerformanceReport({
    required String schoolId,
    required String classId,
    String? sectionId,
  }) async {
    if (schoolId.trim().isEmpty || classId.trim().isEmpty) {
      throw ArgumentError('School aur class required hain.');
    }

    final studentsSnapshot = await _students
        .where('schoolId', isEqualTo: schoolId)
        .where('classId', isEqualTo: classId)
        .get();

    final allStudents = studentsSnapshot.docs
        .where((doc) => doc.data()['isActive'] != false)
        .where((doc) {
          if (sectionId == null) return true;
          return doc.data()['sectionId'] == sectionId;
        })
        .map((doc) => <String, dynamic>{
              'id': doc.id,
              ...doc.data(),
            })
        .toList();

    final studentIds = allStudents.map((s) => s['id'] as String).toSet();

    if (studentIds.isEmpty) {
      return {
        'studentCount': 0,
        'publishedMarkCount': 0,
        'overallObtainedMarks': 0.0,
        'overallTotalMarks': 0.0,
        'overallPercentage': 0.0,
        'subjects': <Map<String, dynamic>>[],
        'students': <Map<String, dynamic>>[],
      };
    }

    final marksSnapshot = await _marks
        .where('schoolId', isEqualTo: schoolId)
        .where('classId', isEqualTo: classId)
        .get();

    final publishedMarks = marksSnapshot.docs
        .map((doc) => <String, dynamic>{
              'id': doc.id,
              ...doc.data(),
            })
        .where((mark) => mark['status'] == 'published')
        .where((mark) => studentIds.contains(mark['studentId']))
        .where((mark) {
          if (sectionId == null) return true;
          return mark['sectionId'] == sectionId;
        })
        .where((mark) {
          final obtained =
              (mark['obtainedMarks'] as num?)?.toDouble() ?? 0;

          final total = (mark['totalMarks'] as num?)?.toDouble() ?? 0;

          return total > 0 && obtained >= 0 && obtained <= total;
        })
        .toList();

    // Group subject totals by normalized subject name rather than subjectId,
    // because a subject may have different document IDs in different sections.
    final subjectTotals = <String, Map<String, dynamic>>{};
    final studentTotals = <String, Map<String, dynamic>>{};

    double overallObtained = 0;
    double overallTotal = 0;

    for (final mark in publishedMarks) {
      final subjectId = (mark['subjectId'] as String? ?? '').trim();

      final rawSubjectName =
          (mark['subjectName'] as String? ?? '').trim();

      final subjectName = _subjectDisplayName(rawSubjectName);

      final obtained = (mark['obtainedMarks'] as num).toDouble();
      final total = (mark['totalMarks'] as num).toDouble();
      final studentId = mark['studentId'] as String;

      if (subjectId.isEmpty) continue;

      final subjectKey = _subjectGroupKey(subjectName);

      final subject = subjectTotals.putIfAbsent(subjectKey, () {
        return {
          'subjectId': subjectId,
          'subjectName': subjectName,
          'obtainedMarks': 0.0,
          'totalMarks': 0.0,
          'testCount': 0,
          'studentIds': <String>{},
        };
      });

      subject['obtainedMarks'] =
          (subject['obtainedMarks'] as double) + obtained;

      subject['totalMarks'] =
          (subject['totalMarks'] as double) + total;

      (subject['studentIds'] as Set<String>).add(studentId);

      subject['testCount'] = (subject['testCount'] as int) + 1;

      final student = studentTotals.putIfAbsent(studentId, () {
        final studentData =
            allStudents.firstWhere((s) => s['id'] == studentId);

        return {
          'studentId': studentId,
          'studentName': studentData['name'] as String? ?? 'Unknown Student',
          'obtainedMarks': 0.0,
          'totalMarks': 0.0,
          'subjects': <String, Map<String, dynamic>>{},
        };
      });

      student['obtainedMarks'] =
          (student['obtainedMarks'] as double) + obtained;

      student['totalMarks'] =
          (student['totalMarks'] as double) + total;

      final studentSubjects =
          student['subjects'] as Map<String, Map<String, dynamic>>;

      final studentSubject = studentSubjects.putIfAbsent(subjectKey, () {
        return {
          'subjectId': subjectId,
          'subjectName': subjectName,
          'obtainedMarks': 0.0,
          'totalMarks': 0.0,
        };
      });

      studentSubject['obtainedMarks'] =
          (studentSubject['obtainedMarks'] as double) + obtained;

      studentSubject['totalMarks'] =
          (studentSubject['totalMarks'] as double) + total;

      overallObtained += obtained;
      overallTotal += total;
    }

    final subjects = subjectTotals.values.map((subject) {
      final obtained = subject['obtainedMarks'] as double;
      final total = subject['totalMarks'] as double;
      final ids = subject['studentIds'] as Set<String>;

      return <String, dynamic>{
        'subjectId': subject['subjectId'],
        'subjectName': subject['subjectName'],
        'obtainedMarks': obtained,
        'totalMarks': total,
        'percentage': total > 0 ? obtained / total * 100 : 0.0,
        'testCount': subject['testCount'],
        'studentCount': ids.length,
      };
    }).toList();

    subjects.sort((a, b) =>
        (a['subjectName'] as String).toLowerCase().compareTo(
              (b['subjectName'] as String).toLowerCase(),
            ));

    final students = studentTotals.values.map((student) {
      final obtained = student['obtainedMarks'] as double;
      final total = student['totalMarks'] as double;

      final subjectRows =
          (student['subjects'] as Map<String, Map<String, dynamic>>)
              .values
              .map((subject) {
        final subjectObtained = subject['obtainedMarks'] as double;
        final subjectTotal = subject['totalMarks'] as double;

        return <String, dynamic>{
          ...subject,
          'percentage': subjectTotal > 0
              ? subjectObtained / subjectTotal * 100
              : 0.0,
        };
      }).toList();

      subjectRows.sort((a, b) =>
          (a['subjectName'] as String).toLowerCase().compareTo(
                (b['subjectName'] as String).toLowerCase(),
              ));

      return <String, dynamic>{
        'studentId': student['studentId'],
        'studentName': student['studentName'],
        'obtainedMarks': obtained,
        'totalMarks': total,
        'percentage': total > 0 ? obtained / total * 100 : 0.0,
        'subjects': subjectRows,
      };
    }).toList();

    students.sort((a, b) =>
        (a['studentName'] as String).toLowerCase().compareTo(
              (b['studentName'] as String).toLowerCase(),
            ));

    return {
      'studentCount': allStudents.length,
      'publishedMarkCount': publishedMarks.length,
      'overallObtainedMarks': overallObtained,
      'overallTotalMarks': overallTotal,
      'overallPercentage':
          overallTotal > 0 ? overallObtained / overallTotal * 100 : 0.0,
      'subjects': subjects,
      'students': students,
    };
  }
}