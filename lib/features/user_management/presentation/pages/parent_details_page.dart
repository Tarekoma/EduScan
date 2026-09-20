import 'package:flutter/material.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../core/widgets/page_header.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../students/domain/entities/student.dart';
import '../../../students/domain/repositories/student_repository.dart';
import '../../../students/presentation/pages/student_attendance_details_page.dart';

/// Account details for one parent, opened from the Users list. [parent] is
/// passed in from the tapped row; the linked children are fetched by id.
class ParentDetailsPage extends StatefulWidget {
  const ParentDetailsPage({super.key, required this.parent});

  final AppUser parent;

  @override
  State<ParentDetailsPage> createState() => _ParentDetailsPageState();
}

class _ParentDetailsPageState extends State<ParentDetailsPage> {
  late Future<List<Student>> _children = _load();

  /// Fetches each linked student individually and skips ids whose record no
  /// longer exists, so one deleted student doesn't hide the rest.
  Future<List<Student>> _load() async {
    final repo = sl<StudentRepository>();
    final results = await Future.wait(
      widget.parent.studentIds.map((id) async {
        try {
          return await repo.getStudent(id);
        } catch (_) {
          return null;
        }
      }),
    );
    return results.whereType<Student>().toList()
      ..sort((a, b) => a.fullName.compareTo(b.fullName));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final parent = widget.parent;
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 76,
        title: PageHeader(
          title: parent.name,
          subtitle: l10n.parentDetailsSubtitle,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.email_outlined),
                  title: Text(l10n.fieldEmail),
                  subtitle: Text(parent.email),
                ),
                if (parent.phone != null && parent.phone!.isNotEmpty)
                  ListTile(
                    leading: const Icon(Icons.phone_outlined),
                    title: Text(l10n.fieldPhone),
                    subtitle: Text(parent.phone!),
                  ),
                ListTile(
                  leading: const Icon(Icons.verified_user_outlined),
                  title: Text(l10n.accountStatusLabel),
                  trailing: StatusBadge(
                    label: parent.isActive
                        ? l10n.accountStatusActive
                        : l10n.accountStatusInactive,
                    tone: parent.isActive
                        ? BadgeTone.positive
                        : BadgeTone.negative,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.linkedChildrenLabel,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          FutureBuilder<List<Student>>(
            future: _children,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Padding(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: LoadingView(),
                );
              }
              if (snap.hasError) {
                return ErrorView(
                  message: l10n.parentCouldNotLoadChildren,
                  onRetry: () => setState(() => _children = _load()),
                );
              }
              final children = snap.data ?? const <Student>[];
              if (children.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Center(child: Text(l10n.userNoChildrenLinked)),
                );
              }
              return Column(
                children: [
                  for (final s in children)
                    Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text(
                            s.className.isNotEmpty ? s.className[0] : '?',
                          ),
                        ),
                        title: Text(s.fullName),
                        subtitle: Text(
                          l10n.personIdTypeLabel(
                            s.studentId,
                            l10n.personClassLabel(s.className),
                          ),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                StudentAttendanceDetailsPage(student: s),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
