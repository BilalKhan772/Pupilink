import '../enums/user_role.dart';
import 'app_permission.dart';

class RolePermissions {
  RolePermissions._();

  static const Set<AppPermission> superAdminPermissions = {
    AppPermission.viewSchool,
    AppPermission.editSchool,
    AppPermission.manageSchoolSettings,

    AppPermission.viewClasses,
    AppPermission.manageClasses,
    AppPermission.viewSections,
    AppPermission.manageSections,

    AppPermission.viewStaff,
    AppPermission.manageStaff,
    AppPermission.assignTeachers,

    AppPermission.viewSubjects,
    AppPermission.manageSubjects,
    AppPermission.assignSubjects,

    AppPermission.viewStudents,
    AppPermission.manageStudents,

    AppPermission.viewAttendance,
    AppPermission.manageAttendance,

    AppPermission.viewHomework,
    AppPermission.manageHomework,

    AppPermission.viewTimetable,
    AppPermission.manageTimetable,

    AppPermission.viewTests,
    AppPermission.manageTests,
    AppPermission.viewResults,
    AppPermission.manageResults,

    AppPermission.viewReports,
    AppPermission.generateReports,

    AppPermission.viewNotifications,
    AppPermission.manageNotifications,

    AppPermission.viewParentLinks,
    AppPermission.manageParentLinks,

    AppPermission.viewMessages,
    AppPermission.sendMessages,

    AppPermission.viewAuditLogs,
  };

  static const Set<AppPermission> schoolAdminPermissions = {
    AppPermission.viewSchool,
    AppPermission.editSchool,
    AppPermission.manageSchoolSettings,

    AppPermission.viewClasses,
    AppPermission.manageClasses,
    AppPermission.viewSections,
    AppPermission.manageSections,

    AppPermission.viewStaff,
    AppPermission.manageStaff,
    AppPermission.assignTeachers,

    AppPermission.viewSubjects,
    AppPermission.manageSubjects,
    AppPermission.assignSubjects,

    AppPermission.viewStudents,
    AppPermission.manageStudents,

    AppPermission.viewAttendance,
    AppPermission.manageAttendance,

    AppPermission.viewHomework,
    AppPermission.manageHomework,

    AppPermission.viewTimetable,
    AppPermission.manageTimetable,

    AppPermission.viewTests,
    AppPermission.manageTests,
    AppPermission.viewResults,
    AppPermission.manageResults,

    AppPermission.viewReports,
    AppPermission.generateReports,

    AppPermission.viewNotifications,
    AppPermission.manageNotifications,

    AppPermission.viewParentLinks,
    AppPermission.manageParentLinks,

    AppPermission.viewMessages,
    AppPermission.sendMessages,

    AppPermission.viewAuditLogs,
  };

  static const Set<AppPermission> classTeacherPermissions = {
    AppPermission.viewClasses,
    AppPermission.viewSections,

    AppPermission.viewStudents,

    AppPermission.viewAttendance,
    AppPermission.manageAttendance,

    AppPermission.viewHomework,
    AppPermission.manageHomework,

    AppPermission.viewTimetable,

    AppPermission.viewTests,
    AppPermission.viewResults,

    AppPermission.viewReports,

    AppPermission.viewNotifications,

    AppPermission.viewParentLinks,

    AppPermission.viewMessages,
    AppPermission.sendMessages,
  };

  static const Set<AppPermission> subjectTeacherPermissions = {
    AppPermission.viewClasses,
    AppPermission.viewSections,

    AppPermission.viewStudents,

    AppPermission.viewAttendance,
    AppPermission.manageAttendance,

    AppPermission.viewHomework,
    AppPermission.manageHomework,

    AppPermission.viewTimetable,

    AppPermission.viewTests,
    AppPermission.manageTests,

    AppPermission.viewResults,
    AppPermission.manageResults,

    AppPermission.viewReports,

    AppPermission.viewNotifications,

    AppPermission.viewMessages,
    AppPermission.sendMessages,
  };

  static const Set<AppPermission> monitorPermissions = {
    AppPermission.viewClasses,
    AppPermission.viewSections,
    AppPermission.viewStudents,
    AppPermission.viewAttendance,
    AppPermission.viewHomework,
    AppPermission.viewTimetable,
    AppPermission.viewTests,
    AppPermission.viewResults,
    AppPermission.viewNotifications,
  };

  static const Set<AppPermission> parentPermissions = {
    AppPermission.viewStudents,
    AppPermission.viewAttendance,
    AppPermission.viewHomework,
    AppPermission.viewTimetable,
    AppPermission.viewTests,
    AppPermission.viewResults,
    AppPermission.viewNotifications,
    AppPermission.viewMessages,
    AppPermission.sendMessages,
  };

  static const Set<AppPermission> studentPermissions = {
    AppPermission.viewAttendance,
    AppPermission.viewHomework,
    AppPermission.viewTimetable,
    AppPermission.viewTests,
    AppPermission.viewResults,
    AppPermission.viewNotifications,
    AppPermission.viewMessages,
    AppPermission.sendMessages,
  };

  static Set<AppPermission> forRole(UserRole role) {
    switch (role) {
      case UserRole.superAdmin:
        return superAdminPermissions;

      case UserRole.schoolAdmin:
        return schoolAdminPermissions;

      case UserRole.classTeacher:
        return classTeacherPermissions;

      case UserRole.subjectTeacher:
        return subjectTeacherPermissions;

      case UserRole.monitor:
        return monitorPermissions;

      case UserRole.parent:
        return parentPermissions;

      case UserRole.student:
        return studentPermissions;
    }
  }
}