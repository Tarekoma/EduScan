import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../locale/locale_cubit.dart';
import '../services/user_provisioner.dart';
import '../theme/theme_cubit.dart';

import '../../features/attendance/attendance_injection.dart';
import '../../features/dashboard/dashboard_injection.dart';
import '../../features/excel/excel_injection.dart';
import '../../features/face_recognition/face_recognition_injection.dart';
import '../../features/auth/auth_injection.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/parent/parent_injection.dart';
import '../../features/pickup/pickup_injection.dart';
import '../../features/pickup/presentation/cubit/pickup_alert_cubit.dart';
import '../../features/qr/qr_injection.dart';
import '../../features/students/students_injection.dart';
import '../../features/user_management/user_management_injection.dart';
import '../../features/workers/workers_injection.dart';
import '../routing/app_router.dart';

/// Global service locator.
///
/// Registration is layered: external SDKs first, then each feature contributes
/// its data sources / repositories / use cases / Cubits, then cross-cutting
/// singletons such as the router.
final GetIt sl = GetIt.instance;

Future<void> configureDependencies() async {
  // ---- External ---------------------------------------------------------
  sl.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
  sl.registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance);
  sl.registerLazySingleton<UserProvisioner>(() => UserProvisioner());
  final prefs = await SharedPreferences.getInstance();

  // ---- Features -------------------------------------------------------
  registerAuthDependencies(sl);
  registerStudentDependencies(sl);
  registerWorkerDependencies(sl);
  registerQrDependencies(sl);
  registerAttendanceDependencies(sl);
  registerUserManagementDependencies(sl);
  registerDashboardDependencies(sl);
  registerExcelDependencies(sl);
  registerFaceRecognitionDependencies(sl);
  registerParentDependencies(sl);
  registerPickupDependencies(sl);
  // Eagerly start the session-lifetime pickup alert watcher.
  sl<PickupAlertCubit>();

  // ---- Cross-cutting -------------------------------------------------
  sl.registerLazySingleton(() => ThemeCubit(prefs));
  sl.registerLazySingleton(() => LocaleCubit(prefs));
  sl.registerLazySingleton(() => AppRouter(sl<AuthCubit>()));
}
