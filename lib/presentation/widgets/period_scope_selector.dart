import 'package:flutter/material.dart';

enum PeriodScope { year, month, day }

class PeriodScopeSelector extends StatelessWidget {
  const PeriodScopeSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final PeriodScope selected;
  final ValueChanged<PeriodScope> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '时间视图切换',
      child: SegmentedButton<PeriodScope>(
        segments: const [
          ButtonSegment(value: PeriodScope.year, label: Text('年')),
          ButtonSegment(value: PeriodScope.month, label: Text('月')),
          ButtonSegment(value: PeriodScope.day, label: Text('日')),
        ],
        selected: {selected},
        showSelectedIcon: false,
        onSelectionChanged: (selection) => onChanged(selection.first),
      ),
    );
  }
}
