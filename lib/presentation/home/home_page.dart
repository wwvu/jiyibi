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
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
    ),
    _HomeTab(
      label: '明细',
      icon: Icons.receipt_long_outlined,
      selectedIcon: Icons.receipt_long_rounded,
    ),
    _HomeTab(
      label: '洞察',
      icon: Icons.donut_large_outlined,
      selectedIcon: Icons.donut_large_rounded,
    ),
    _HomeTab(
      label: '我的',
      icon: Icons.face_outlined,
      selectedIcon: Icons.face_rounded,
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
      bottomNavigationBar: _AppBottomBar(
        selectedIndex: _selectedIndex,
        tabs: _tabs,
        onAdd: () => showEditorSheet(context),
        onDestinationSelected: (index) {
          if (index == 0) {
            final now = DateTime.now();
            ref
                .read(currentMonthProvider.notifier)
                .setMonth(DateTime(now.year, now.month));
          }
          setState(() => _selectedIndex = index);
        },
      ),
    );
  }
}

class _AppBottomBar extends StatelessWidget {
  const _AppBottomBar({
    required this.selectedIndex,
    required this.tabs,
    required this.onDestinationSelected,
    required this.onAdd,
  });

  final int selectedIndex;
  final List<_HomeTab> tabs;
  final ValueChanged<int> onDestinationSelected;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      child: SafeArea(
        top: false,
        child: Container(
          height: 70,
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
          ),
          child: Row(
            children: [
              _BottomItem(
                tab: tabs[0],
                selected: selectedIndex == 0,
                onTap: () => onDestinationSelected(0),
              ),
              _BottomItem(
                tab: tabs[1],
                selected: selectedIndex == 1,
                onTap: () => onDestinationSelected(1),
              ),
              _AddItem(onTap: onAdd),
              _BottomItem(
                tab: tabs[2],
                selected: selectedIndex == 2,
                onTap: () => onDestinationSelected(2),
              ),
              _BottomItem(
                tab: tabs[3],
                selected: selectedIndex == 3,
                onTap: () => onDestinationSelected(3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomItem extends StatelessWidget {
  const _BottomItem({
    required this.tab,
    required this.selected,
    required this.onTap,
  });

  final _HomeTab tab;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = selected
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;
    return Expanded(
      child: InkResponse(
        onTap: onTap,
        radius: 30,
        child: Semantics(
          selected: selected,
          button: true,
          label: tab.label,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 34,
                height: 30,
                decoration: BoxDecoration(
                  color: selected
                      ? theme.colorScheme.primary.withValues(alpha: 0.11)
                      : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  selected ? tab.selectedIcon : tab.icon,
                  color: color,
                  size: 21,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                tab.label,
                maxLines: 1,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: color,
                  fontSize: 10,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddItem extends StatelessWidget {
  const _AddItem({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: InkResponse(
        onTap: onTap,
        radius: 30,
        child: Semantics(
          button: true,
          label: '记账',
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 34,
                height: 30,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.11),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.edit_note_rounded,
                  color: theme.colorScheme.primary,
                  size: 21,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '记账',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
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
