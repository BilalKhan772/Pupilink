
abstract final class FirestorePaths {
  FirestorePaths._();

  static const users = 'users';
  static const schools = 'schools';
  static const students = 'students';
  static const parents = 'parents';
  static const staff = 'staff';
  static const classes = 'classes';
  static const sections = 'sections';
  static const subjects = 'subjects';
  static const attendance = 'attendance';
  static const homework = 'homework';
  static const timetable = 'timetable';
  static const results = 'results';
  static const notifications = 'notifications';
  static const childLinks = 'parentChildLinks';
  static const academicYears = 'academicYears';
  static const schoolTests = 'schoolTests';
  static const examDateSheets = 'examDateSheets';
  static const conversations = 'conversations';
  static const subscriptions = 'subscriptions';
  static const payments = 'payments';
  static const auditLogs = 'auditLogs';

  static String user(String uid) => '$users/$uid';

  static String school(String schoolId) => '$schools/$schoolId';

  static String student(String studentId) => '$students/$studentId';

  static String parent(String parentId) => '$parents/$parentId';

  static String staffMember(String staffId) => '$staff/$staffId';

  static String schoolSubcollection({
    required String schoolId,
    required String collection,
  }) {
    return '${school(schoolId)}/$collection';
  }
}
