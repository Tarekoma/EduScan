import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/enums/worker_job_title_display.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_search_bar.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../students/domain/entities/student.dart';
import '../../../students/presentation/cubit/students_cubit.dart';
import '../../../workers/domain/entities/worker.dart';
import '../../../workers/presentation/cubit/workers_cubit.dart';
import '../../domain/entities/id_card_data.dart';

/// Lets the user pick students and workers whose QR cards should be printed.
///
/// Two sections (students / workers) mirror the management lists without the
/// edit / QR actions. Each row has a checkbox; the header has "select all" for
/// whatever the current search / class filter shows. The selection is kept
/// while switching between the two sections.
///
/// * [onOpen] set: tapping a row opens that one person straight away.
/// * [onOpen] null: tapping a row toggles its checkbox.
///
/// People in [excluded] (by `qrCodeId`) are shown as already added and cannot
/// be picked again.
class QrPersonPicker extends StatefulWidget {
  const QrPersonPicker({
    super.key,
    required this.onConfirm,
    required this.confirmLabel,
    this.onOpen,
    this.hint,
    this.excluded = const {},
  });

  final ValueChanged<IdCardData>? onOpen;
  final ValueChanged<List<IdCardData>> onConfirm;
  final String Function(AppLocalizations l10n, int count) confirmLabel;
  final String? hint;
  final Set<String> excluded;

  @override
  State<QrPersonPicker> createState() => _QrPersonPickerState();
}

class _QrPersonPickerState extends State<QrPersonPicker> {
  final Map<String, IdCardData> _selected = {};
  int _section = 0;

  void _toggle(IdCardData card) => setState(() {
    if (_selected.remove(card.qrValue) == null) {
      _selected[card.qrValue] = card;
    }
  });

  /// Selects every visible card, or clears them if they are all selected.
  void _toggleAll(List<IdCardData> cards) => setState(() {
    final pickable = cards.where((c) => !widget.excluded.contains(c.qrValue));
    if (pickable.every((c) => _selected.containsKey(c.qrValue))) {
      for (final c in pickable) {
        _selected.remove(c.qrValue);
      }
    } else {
      for (final c in pickable) {
        _selected[c.qrValue] = c;
      }
    }
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Scrolls away with the list and floats back on the first scroll up.
    final topBar = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Expanded(
                child: SegmentedButton<int>(
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(
                      value: 0,
                      icon: const Icon(Icons.school_outlined),
                      label: Text(l10n.studentsPageTitle),
                    ),
                    ButtonSegment(
                      value: 1,
                      icon: const Icon(Icons.badge_outlined),
                      label: Text(l10n.workersPageTitle),
                    ),
                  ],
                  selected: {_section},
                  onSelectionChanged: (s) => setState(() => _section = s.first),
                ),
              ),
              // The hint lives behind an (i) so it takes no space until asked.
              if (widget.hint != null)
                Tooltip(
                  message: widget.hint!,
                  triggerMode: TooltipTriggerMode.tap,
                  showDuration: const Duration(seconds: 6),
                  child: const Padding(
                    padding: EdgeInsets.all(AppSpacing.sm),
                    child: Icon(Icons.info_outline),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<StudentsCubit>()..start()),
        BlocProvider(create: (_) => sl<WorkersCubit>()..start()),
      ],
      child: Column(
        children: [
          Expanded(
            child: IndexedStack(
              index: _section,
              children: [
                _StudentsSection(
                  topBar: topBar,
                  selection: _selection,
                  excluded: widget.excluded,
                  onToggle: _toggle,
                  onToggleAll: _toggleAll,
                  onTap: widget.onOpen ?? _toggle,
                ),
                _WorkersSection(
                  topBar: topBar,
                  selection: _selection,
                  excluded: widget.excluded,
                  onToggle: _toggle,
                  onToggleAll: _toggleAll,
                  onTap: widget.onOpen ?? _toggle,
                ),
              ],
            ),
          ),
          if (_selected.isNotEmpty)
            Material(
              elevation: 8,
              color: Theme.of(context).colorScheme.surface,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      TextButton(
                        onPressed: () => setState(_selected.clear),
                        child: Text(l10n.printQrClearSelection),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      // The app theme gives filled buttons infinite width, so
                      // this one must be bounded by an Expanded.
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () =>
                              widget.onConfirm(_selected.values.toList()),
                          icon: const Icon(Icons.print_outlined),
                          label: Text(
                            widget.confirmLabel(l10n, _selected.length),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Set<String> get _selection => _selected.keys.toSet();
}

class _StudentsSection extends StatelessWidget {
  const _StudentsSection({
    required this.topBar,
    required this.selection,
    required this.excluded,
    required this.onToggle,
    required this.onToggleAll,
    required this.onTap,
  });

  final Widget topBar;
  final Set<String> selection;
  final Set<String> excluded;
  final ValueChanged<IdCardData> onToggle;
  final ValueChanged<List<IdCardData>> onToggleAll;
  final ValueChanged<IdCardData> onTap;

  static IdCardData _card(AppLocalizations l10n, Student s) => IdCardData(
    personId: s.studentId,
    fullName: s.fullName,
    qrValue: s.qrCodeId,
    typeLabel: l10n.cardTypeStudent,
    detail: s.className.isEmpty ? null : l10n.personClassLabel(s.className),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<StudentsCubit>();
    return BlocBuilder<StudentsCubit, StudentsState>(
      builder: (context, state) {
        final cards = state.status == StudentsStatus.ready
            ? [for (final s in state.filtered) _card(l10n, s)]
            : const <IdCardData>[];
        return _Section(
          topBar: topBar,
          countLabel: state.all.isEmpty
              ? null
              : l10n.studentsCount(state.filtered.length),
          filters: Row(
            children: [
              Expanded(
                child: AppSearchBar(
                  hintText: l10n.searchStudentsHint,
                  onChanged: cubit.search,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              DropdownMenu<String?>(
                initialSelection: state.classFilter,
                hintText: l10n.allClassesLabel,
                onSelected: cubit.filterByClass,
                dropdownMenuEntries: [
                  DropdownMenuEntry(value: null, label: l10n.allClassesLabel),
                  for (final c in state.classNames)
                    DropdownMenuEntry(value: c, label: c),
                ],
              ),
            ],
          ),
          cards: cards,
          selection: selection,
          excluded: excluded,
          onToggle: onToggle,
          onToggleAll: onToggleAll,
          onTap: onTap,
          emptyState: switch (state.status) {
            StudentsStatus.initial ||
            StudentsStatus.loading => const LoadingView(),
            StudentsStatus.error => ErrorView(
              message: state.errorMessage ?? l10n.studentsCouldNotLoad,
              onRetry: cubit.start,
            ),
            StudentsStatus.ready => EmptyView(
              message: state.all.isEmpty
                  ? l10n.studentsNoneYet
                  : l10n.studentsNoneMatchSearch,
            ),
          },
        );
      },
    );
  }
}

class _WorkersSection extends StatelessWidget {
  const _WorkersSection({
    required this.topBar,
    required this.selection,
    required this.excluded,
    required this.onToggle,
    required this.onToggleAll,
    required this.onTap,
  });

  final Widget topBar;
  final Set<String> selection;
  final Set<String> excluded;
  final ValueChanged<IdCardData> onToggle;
  final ValueChanged<List<IdCardData>> onToggleAll;
  final ValueChanged<IdCardData> onTap;

  static IdCardData _card(BuildContext context, Worker w) => IdCardData(
    personId: w.workerId,
    fullName: w.fullName,
    qrValue: w.qrCodeId,
    typeLabel: AppLocalizations.of(context)!.cardTypeWorker,
    detail: w.jobTitle.label(context),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<WorkersCubit>();
    return BlocBuilder<WorkersCubit, WorkersState>(
      builder: (context, state) {
        final cards = state.status == WorkersStatus.ready
            ? [for (final w in state.filtered) _card(context, w)]
            : const <IdCardData>[];
        return _Section(
          topBar: topBar,
          countLabel: state.all.isEmpty
              ? null
              : l10n.workersCount(state.filtered.length),
          filters: AppSearchBar(
            hintText: l10n.searchWorkersHint,
            onChanged: cubit.search,
          ),
          cards: cards,
          selection: selection,
          excluded: excluded,
          onToggle: onToggle,
          onToggleAll: onToggleAll,
          onTap: onTap,
          emptyState: switch (state.status) {
            WorkersStatus.initial ||
            WorkersStatus.loading => const LoadingView(),
            WorkersStatus.error => ErrorView(
              message: state.errorMessage ?? l10n.workersCouldNotLoad,
              onRetry: cubit.start,
            ),
            WorkersStatus.ready => EmptyView(
              message: state.all.isEmpty
                  ? l10n.workersNoneYet
                  : l10n.workersNoneMatchSearch,
            ),
          },
        );
      },
    );
  }
}

/// Count + "select all" row, filters, and the checkbox list for one section.
class _Section extends StatelessWidget {
  const _Section({
    required this.topBar,
    required this.countLabel,
    required this.filters,
    required this.cards,
    required this.selection,
    required this.excluded,
    required this.onToggle,
    required this.onToggleAll,
    required this.onTap,
    required this.emptyState,
  });

  final Widget topBar;
  final String? countLabel;
  final Widget filters;
  final List<IdCardData> cards;
  final Set<String> selection;
  final Set<String> excluded;
  final ValueChanged<IdCardData> onToggle;
  final ValueChanged<List<IdCardData>> onToggleAll;
  final ValueChanged<IdCardData> onTap;

  /// Shown instead of the list when there is nothing to list.
  final Widget emptyState;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final pickable = cards.where((c) => !excluded.contains(c.qrValue)).toList();
    final allSelected =
        pickable.isNotEmpty &&
        pickable.every((c) => selection.contains(c.qrValue));
    final scaffoldColor = Theme.of(context).scaffoldBackgroundColor;
    return NestedScrollView(
      headerSliverBuilder: (context, _) => [
        SliverFloatingHeader(
          child: ColoredBox(
            color: scaffoldColor,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  topBar,
                  filters,
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      if (countLabel != null)
                        Text(
                          countLabel!,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: pickable.isEmpty
                            ? null
                            : () => onToggleAll(cards),
                        icon: Icon(
                          allSelected ? Icons.deselect : Icons.select_all,
                          size: 20,
                        ),
                        label: Text(
                          allSelected
                              ? l10n.printQrClearSelection
                              : l10n.printQrSelectAll,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: cards.isEmpty
            ? emptyState
            : ListView.separated(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                itemCount: cards.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, i) {
                  final card = cards[i];
                  final already = excluded.contains(card.qrValue);
                  return Card(
                    margin: EdgeInsets.zero,
                    child: ListTile(
                      enabled: !already,
                      onTap: () => onTap(card),
                      leading: Checkbox(
                        value: already || selection.contains(card.qrValue),
                        onChanged: already ? null : (_) => onToggle(card),
                      ),
                      title: Text(card.fullName),
                      subtitle: Text(
                        [
                          card.personId,
                          if (card.detail?.isNotEmpty ?? false) card.detail!,
                          if (already) l10n.printQrAlreadyAdded,
                        ].join(' • '),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
