import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../application/app_providers.dart';
import '../../application/petji_analytics.dart';
import '../../domain/models.dart';
import '../formatters.dart';
import '../theme/petji_theme.dart';
import '../widgets/calendar_grids.dart';
import '../widgets/calendar_navigator.dart';
import '../widgets/info_card.dart';
import '../widgets/period_scope_selector.dart';

class TimelinePage extends ConsumerStatefulWidget {
  const TimelinePage({super.key, this.focusedEventId});

  final String? focusedEventId;

  @override
  ConsumerState<TimelinePage> createState() => _TimelinePageState();
}

class _TimelinePageState extends ConsumerState<TimelinePage> {
  PeriodScope _scope = PeriodScope.month;
  DateTime? _anchor;
  String? _handledFocusedEventId;

  @override
  Widget build(BuildContext context) {
    final snapshot = ref.watch(appSnapshotProvider);
    final pet = snapshot.currentPet;
    if (pet == null) {
      return const Center(child: Text('请先登记宠物'));
    }
    final events =
        snapshot.timelineEvents
            .where((event) => event.deletedAt == null && event.petId == pet.id)
            .toList()
          ..sort((a, b) => b.happenedAt.compareTo(a.happenedAt));
    _anchor ??= events.isEmpty ? snapshot.exportedAt : events.first.happenedAt;
    final focusedEventId = widget.focusedEventId;
    if (focusedEventId != null && focusedEventId != _handledFocusedEventId) {
      final focused = events.where((event) => event.id == focusedEventId);
      if (focused.isNotEmpty) {
        _anchor = focused.first.happenedAt;
        _scope = PeriodScope.day;
        _handledFocusedEventId = focusedEventId;
      }
    }
    final anchor = _anchor!;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '成长线',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            FilledButton.icon(
              onPressed: () => _showAddDialog(context, anchor),
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: const Text('添加成长记录'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text('按年度图谱、月份故事板和每日详情整理成长事件。'),
        const SizedBox(height: 14),
        CalendarNavigator(
          semanticLabel: '成长线日历导航',
          scope: _scope,
          label: _periodLabel(anchor),
          onPrevious: () => setState(() => _anchor = _previous(anchor)),
          onNext: () => setState(() => _anchor = _next(anchor)),
        ),
        const SizedBox(height: 14),
        Align(
          alignment: Alignment.centerLeft,
          child: PeriodScopeSelector(
            selected: _scope,
            onChanged: (scope) => setState(() => _scope = scope),
          ),
        ),
        const SizedBox(height: 18),
        switch (_scope) {
          PeriodScope.year => _buildYearView(events, anchor),
          PeriodScope.month => _buildMonthView(events, anchor),
          PeriodScope.day => _buildDayView(events, anchor),
        },
      ],
    );
  }

  Widget _buildYearView(List<TimelineEvent> events, DateTime anchor) {
    final summaries = summarizeTimelineByMonthForPet(
      events,
      petId: ref.read(appSnapshotProvider).currentPet!.id,
      year: anchor.year,
    );
    return InfoCard(
      title: '${anchor.year} 年成长图谱',
      icon: Icons.auto_awesome_motion_outlined,
      child: YearMonthCalendarGrid(
        semanticLabel: '成长线年度月历',
        months: [
          for (var month = 1; month <= 12; month += 1)
            _timelineMonthCell(
              month: month,
              summary: summaries[month],
              selected: month == anchor.month,
              onTap: () => setState(() {
                _scope = PeriodScope.month;
                _anchor = DateTime(anchor.year, month);
              }),
            ),
        ],
      ),
    );
  }

  Widget _buildMonthView(List<TimelineEvent> events, DateTime anchor) {
    final summaries = summarizeTimelineByDayForPet(
      events,
      petId: ref.read(appSnapshotProvider).currentPet!.id,
      year: anchor.year,
      month: anchor.month,
    );
    return InfoCard(
      title: '${anchor.year}-${anchor.month.toString().padLeft(2, '0')} 月份故事板',
      icon: Icons.view_agenda_outlined,
      child: MonthDayCalendarGrid(
        semanticLabel: '成长线月历格子',
        year: anchor.year,
        month: anchor.month,
        dayBuilder: (day) {
          final summary = summaries[day];
          return _timelineDayCell(
            day: day,
            summary: summary,
            selected: day == anchor.day,
            onTap: () => setState(() {
              _scope = PeriodScope.day;
              _anchor = DateTime(anchor.year, anchor.month, day);
            }),
          );
        },
      ),
    );
  }

  Widget _buildDayView(List<TimelineEvent> events, DateTime anchor) {
    final visible =
        events
            .where(
              (event) =>
                  event.happenedAt.year == anchor.year &&
                  event.happenedAt.month == anchor.month &&
                  event.happenedAt.day == anchor.day,
            )
            .toList()
          ..sort((a, b) => b.happenedAt.compareTo(a.happenedAt));
    return InfoCard(
      title: '${dateLabel(anchor)} 成长记录',
      icon: Icons.today_outlined,
      child: visible.isEmpty
          ? const Text('这一天还没有成长记录。')
          : Column(
              children: [
                for (final item in visible)
                  _TimelineTile(
                    event: item,
                    focused: item.id == widget.focusedEventId,
                    onTap: () => _showEventDetail(context, item),
                    onDelete: () => _confirmDeleteEvent(context, item),
                  ),
              ],
            ),
    );
  }

  void _showAddDialog(BuildContext context, DateTime anchor) {
    final controller = ref.read(appSnapshotProvider.notifier);
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return _TimelineAddDialog(
          initialDate: DateTime(anchor.year, anchor.month, anchor.day),
          onPickMedia: _pickManagedMedia,
          onSave: (event) {
            controller.addTimelineEvent(
              happenedAt: event.date,
              title: event.title,
              note: event.description,
              mediaPath: event.mediaPath,
            );
            setState(() {
              _anchor = event.date;
              _scope = PeriodScope.day;
            });
            Navigator.of(dialogContext).pop();
            _showMessage(context, '成长记录已保存');
          },
        );
      },
    );
  }

  Future<String?> _pickManagedMedia() async {
    final picked = await ImagePicker().pickMedia();
    if (picked == null) {
      return null;
    }
    final root = await getApplicationDocumentsDirectory();
    final directory = Directory(p.join(root.path, 'petji', 'media'));
    await directory.create(recursive: true);
    final target = File(
      p.join(
        directory.path,
        '${DateTime.now().microsecondsSinceEpoch}_${p.basename(picked.path)}',
      ),
    );
    await File(picked.path).copy(target.path);
    return target.path;
  }

  void _showEventDetail(BuildContext context, TimelineEvent event) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            children: [
              Text('成长记录详情', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              Text(event.title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                '${dateLabel(event.happenedAt)} · ${timelineEventTypeLabel(event.type)}',
              ),
              if (event.note != null && event.note!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(event.note!),
              ],
              if (event.mediaPath != null || event.filePath != null) ...[
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.attach_file),
                  title: const Text('附件'),
                  subtitle: Text(event.mediaPath ?? event.filePath!),
                ),
              ],
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(sheetContext).pop(),
                  child: const Text('关闭'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmDeleteEvent(BuildContext context, TimelineEvent event) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('删除成长记录'),
        content: Text('确认删除“${event.title}”？此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () {
              ref
                  .read(appSnapshotProvider.notifier)
                  .deleteTimelineEvent(event.id);
              Navigator.of(dialogContext).pop();
              _showMessage(context, '成长记录已删除');
            },
            child: const Text('确认删除'),
          ),
        ],
      ),
    );
  }

  DateTime _previous(DateTime anchor) => switch (_scope) {
    PeriodScope.year => DateTime(anchor.year - 1),
    PeriodScope.month => DateTime(anchor.year, anchor.month - 1),
    PeriodScope.day => anchor.subtract(const Duration(days: 1)),
  };

  DateTime _next(DateTime anchor) => switch (_scope) {
    PeriodScope.year => DateTime(anchor.year + 1),
    PeriodScope.month => DateTime(anchor.year, anchor.month + 1),
    PeriodScope.day => anchor.add(const Duration(days: 1)),
  };

  String _periodLabel(DateTime anchor) {
    final month = anchor.month.toString().padLeft(2, '0');
    return switch (_scope) {
      PeriodScope.year => '${anchor.year}',
      PeriodScope.month => '${anchor.year}-$month',
      PeriodScope.day => dateLabel(anchor),
    };
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _TimelineAddDialog extends StatefulWidget {
  const _TimelineAddDialog({
    required this.initialDate,
    required this.onPickMedia,
    required this.onSave,
  });

  final DateTime initialDate;
  final Future<String?> Function() onPickMedia;
  final ValueChanged<_TimelineDraft> onSave;

  @override
  State<_TimelineAddDialog> createState() => _TimelineAddDialogState();
}

class _TimelineAddDialogState extends State<_TimelineAddDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  late DateTime _date = widget.initialDate;
  String? _mediaPath;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('添加成长记录'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                label: '成长记录标题输入框',
                textField: true,
                child: TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: '事件标题'),
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? '请输入事件标题' : null,
                ),
              ),
              const SizedBox(height: 12),
              Semantics(
                label: '成长记录描述输入框',
                textField: true,
                child: TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: '具体描述（可选）'),
                  minLines: 2,
                  maxLines: 3,
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  final selected = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                    confirmText: '确定',
                    cancelText: '取消',
                  );
                  if (selected != null) {
                    setState(() => _date = selected);
                  }
                },
                icon: const Icon(Icons.event_outlined),
                label: Text(dateLabel(_date)),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () async {
                  final path = await widget.onPickMedia();
                  if (mounted && path != null) {
                    setState(() => _mediaPath = path);
                  }
                },
                icon: const Icon(Icons.attach_file),
                label: Text(_mediaPath == null ? '选择照片或视频' : '已选择媒体'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) {
              return;
            }
            widget.onSave(
              _TimelineDraft(
                date: _date,
                title: _titleController.text.trim(),
                description: _descriptionController.text.trim(),
                mediaPath: _mediaPath,
              ),
            );
          },
          child: const Text('保存成长记录'),
        ),
      ],
    );
  }
}

CalendarGridCellData _timelineMonthCell({
  required int month,
  required TimelinePeriodSummary? summary,
  required bool selected,
  required VoidCallback onTap,
}) {
  final eventCount = summary?.eventCount ?? 0;
  final mediaCount = summary?.mediaCount ?? 0;
  return CalendarGridCellData(
    title: '$month月',
    subtitle: eventCount == 0 ? '0条' : '事件$eventCount条\n媒体$mediaCount条',
    selected: selected,
    hasContent: eventCount > 0,
    semanticLabel: '$month月成长线 $eventCount条事件',
    onTap: onTap,
  );
}

CalendarGridCellData _timelineDayCell({
  required int day,
  required TimelinePeriodSummary? summary,
  required bool selected,
  required VoidCallback onTap,
}) {
  final eventCount = summary?.eventCount ?? 0;
  return CalendarGridCellData(
    title: '$day号',
    subtitle: eventCount == 0 ? null : '$eventCount条事件',
    selected: selected,
    hasContent: eventCount > 0,
    semanticLabel: '$day号成长线 $eventCount条事件',
    onTap: onTap,
  );
}

class _TimelineTile extends StatelessWidget {
  const _TimelineTile({
    required this.event,
    required this.focused,
    required this.onTap,
    required this.onDelete,
  });

  final TimelineEvent event;
  final bool focused;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final tile = Card(
      color: focused ? const Color(0xFFFFEDD5) : null,
      child: ListTile(
        onTap: onTap,
        leading: Icon(_iconFor(event.type), color: PetjiColors.primary),
        title: Text(event.title),
        subtitle: event.note == null || event.note!.isEmpty
            ? Text(timelineEventTypeLabel(event.type))
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(timelineEventTypeLabel(event.type)),
                  Text(event.note!),
                ],
              ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: onDelete,
              tooltip: '删除成长记录 ${event.title}',
              icon: const Icon(Icons.delete_outline),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
    if (!focused) {
      return tile;
    }
    return Semantics(
      label: '已聚焦成长记录 ${event.title}',
      container: true,
      child: tile,
    );
  }

  IconData _iconFor(TimelineEventType type) => switch (type) {
    TimelineEventType.photo || TimelineEventType.media => Icons.image_outlined,
    TimelineEventType.video => Icons.play_circle_outline,
    TimelineEventType.vaccine => Icons.vaccines_outlined,
    TimelineEventType.deworming => Icons.health_and_safety_outlined,
    TimelineEventType.report => Icons.description_outlined,
    TimelineEventType.weight => Icons.monitor_weight_outlined,
    _ => Icons.edit_note_outlined,
  };
}

class _TimelineDraft {
  const _TimelineDraft({
    required this.date,
    required this.title,
    required this.description,
    this.mediaPath,
  });

  final DateTime date;
  final String title;
  final String description;
  final String? mediaPath;
}
