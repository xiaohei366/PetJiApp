import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/app_providers.dart';
import '../../application/petji_analytics.dart';
import '../../domain/models.dart';
import '../formatters.dart';
import '../theme/petji_theme.dart';
import '../widgets/calendar_grids.dart';
import '../widgets/calendar_navigator.dart';
import '../widgets/info_card.dart';
import '../widgets/period_scope_selector.dart';

class ExpensesPage extends ConsumerStatefulWidget {
  const ExpensesPage({super.key});

  @override
  ConsumerState<ExpensesPage> createState() => _ExpensesPageState();
}

class _ExpensesPageState extends ConsumerState<ExpensesPage> {
  PeriodScope _scope = PeriodScope.month;
  DateTime? _anchor;

  @override
  Widget build(BuildContext context) {
    final snapshot = ref.watch(appSnapshotProvider);
    final pet = snapshot.currentPet;
    final anchor = _anchor ?? snapshot.exportedAt;
    final entries =
        snapshot.expenses
            .where(
              (entry) =>
                  entry.deletedAt == null &&
                  (pet == null || entry.petId == null || entry.petId == pet.id),
            )
            .toList()
          ..sort((a, b) => b.spentAt.compareTo(a.spentAt));

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '消费报告',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            FilledButton.icon(
              onPressed: () => _showExpenseDialog(context, snapshot),
              icon: const Icon(Icons.add),
              label: const Text('新增消费'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text('按年、月、日递进查看当前宠物和全家共用支出。'),
        const SizedBox(height: 16),
        CalendarNavigator(
          semanticLabel: '消费报告日历导航',
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
          PeriodScope.year => _buildYearView(context, entries, anchor),
          PeriodScope.month => _buildMonthView(context, entries, anchor),
          PeriodScope.day => _buildDayView(context, entries, anchor),
        },
      ],
    );
  }

  Widget _buildYearView(
    BuildContext context,
    List<ExpenseEntry> entries,
    DateTime anchor,
  ) {
    final months = summarizeExpensesByMonthForPet(
      entries,
      petId: ref.read(appSnapshotProvider).currentPet?.id ?? '',
      year: anchor.year,
    );
    final yearSummary = _ExpenseSummary.from(
      entries.where((entry) => entry.spentAt.year == anchor.year),
    );
    return Column(
      children: [
        _ExpenseSummaryCard(
          title: '${anchor.year} 年消费报告',
          summary: yearSummary,
        ),
        const SizedBox(height: 16),
        InfoCard(
          title: '年度月历',
          icon: Icons.calendar_view_month_outlined,
          child: YearMonthCalendarGrid(
            semanticLabel: '消费报告年度月历',
            months: [
              for (var month = 1; month <= 12; month += 1)
                _expenseMonthCell(
                  month: month,
                  summary: _summaryFromPeriod(months[month]),
                  selected: month == anchor.month,
                  onTap: () => setState(() {
                    _scope = PeriodScope.month;
                    _anchor = DateTime(anchor.year, month);
                  }),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMonthView(
    BuildContext context,
    List<ExpenseEntry> entries,
    DateTime anchor,
  ) {
    final days = summarizeExpensesByDayForPet(
      entries,
      petId: ref.read(appSnapshotProvider).currentPet?.id ?? '',
      year: anchor.year,
      month: anchor.month,
    );
    final monthEntries = entries
        .where(
          (entry) =>
              entry.spentAt.year == anchor.year &&
              entry.spentAt.month == anchor.month,
        )
        .toList();
    final monthSummary = _ExpenseSummary.from(monthEntries);
    return Column(
      children: [
        _ExpenseSummaryCard(
          title:
              '${anchor.year}-${anchor.month.toString().padLeft(2, '0')} 消费报告',
          summary: monthSummary,
        ),
        const SizedBox(height: 16),
        InfoCard(
          title: '每日开支日历',
          icon: Icons.calendar_month_outlined,
          child: MonthDayCalendarGrid(
            semanticLabel: '消费报告月历格子',
            year: anchor.year,
            month: anchor.month,
            dayBuilder: (day) {
              final summary = _summaryFromPeriod(days[day]);
              return _expenseDayCell(
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
        ),
      ],
    );
  }

  Widget _buildDayView(
    BuildContext context,
    List<ExpenseEntry> entries,
    DateTime anchor,
  ) {
    final visibleEntries =
        entries
            .where(
              (entry) =>
                  entry.spentAt.year == anchor.year &&
                  entry.spentAt.month == anchor.month &&
                  entry.spentAt.day == anchor.day,
            )
            .toList()
          ..sort((a, b) => b.spentAt.compareTo(a.spentAt));
    final summary = _ExpenseSummary.from(visibleEntries);
    return Column(
      children: [
        _ExpenseSummaryCard(
          title: '${_dateLabel(anchor)} 消费报告',
          summary: summary,
        ),
        const SizedBox(height: 16),
        InfoCard(
          title: '消费明细',
          icon: Icons.receipt_long_outlined,
          child: visibleEntries.isEmpty
              ? const Text('当前视图没有消费记录。')
              : Column(children: visibleEntries.map(_expenseTile).toList()),
        ),
      ],
    );
  }

  Widget _expenseTile(ExpenseEntry entry) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(_iconFor(entry.category)),
      title: Text(entry.title),
      subtitle: Text(
        '${expenseCategoryLabel(entry.category)} · ${_dateLabel(entry.spentAt)}',
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(moneyLabel(entry.amountCents)),
          IconButton(
            onPressed: () => _confirmDeleteExpense(context, entry),
            tooltip: '删除消费 ${entry.title}',
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteExpense(BuildContext context, ExpenseEntry entry) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('删除消费'),
        content: Text('确认删除“${entry.title}”？此操作不可恢复。'),
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
              ref.read(appSnapshotProvider.notifier).deleteExpense(entry.id);
              Navigator.of(dialogContext).pop();
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(const SnackBar(content: Text('消费已删除')));
            },
            child: const Text('确认删除'),
          ),
        ],
      ),
    );
  }

  DateTime _previous(DateTime anchor) => switch (_scope) {
    PeriodScope.year => DateTime(anchor.year - 1, 1),
    PeriodScope.month => DateTime(anchor.year, anchor.month - 1),
    PeriodScope.day => anchor.subtract(const Duration(days: 1)),
  };

  DateTime _next(DateTime anchor) => switch (_scope) {
    PeriodScope.year => DateTime(anchor.year + 1, 1),
    PeriodScope.month => DateTime(anchor.year, anchor.month + 1),
    PeriodScope.day => anchor.add(const Duration(days: 1)),
  };

  String _periodLabel(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return switch (_scope) {
      PeriodScope.year => '$year 年',
      PeriodScope.month => '$year-$month',
      PeriodScope.day => '$year-$month-$day',
    };
  }

  IconData _iconFor(ExpenseCategory category) => switch (category) {
    ExpenseCategory.food => Icons.restaurant_outlined,
    ExpenseCategory.medical => Icons.local_hospital_outlined,
    ExpenseCategory.grooming => Icons.spa_outlined,
    ExpenseCategory.toy => Icons.extension_outlined,
    ExpenseCategory.supplies => Icons.inventory_2_outlined,
    ExpenseCategory.insurance => Icons.verified_user_outlined,
    ExpenseCategory.other => Icons.more_horiz,
  };

  void _showExpenseDialog(BuildContext context, AppSnapshot snapshot) {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    var category = ExpenseCategory.supplies;
    var shared = false;
    var spentAt = DateTime(
      snapshot.exportedAt.year,
      snapshot.exportedAt.month,
      snapshot.exportedAt.day,
    );
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('新增消费'),
              content: Form(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Semantics(
                        label: '消费标题输入框',
                        textField: true,
                        child: TextField(
                          controller: titleController,
                          autofocus: true,
                          decoration: const InputDecoration(
                            labelText: '标题',
                            hintText: '例如 猫砂',
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Semantics(
                        label: '消费金额输入框',
                        textField: true,
                        child: TextField(
                          controller: amountController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: '金额（元）',
                            hintText: '例如 10',
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<ExpenseCategory>(
                        initialValue: category,
                        decoration: const InputDecoration(labelText: '类别'),
                        items: ExpenseCategory.values
                            .map(
                              (item) => DropdownMenuItem(
                                value: item,
                                child: Text(expenseCategoryLabel(item)),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() => category = value);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('全家共用消费'),
                        subtitle: const Text('关闭时绑定当前宠物'),
                        value: shared,
                        onChanged: (value) {
                          setDialogState(() => shared = value);
                        },
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final selected = await showDatePicker(
                            context: context,
                            initialDate: spentAt,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                            confirmText: '确定',
                            cancelText: '取消',
                          );
                          if (selected != null) {
                            setDialogState(() => spentAt = selected);
                          }
                        },
                        icon: const Icon(Icons.event_outlined),
                        label: Text('日期 ${_dateLabel(spentAt)}'),
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
                    final title = titleController.text.trim();
                    final amount = double.tryParse(
                      amountController.text.trim(),
                    );
                    if (title.isEmpty || amount == null || amount <= 0) {
                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                          const SnackBar(content: Text('请填写有效消费')),
                        );
                      return;
                    }
                    ref
                        .read(appSnapshotProvider.notifier)
                        .addExpense(
                          title: title,
                          amountCents: (amount * 100).round(),
                          date: spentAt,
                          category: category,
                          shared: shared,
                        );
                    Navigator.of(dialogContext).pop();
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(const SnackBar(content: Text('消费已保存')));
                  },
                  child: const Text('保存消费'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.categoryTotals, required this.totalCents});

  final Map<ExpenseCategory, int> categoryTotals;
  final int totalCents;

  @override
  Widget build(BuildContext context) {
    if (categoryTotals.isEmpty) {
      return const Text('暂无分类数据');
    }
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: categoryTotals.entries.map((entry) {
        final percent = totalCents == 0 ? 0 : entry.value / totalCents * 100;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: expenseCategoryColor(entry.key),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '${expenseCategoryLabel(entry.key)} ${percent.toStringAsFixed(1)}%',
            ),
          ],
        );
      }).toList(),
    );
  }
}

class _ExpenseSummaryCard extends StatelessWidget {
  const _ExpenseSummaryCard({required this.title, required this.summary});

  final String title;
  final _ExpenseSummary summary;

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      title: title,
      icon: Icons.payments_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      moneyLabel(summary.totalCents),
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    Text('${summary.itemCount}笔记录'),
                  ],
                ),
              ),
              _MiniExpensePie(
                categoryTotals: summary.categoryTotals,
                size: 104,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('分类图例', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          _Legend(
            categoryTotals: summary.categoryTotals,
            totalCents: summary.totalCents,
          ),
        ],
      ),
    );
  }
}

class _MiniExpensePie extends StatelessWidget {
  const _MiniExpensePie({required this.categoryTotals, this.size = 44});

  final Map<ExpenseCategory, int> categoryTotals;
  final double size;

  @override
  Widget build(BuildContext context) {
    final radius = size < 30 ? (size / 2) - 1 : (size < 60 ? 20.0 : 30.0);
    return SizedBox(
      width: size,
      height: size,
      child: Semantics(
        label: '消费分类占比图',
        child: PieChart(
          PieChartData(
            sectionsSpace: 1,
            centerSpaceRadius: size < 30
                ? radius * 0.36
                : (size < 60 ? 10 : 26),
            sections: _pieSections(categoryTotals, radius),
          ),
        ),
      ),
    );
  }
}

class _ExpenseSummary {
  const _ExpenseSummary({
    required this.totalCents,
    required this.itemCount,
    required this.categoryTotals,
  });

  final int totalCents;
  final int itemCount;
  final Map<ExpenseCategory, int> categoryTotals;

  factory _ExpenseSummary.from(Iterable<ExpenseEntry> entries) {
    final categoryTotals = <ExpenseCategory, int>{};
    var total = 0;
    var count = 0;
    for (final entry in entries) {
      total += entry.amountCents;
      count += 1;
      categoryTotals.update(
        entry.category,
        (value) => value + entry.amountCents,
        ifAbsent: () => entry.amountCents,
      );
    }
    return _ExpenseSummary(
      totalCents: total,
      itemCount: count,
      categoryTotals: Map.unmodifiable(categoryTotals),
    );
  }
}

_ExpenseSummary _summaryFromPeriod(ExpensePeriodSummary? summary) {
  if (summary == null) {
    return const _ExpenseSummary(
      totalCents: 0,
      itemCount: 0,
      categoryTotals: {},
    );
  }
  return _ExpenseSummary(
    totalCents: summary.totalCents,
    itemCount: summary.itemCount,
    categoryTotals: summary.categoryTotals,
  );
}

CalendarGridCellData _expenseMonthCell({
  required int month,
  required _ExpenseSummary summary,
  required bool selected,
  required VoidCallback onTap,
}) {
  return CalendarGridCellData(
    title: '$month月',
    subtitle: summary.itemCount == 0
        ? '0笔'
        : '${moneyLabel(summary.totalCents)}\n${summary.itemCount}笔',
    selected: selected,
    hasContent: summary.itemCount > 0,
    trailing: summary.itemCount == 0
        ? null
        : _MiniExpensePie(categoryTotals: summary.categoryTotals, size: 24),
    semanticLabel: '$month月消费 ${summary.itemCount}笔',
    onTap: onTap,
  );
}

CalendarGridCellData _expenseDayCell({
  required int day,
  required _ExpenseSummary summary,
  required bool selected,
  required VoidCallback onTap,
}) {
  return CalendarGridCellData(
    title: '$day号',
    subtitle: summary.itemCount == 0
        ? null
        : '${moneyLabel(summary.totalCents)}\n${summary.itemCount}笔',
    selected: selected,
    hasContent: summary.itemCount > 0,
    semanticLabel: '$day号消费 ${summary.itemCount}笔',
    onTap: onTap,
  );
}

List<PieChartSectionData> _pieSections(
  Map<ExpenseCategory, int> totals,
  double radius,
) {
  if (totals.isEmpty) {
    return [
      PieChartSectionData(
        value: 1,
        color: const Color(0xFFE5E7EB),
        title: '',
        radius: radius,
      ),
    ];
  }
  return totals.entries.map((entry) {
    return PieChartSectionData(
      value: entry.value.toDouble(),
      color: expenseCategoryColor(entry.key),
      title: '',
      radius: radius,
    );
  }).toList();
}

Color expenseCategoryColor(ExpenseCategory category) => switch (category) {
  ExpenseCategory.food => PetjiColors.primary,
  ExpenseCategory.medical => PetjiColors.cta,
  ExpenseCategory.grooming => PetjiColors.success,
  ExpenseCategory.toy => PetjiColors.secondary,
  ExpenseCategory.supplies => const Color(0xFF0F766E),
  ExpenseCategory.insurance => const Color(0xFF7C3AED),
  ExpenseCategory.other => const Color(0xFF64748B),
};

String _dateLabel(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}
