import 'package:flutter/material.dart';

class CalendarGridCellData {
  const CalendarGridCellData({
    required this.title,
    this.subtitle,
    this.onTap,
    this.selected = false,
    this.hasContent = false,
    this.trailing,
    this.semanticLabel,
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool selected;
  final bool hasContent;
  final Widget? trailing;
  final String? semanticLabel;
}

class YearMonthCalendarGrid extends StatelessWidget {
  const YearMonthCalendarGrid({
    super.key,
    required this.semanticLabel,
    required this.months,
  }) : assert(months.length == 12);

  final String semanticLabel;
  final List<CalendarGridCellData> months;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: semanticLabel,
      child: LayoutBuilder(
        builder: (context, constraints) {
          const spacing = 8.0;
          final dense = constraints.maxWidth < 340;
          final aspectRatio = dense ? 0.9 : 1.0;
          final cellWidth = (constraints.maxWidth - spacing * 3) / 4;
          final cellHeight = cellWidth / aspectRatio;
          return Column(
            children: [
              for (var row = 0; row < 3; row += 1) ...[
                Row(
                  children: [
                    for (var column = 0; column < 4; column += 1) ...[
                      SizedBox(
                        width: cellWidth,
                        height: cellHeight,
                        child: _CalendarGridCell(
                          data: months[row * 4 + column],
                          dense: dense,
                        ),
                      ),
                      if (column != 3) const SizedBox(width: spacing),
                    ],
                  ],
                ),
                if (row != 2) const SizedBox(height: spacing),
              ],
            ],
          );
        },
      ),
    );
  }
}

class MonthDayCalendarGrid extends StatelessWidget {
  const MonthDayCalendarGrid({
    super.key,
    required this.semanticLabel,
    required this.year,
    required this.month,
    required this.dayBuilder,
  });

  final String semanticLabel;
  final int year;
  final int month;
  final CalendarGridCellData Function(int day) dayBuilder;

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(year, month);
    final leadingBlanks = firstDay.weekday % 7;
    final dayCount = DateTime(year, month + 1, 0).day;
    final itemCount = leadingBlanks + dayCount;

    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: semanticLabel,
      child: Column(
        children: [
          const _WeekdayHeader(),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              const spacing = 6.0;
              final aspectRatio = constraints.maxWidth < 340 ? 0.55 : 0.62;
              final cellWidth = (constraints.maxWidth - spacing * 6) / 7;
              final cellHeight = cellWidth / aspectRatio;
              final rowCount = (itemCount / 7).ceil();
              return Column(
                children: [
                  for (var row = 0; row < rowCount; row += 1) ...[
                    Row(
                      children: [
                        for (var column = 0; column < 7; column += 1) ...[
                          SizedBox(
                            width: cellWidth,
                            height: cellHeight,
                            child: _dayCellForIndex(
                              row * 7 + column,
                              leadingBlanks,
                              dayCount,
                            ),
                          ),
                          if (column != 6) const SizedBox(width: spacing),
                        ],
                      ],
                    ),
                    if (row != rowCount - 1) const SizedBox(height: spacing),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _dayCellForIndex(int index, int leadingBlanks, int dayCount) {
    if (index < leadingBlanks) {
      return const SizedBox.shrink();
    }
    final day = index - leadingBlanks + 1;
    if (day > dayCount) {
      return const SizedBox.shrink();
    }
    return _CalendarGridCell(data: dayBuilder(day), dense: true);
  }
}

class _WeekdayHeader extends StatelessWidget {
  const _WeekdayHeader();

  static const _weekdays = ['日', '一', '二', '三', '四', '五', '六'];

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelMedium?.copyWith(
      fontWeight: FontWeight.w800,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
    return Row(
      children: [
        for (final weekday in _weekdays)
          Expanded(
            child: Center(child: Text(weekday, style: style)),
          ),
      ],
    );
  }
}

class _CalendarGridCell extends StatelessWidget {
  const _CalendarGridCell({required this.data, required this.dense});

  final CalendarGridCellData data;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final hasContent = data.hasContent || (data.subtitle?.isNotEmpty ?? false);
    final background = data.selected
        ? scheme.primary
        : hasContent
        ? scheme.primaryContainer.withValues(alpha: 0.58)
        : scheme.surfaceContainerHighest.withValues(alpha: 0.36);
    final borderColor = data.selected
        ? scheme.primary
        : hasContent
        ? scheme.primary.withValues(alpha: 0.18)
        : scheme.outlineVariant.withValues(alpha: 0.7);
    final foreground = data.selected ? scheme.onPrimary : scheme.onSurface;
    final mutedForeground = data.selected
        ? scheme.onPrimary.withValues(alpha: 0.92)
        : scheme.onSurfaceVariant;

    final child = Material(
      color: background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: data.onTap,
        child: Padding(
          padding: EdgeInsets.all(dense ? 5 : 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      data.title,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: foreground,
                        fontWeight: FontWeight.w800,
                        fontSize: dense ? 12 : null,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                  if (data.trailing != null) ...[
                    SizedBox(width: dense ? 2 : 4),
                    SizedBox.square(
                      dimension: dense ? 16 : 24,
                      child: data.trailing,
                    ),
                  ],
                ],
              ),
              if (data.subtitle != null && data.subtitle!.isNotEmpty) ...[
                SizedBox(height: dense ? 3 : 6),
                Flexible(
                  child: Center(
                    child: Text(
                      data.subtitle!,
                      textAlign: TextAlign.center,
                      maxLines: dense ? 2 : 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: mutedForeground,
                        fontWeight: FontWeight.w700,
                        fontSize: dense ? 9 : 11,
                        height: 1.12,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    return Semantics(
      button: data.onTap != null,
      label: data.semanticLabel ?? data.title,
      child: child,
    );
  }
}
