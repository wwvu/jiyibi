import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:jiyibi/core/providers.dart';
import 'package:jiyibi/presentation/detail/detail_page.dart';
import 'package:jiyibi/presentation/editor/editor_sheet.dart';
import 'package:jiyibi/presentation/overview/overview_page.dart';
import 'package:jiyibi/presentation/report/report_page.dart';
import 'package:jiyibi/presentation/settings/settings_page.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  var _selectedIndex = 0;

  static const _tabs = <_HomeTab>[
    _HomeTab(
      label: '首页',
      icon: Icons.space_dashboard_outlined,
      selectedIcon: Icons.space_dashboard_rounded,
    ),
    _HomeTab(
      label: '明细',
      icon: Icons.receipt_long_outlined,
      selectedIcon: Icons.receipt_long,
    ),
    _HomeTab(
      label: '洞察',
      icon: Icons.auto_graph_outlined,
      selectedIcon: Icons.auto_graph_rounded,
    ),
    _HomeTab(
      label: '我的',
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          OverviewPage(
            onShowDetails: () => setState(() => _selectedIndex = 1),
            onShowInsights: () => setState(() => _selectedIndex = 2),
          ),
          const DetailPage(),
          const ReportPage(),
          const SettingsPage(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showEditorSheet(context),
        tooltip: '记一笔',
        child: const Icon(Icons.add, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          if (index == 0) {
            final now = DateTime.now();
            ref
                .read(currentMonthProvider.notifier)
                .setMonth(DateTime(now.year, now.month));
          }
          setState(() => _selectedIndex = index);
        },
        destinations: [
          for (final tab in _tabs)
            NavigationDestination(
              icon: Icon(tab.icon),
              selectedIcon: Icon(tab.selectedIcon),
              label: tab.label,
            ),
        ],
      ),
    );
  }
}

class _HomeTab {
  const _HomeTab({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}
