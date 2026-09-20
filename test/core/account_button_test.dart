import 'package:attendance_management/core/locale/locale_cubit.dart';
import 'package:attendance_management/core/theme/app_theme.dart';
import 'package:attendance_management/core/theme/theme_cubit.dart';
import 'package:attendance_management/core/enums/user_role.dart';
import 'package:attendance_management/core/widgets/account_button.dart';
import 'package:attendance_management/features/auth/domain/entities/app_user.dart';
import 'package:attendance_management/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:attendance_management/l10n/app_localizations.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

void main() {
  late _MockAuthCubit auth;
  late ThemeCubit theme;
  late LocaleCubit locale;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    theme = ThemeCubit(prefs);
    locale = LocaleCubit(prefs);
    auth = _MockAuthCubit();
    when(() => auth.state).thenReturn(
      const AuthState(
        status: AuthStatus.authenticated,
        user: AppUser(
          uid: 'u1',
          name: 'Tarek Omar',
          email: 't@example.com',
          role: UserRole.manager,
          isActive: true,
        ),
      ),
    );
    when(() => auth.signOut()).thenAnswer((_) async {});
  });

  Widget host() => MultiBlocProvider(
    providers: [
      BlocProvider<AuthCubit>.value(value: auth),
      BlocProvider<ThemeCubit>.value(value: theme),
      BlocProvider<LocaleCubit>.value(value: locale),
    ],
    child: BlocBuilder<LocaleCubit, Locale>(
      builder: (context, l) => MaterialApp(
        theme: AppTheme.light,
        locale: l,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          appBar: AppBar(
            title: const Text('Page'),
            actions: const [AccountButton()],
          ),
        ),
      ),
    ),
  );

  testWidgets('shows the initial, and the sheet shows name and role', (
    tester,
  ) async {
    await tester.pumpWidget(host());
    expect(find.text('T'), findsOneWidget);

    await tester.tap(find.byType(AccountButton));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Tarek Omar'), findsOneWidget);
    expect(find.text('Manager'), findsOneWidget);
    expect(find.text('Sign out'), findsOneWidget);
  });

  testWidgets('language switch works from the sheet', (tester) async {
    await tester.pumpWidget(host());
    await tester.tap(find.byType(AccountButton));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Switch to Arabic'));
    await tester.pumpAndSettle();
    expect(locale.state.languageCode, 'ar');
    expect(find.text('التبديل إلى الإنجليزية'), findsOneWidget);
  });

  testWidgets('sign out closes the sheet and signs out', (tester) async {
    await tester.pumpWidget(host());
    await tester.tap(find.byType(AccountButton));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();
    verify(() => auth.signOut()).called(1);
    expect(find.text('Sign out'), findsNothing);
  });

  testWidgets('renders nothing when signed out', (tester) async {
    when(() => auth.state).thenReturn(const AuthState());
    await tester.pumpWidget(host());
    expect(find.byType(CircleAvatar), findsNothing);
  });
}
