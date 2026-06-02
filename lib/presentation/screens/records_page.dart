import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/app_providers.dart';
import '../../application/petji_analytics.dart';
import '../../domain/models.dart';
import '../formatters.dart';
import '../widgets/calendar_grids.dart';
import '../widgets/calendar_navigator.dart';
import '../widgets/info_card.dart';
import '../widgets/period_scope_selector.dart';

class RecordsPage extends ConsumerStatefulWidget {
  const RecordsPage({super.key});

  @override
  ConsumerState<RecordsPage> createState() => _RecordsPageState();
}

class _RecordsPageState extends ConsumerState<RecordsPage> {
  PeriodScope _scope = PeriodScope.month;
  DateTime? _anchor;

  @override
  Widget build(BuildContext context) {
    final snapshot = ref.watch(appSnapshotProvider);
    final pet = snapshot.currentPet;
    if (pet == null) {
      return const Center(child: Text('请先登记宠物'));
    }
    final now = snapshot.exportedAt;
    final anchor = _anchor ?? now;
    final todos =
        snapshot.todos
            .where((todo) => todo.deletedAt == null && todo.petId == pet.id)
            .toList()
          ..sort((a, b) {
            final left = a.dueAt ?? a.createdAt;
            final right = b.dueAt ?? b.createdAt;
            return left.compareTo(right);
          });

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '待办',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            FilledButton.icon(
              onPressed: () => _showTodoDialog(context, now),
              icon: const Icon(Icons.add),
              label: const Text('新增待办'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text('按年、月、日安排疫苗、驱虫、洗护和复诊。'),
        const SizedBox(height: 16),
        CalendarNavigator(
          semanticLabel: '待办日历导航',
          scope: _scope,
          label: _periodLabel(anchor),
          onPrevious: () => setState(() => _anchor = _previous(anchor)),
          onNext: () => setState(() => _anchor = _next(anchor)),
        ),
        const SizedBox(height: 16),
        PeriodScopeSelector(
          selected: _scope,
          onChanged: (scope) => setState(() => _scope = scope),
        ),
        const SizedBox(height: 16),
        switch (_scope) {
          PeriodScope.year => _buildYearView(todos, anchor, now),
          PeriodScope.month => _buildMonthView(todos, anchor, now),
          PeriodScope.day => _buildDayView(todos, anchor, now),
        },
      ],
    );
  }

  Widget _buildYearView(List<TodoItem> todos, DateTime anchor, DateTime now) {
    final petId = ref.read(appSnapshotProvider).currentPet!.id;
    final summaries = summarizeTodosByMonthForPet(
      todos,
      petId: petId,
      year: anchor.year,
      asOf: now,
    );
    return InfoCard(
      title: '${anchor.year} 年待办图谱',
      icon: Icons.event_note_outlined,
      child: YearMonthCalendarGrid(
        semanticLabel: '待办年度月历',
        months: [
          for (var month = 1; month <= 12; month += 1)
            _todoMonthCell(
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

  Widget _buildMonthView(List<TodoItem> todos, DateTime anchor, DateTime now) {
    final petId = ref.read(appSnapshotProvider).currentPet!.id;
    final summaries = summarizeTodosByDayForPet(
      todos,
      petId: petId,
      year: anchor.year,
      month: anchor.month,
      asOf: now,
    );
    return InfoCard(
      title: '${anchor.year}-${anchor.month.toString().padLeft(2, '0')} 待办日历',
      icon: Icons.calendar_month_outlined,
      child: MonthDayCalendarGrid(
        semanticLabel: '待办月历格子',
        year: anchor.year,
        month: anchor.month,
        dayBuilder: (day) {
          return _todoDayCell(
            day: day,
            summary: summaries[day],
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

  Widget _buildDayView(List<TodoItem> todos, DateTime anchor, DateTime now) {
    final visibleTodos = todos.where((todo) {
      final date = todo.dueAt ?? todo.createdAt;
      return date.year == anchor.year &&
          date.month == anchor.month &&
          date.day == anchor.day;
    }).toList();
    return InfoCard(
      title: '${dateLabel(anchor)} 待办',
      icon: Icons.today_outlined,
      child: visibleTodos.isEmpty
          ? const Text('这一天没有待办。')
          : Column(
              children: [
                for (final todo in visibleTodos)
                  _TodoTile(
                    todo: todo,
                    now: now,
                    onChanged: (_) {
                      ref
                          .read(appSnapshotProvider.notifier)
                          .toggleTodo(todo.id);
                    },
                  ),
              ],
            ),
    );
  }

  void _showTodoDialog(BuildContext context, DateTime now) {
    final titleController = TextEditingController();
    final noteController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    var dueAt = DateTime(now.year, now.month, now.day);
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('新增待办'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Semantics(
                        label: '待办标题输入框',
                        textField: true,
                        child: TextFormField(
                          controller: titleController,
                          autofocus: true,
                          decoration: const InputDecoration(
                            labelText: '标题',
                            hintText: '例如 预约疫苗',
                          ),
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                              ? '请填写待办标题'
                              : null,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Semantics(
                        label: '待办内容输入框',
                        textField: true,
                        child: TextFormField(
                          controller: noteController,
                          decoration: const InputDecoration(
                            labelText: '内容（可选）',
                          ),
                          minLines: 2,
                          maxLines: 3,
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final selected = await showDatePicker(
                            context: context,
                            initialDate: dueAt,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                            confirmText: '确定',
                            cancelText: '取消',
                          );
                          if (selected != null) {
                            setDialogState(() => dueAt = selected);
                          }
                        },
                        icon: const Icon(Icons.event_outlined),
                        label: Text('日期 ${dateLabel(dueAt)}'),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('取消'),
                ),
                FilledButton(
                  onPressed: () {
                    if (!formKey.currentState!.validate()) {
                      return;
                    }
                    ref
                        .read(appSnapshotProvider.notifier)
                        .addTodo(
                          title: titleController.text,
                          note: noteController.text,
                          dueAt: dueAt,
                        );
                    setState(() {
                      _scope = PeriodScope.day;
                      _anchor = dueAt;
                    });
                    Navigator.of(dialogContext).pop();
                    _showMessage('已创建待办，并准备本地通知提醒');
                  },
                  child: const Text('保存待办'),
                ),
              ],
            );
          },
        );
      },
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

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

CalendarGridCellData _todoMonthCell({
  required int month,
  required TodoPeriodSummary? summary,
  required bool selected,
  required VoidCallback onTap,
}) {
  final total = summary?.totalCount ?? 0;
  final done = summary?.doneCount ?? 0;
  final overdue = summary?.overdueCount ?? 0;
  return CalendarGridCellData(
    title: '$month月',
    subtitle: total == 0
        ? '0项'
        : overdue > 0
        ? '$total项\n逾期$overdue'
        : '$total项\n完成$done',
    selected: selected,
    hasContent: total > 0,
    semanticLabel: '$month月待办 $total项',
    onTap: onTap,
  );
}

CalendarGridCellData _todoDayCell({
  required int day,
  required TodoPeriodSummary? summary,
  required bool selected,
  required VoidCallback onTap,
}) {
  final total = summary?.totalCount ?? 0;
  final done = summary?.doneCount ?? 0;
  final overdue = summary?.overdueCount ?? 0;
  return CalendarGridCellData(
    title: '$day号',
    subtitle: total == 0
        ? null
        : overdue > 0
        ? '$total项\n逾期$overdue'
        : '$total项\n完成$done',
    selected: selected,
    hasContent: total > 0,
    semanticLabel: '$day号待办 $total项',
    onTap: onTap,
  );
}

class _TodoTile extends StatelessWidget {
  const _TodoTile({
    required this.todo,
    required this.now,
    required this.onChanged,
  });

  final TodoItem todo;
  final DateTime now;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    final completed = todo.status == TodoStatus.done;
    final titleStyle = completed
        ? const TextStyle(decoration: TextDecoration.lineThrough)
        : null;
    final dueAt = todo.dueAt;
    return CheckboxListTile(
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
      value: completed,
      onChanged: onChanged,
      title: Text(todo.title, style: titleStyle),
      subtitle: Text(
        completed
            ? '已完成'
            : dueAt == null
            ? '未设置日期'
            : dueOffsetLabel(dueAt, now),
      ),
      secondary: const Icon(Icons.alarm_outlined),
      checkboxSemanticLabel: '完成待办 ${todo.title}',
    );
  }
}
