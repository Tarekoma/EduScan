import 'package:attendance_management/core/theme/app_theme.dart';
import 'package:attendance_management/core/enums/user_role.dart';
import 'package:attendance_management/features/auth/domain/entities/app_user.dart';
import 'package:attendance_management/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:attendance_management/features/auth/presentation/pages/login_page.dart';
import 'package:attendance_management/l10n/app_localizations.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

class _MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

const _user = AppUser(
  uid: 'u1',
  name: 'Tarek',
  email: 't@example.com',
  role: UserRole.manager,
  isActive: true,
);

void main() {
  late _MockAuthCubit auth;
  final autofillCalls = <Object?>[];

  setUp(() {
    auth = _MockAuthCubit();
    autofillCalls.clear();
  });

  /// flutter_test installs its own text-input handler when a test starts, so
  /// ours must be registered from inside the test body.
  void recordAutofillCalls() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.textInput, (call) async {
          if (call.method == 'TextInput.finishAutofillContext') {
            autofillCalls.add(call.arguments);
          }
          return null;
        });
  }

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.textInput, null);
  });

  Widget host() => MaterialApp(
    theme: AppTheme.light,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: BlocProvider<AuthCubit>.value(value: auth, child: const LoginPage()),
  );

  testWidgets('email and password fields carry autofill hints in one group', (
    tester,
  ) async {
    recordAutofillCalls();
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(900, 2400);
    addTearDown(tester.view.reset);
    whenListen(
      auth,
      const Stream<AuthState>.empty(),
      initialState: const AuthState(),
    );
    await tester.pumpWidget(host());

    expect(find.byType(AutofillGroup), findsOneWidget);
    final fields = tester
        .widgetList<TextField>(find.byType(TextField))
        .toList();
    expect(fields[0].autofillHints, contains(AutofillHints.username));
    expect(fields[1].autofillHints, [AutofillHints.password]);
  });

  testWidgets('asks the OS to save only after a successful sign-in', (
    tester,
  ) async {
    recordAutofillCalls();
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(900, 2400);
    addTearDown(tester.view.reset);
    whenListen(
      auth,
      Stream.fromIterable([const AuthState(errorMessage: 'wrong password')]),
      initialState: const AuthState(),
    );
    await tester.pumpWidget(host());
    await tester.pump();
    expect(
      autofillCalls.where((shouldSave) => shouldSave == true),
      isEmpty,
      reason: 'a failed attempt must not ask the OS to save',
    );

    whenListen(
      auth,
      Stream.fromIterable([
        const AuthState(status: AuthStatus.authenticated, user: _user),
      ]),
      initialState: const AuthState(),
    );
    await tester.pumpWidget(Container());
    await tester.pumpWidget(host());
    await tester.pump();
    // Closing the first page cancelled its context (false); the successful
    // sign-in asked the OS to save exactly once (true).
    expect(
      autofillCalls.where((shouldSave) => shouldSave == true),
      hasLength(1),
    );
  });
}
