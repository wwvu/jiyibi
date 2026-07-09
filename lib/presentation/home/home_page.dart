import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:jiyibi/presentation/budget/budget_page.dart';
import 'package:jiyibi/presentation/detail/detail_page.dart';
import 'package:jiyibi/presentation/editor/editor_sheet.dart';
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
    _HomeTab(label: '明细', icon: Icons.receipt_long_outlined),
    _HomeTab(label: '预算', icon: Icons.savings_outlined),
    _HomeTab(label: '报表', icon: Icons.pie_chart_outline),
    _HomeTab(label: '我的', icon: Icons.person_outline),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          DetailPage(),
          BudgetPage(),
          ReportPage(),
          SettingsPage(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showEditorSheet(context),
        tooltip: '记一笔',
        elevation: 4,
        highlightElevation: 8,
        child: const Icon(Icons.add, size: 30),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        height: 72,
        padding: EdgeInsets.zero,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: SizedBox(
          height: 72,
          child: Row(
            children: [
              Expanded(
                child: _BottomTabButton(
                  tab: _tabs[0],
                  isSelected: _selectedIndex == 0,
                  onTap: () => setState(() => _selectedIndex = 0),
                ),
              ),
              Expanded(
                child: _BottomTabButton(
                  tab: _tabs[1],
                  isSelected: _selectedIndex == 1,
                  onTap: () => setState(() => _selectedIndex = 1),
                ),
              ),
              const SizedBox(width: 80),
              Expanded(
                child: _BottomTabButton(
                  tab: _tabs[2],
                  isSelected: _selectedIndex == 2,
                  onTap: () => setState(() => _selectedIndex = 2),
                ),
              ),
              Expanded(
                child: _BottomTabButton(
                  tab: _tabs[3],
                  isSelected: _selectedIndex == 3,
                  onTap: () => setState(() => _selectedIndex = 3),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomTabButton extends StatelessWidget {
  const _BottomTabButton({
    required this.tab,
    required this.isSelected,
    required this.onTap,
  });

  final _HomeTab tab;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = isSelected
        ? colorScheme.primary
        : colorScheme.onSurfaceVariant;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(tab.icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            tab.label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeTab {
  const _HomeTab({required this.label, required this.icon});

  final String label;
  final IconData icon;
}
