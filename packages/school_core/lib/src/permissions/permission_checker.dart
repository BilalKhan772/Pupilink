import '../enums/user_role.dart';
import 'app_permission.dart';
import 'role_permissions.dart';

class PermissionChecker {
  const PermissionChecker();

  bool hasPermission(
    UserRole role,
    AppPermission permission,
  ) {
    return RolePermissions.forRole(role).contains(permission);
  }

  bool hasAnyPermission(
    UserRole role,
    Iterable<AppPermission> permissions,
  ) {
    final rolePermissions = RolePermissions.forRole(role);

    return permissions.any(rolePermissions.contains);
  }

  bool hasAllPermissions(
    UserRole role,
    Iterable<AppPermission> permissions,
  ) {
    final rolePermissions = RolePermissions.forRole(role);

    return permissions.every(rolePermissions.contains);
  }

  Set<AppPermission> getPermissions(UserRole role) {
    return RolePermissions.forRole(role);
  }
}