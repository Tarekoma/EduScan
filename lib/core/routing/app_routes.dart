/// Centralised route paths and names. Never hard-code route strings in widgets.
abstract final class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';

  // Role home shells (wired up in Phase 3).
  static const String securityHome = '/security';
  static const String securityScan = '/security/scan';
  static const String securityPickup = '/security/pickup';
  static const String securityStudents = '/security/students';
  static const String securityWorkers = '/security/workers';
  static const String securityDashboard = '/security/dashboard';
  static const String managerHome = '/manager';
  static const String supervisorHome = '/supervisor';
  static const String parentHome = '/parent';

  static const String managerDashboard = '/manager/dashboard';
  static const String supervisorDashboard = '/supervisor/dashboard';

  // People management (manager).
  static const String managerStudents = '/manager/students';
  static const String managerStudentForm = '/manager/students/form';
  static const String managerWorkers = '/manager/workers';
  static const String managerWorkerForm = '/manager/workers/form';
  static const String managerUsers = '/manager/users';
  static const String managerExcel = '/manager/excel';

  // People (supervisor, read-only).
  static const String supervisorStudents = '/supervisor/students';
  static const String supervisorWorkers = '/supervisor/workers';
}
