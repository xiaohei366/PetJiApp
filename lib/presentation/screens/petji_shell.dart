import 'package:flutter/material.dart';

import 'dashboard_page.dart';
import 'expenses_page.dart';
import 'records_page.dart';
import 'settings_page.dart';
import 'timeline_page.dart';

class PetjiShell extends StatefulWidget {
  const PetjiShell({super.key});

  @override
  State<PetjiShell> createState() => _PetjiShellState();
}

class _PetjiShellState extends State<PetjiShell> {
  var _selectedIndex = 0;
  String? _focusedTimelineEventId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: _pageFor(_selectedIndex)),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: '首页',
          ),
          NavigationDestination(
            icon: Icon(Icons.photo_library_outlined),
            selectedIcon: Icon(Icons.photo_library),
            label: '成长线',
          ),
          NavigationDestination(
            icon: Icon(Icons.edit_note_outlined),
            selectedIcon: Icon(Icons.edit_note),
            label: '待办',
          ),
          NavigationDestination(
            icon: Icon(Icons.payments_outlined),
            selectedIcon: Icon(Icons.payments),
            label: '消费',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: '我的',
          ),
        ],
      ),
    );
  }

  Widget _pageFor(int index) {
    return switch (index) {
      0 => DashboardPage(
        onOpenTimelineAll: () {
          setState(() {
            _selectedIndex = 1;
            _focusedTimelineEventId = null;
          });
        },
        onOpenTimelineEvent: (eventId) {
          setState(() {
            _selectedIndex = 1;
            _focusedTimelineEventId = eventId;
          });
        },
      ),
      1 => TimelinePage(focusedEventId: _focusedTimelineEventId),
      2 => const RecordsPage(),
      3 => const ExpensesPage(),
      _ => const SettingsPage(),
    };
  }
}
