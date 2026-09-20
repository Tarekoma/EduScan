import 'package:attendance_management/core/di/injection.dart';
import 'package:attendance_management/core/enums/worker_job_title.dart';
import 'package:attendance_management/core/theme/app_theme.dart';
import 'package:attendance_management/features/qr/domain/entities/id_card_data.dart';
import 'package:attendance_management/features/qr/presentation/widgets/qr_person_picker.dart';
import 'package:attendance_management/features/students/domain/entities/student.dart';
import 'package:attendance_management/features/students/domain/usecases/student_usecases.dart';
import 'package:attendance_management/features/students/presentation/cubit/students_cubit.dart';
import 'package:attendance_management/features/workers/domain/entities/worker.dart';
import 'package:attendance_management/features/workers/domain/usecases/worker_usecases.dart';
import 'package:attendance_management/features/workers/presentation/cubit/workers_cubit.dart';
import 'package:attendance_management/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockWatchStudents extends Mock implements WatchStudents {}

class _MockCreateStudent extends Mock implements CreateStudent {}

class _MockUpdateStudent extends Mock implements UpdateStudent {}

class _MockDeleteStudent extends Mock implements DeleteStudent {}

class _MockWatchWorkers extends Mock implements WatchWorkers {}

class _MockCreateWorker extends Mock implements CreateWorker {}

class _MockUpdateWorker extends Mock implements UpdateWorker {}

class _MockDeleteWorker extends Mock implements DeleteWorker {}

const _students = [
  Student(
    studentId: 'STU_00001',
    fullName: 'Adam Khaled',
    className: 'Senior A',
    qrCodeId: 'qr-1',
  ),
  Student(
    studentId: 'STU_00002',
    fullName: 'ادم خالد',
    className: 'Senior B',
    qrCodeId: 'qr-2',
  ),
];

/// Roster the mocked use case streams; tests can swap it.
List<Student> _roster = _students;

const _workers = [
  Worker(
    workerId: 'WRK_00001',
    fullName: 'Sara Ali',
    jobTitle: WorkerJobTitle.teacher,
    qrCodeId: 'qr-w1',
  ),
];

Widget _host(Widget child) => MaterialApp(
  theme: AppTheme.light,
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: AppLocalizations.supportedLocales,
  home: child,
);

void main() {
  setUp(() {
    final watchStudents = _MockWatchStudents();
    when(() => watchStudents()).thenAnswer((_) => Stream.value(_roster));
    final watchWorkers = _MockWatchWorkers();
    when(() => watchWorkers()).thenAnswer((_) => Stream.value(_workers));
    sl
      ..registerFactory(
        () => StudentsCubit(
          watchStudents: watchStudents,
          createStudent: _MockCreateStudent(),
          updateStudent: _MockUpdateStudent(),
          deleteStudent: _MockDeleteStudent(),
        ),
      )
      ..registerFactory(
        () => WorkersCubit(
          watchWorkers: watchWorkers,
          createWorker: _MockCreateWorker(),
          updateWorker: _MockUpdateWorker(),
          deleteWorker: _MockDeleteWorker(),
        ),
      );
  });

  tearDown(() {
    _roster = _students;
    return sl.reset();
  });

  /// Mirrors how the Data page hosts the picker: inside a TabBarView, kept
  /// alive, under a Scaffold.
  Widget tabHost({
    ValueChanged<IdCardData>? onOpen,
    ValueChanged<List<IdCardData>>? onConfirm,
  }) {
    return _host(
      DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            bottom: const TabBar(
              tabs: [
                Tab(text: 'a'),
                Tab(text: 'b'),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              const SizedBox(),
              _KeepAlive(
                child: QrPersonPicker(
                  hint: 'hint',
                  onOpen: onOpen,
                  onConfirm: onConfirm ?? (_) {},
                  confirmLabel: (l10n, n) => 'Print ($n)',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  testWidgets('renders students, selects all, then confirms', (tester) async {
    List<IdCardData>? confirmed;
    await tester.pumpWidget(tabHost(onConfirm: (c) => confirmed = c));
    await tester.tap(find.text('b'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    expect(find.text('Adam Khaled'), findsOneWidget);
    await tester.tap(find.text('Select all'));
    await tester.pump();
    expect(find.text('Print (2)'), findsOneWidget);

    await tester.tap(find.text('Print (2)'));
    expect(confirmed!.map((c) => c.personId), ['STU_00001', 'STU_00002']);
  });

  testWidgets(
    'tapping a name opens that person; selection survives switching',
    (tester) async {
      IdCardData? opened;
      await tester.pumpWidget(tabHost(onOpen: (c) => opened = c));
      await tester.tap(find.text('b'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Adam Khaled'));
      expect(opened?.qrValue, 'qr-1');

      await tester.tap(find.byType(Checkbox).first);
      await tester.pump();
      await tester.tap(find.text('Workers'));
      await tester.pumpAndSettle();
      expect(find.text('Sara Ali'), findsOneWidget);
      expect(find.text('Print (1)'), findsOneWidget);
    },
  );

  testWidgets('header hides when scrolling down and returns on scroll up', (
    tester,
  ) async {
    _roster = [
      for (var i = 0; i < 40; i++)
        Student(
          studentId: 'STU_${i.toString().padLeft(5, '0')}',
          fullName: 'Student $i',
          className: 'Senior A',
          qrCodeId: 'qr-$i',
        ),
    ];
    await tester.pumpWidget(tabHost());
    await tester.tap(find.text('b'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.info_outline), findsOneWidget);

    await tester.drag(find.byType(ListView).first, const Offset(0, -600));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.info_outline), findsNothing);

    await tester.drag(find.byType(ListView).first, const Offset(0, 120));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.info_outline), findsOneWidget);
  });
}

class _KeepAlive extends StatefulWidget {
  const _KeepAlive({required this.child});

  final Widget child;

  @override
  State<_KeepAlive> createState() => _KeepAliveState();
}

class _KeepAliveState extends State<_KeepAlive>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
