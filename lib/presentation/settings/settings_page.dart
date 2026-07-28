import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:jiyibi/core/providers.dart';
import 'package:jiyibi/data/database/app_database.dart';
import 'package:jiyibi/data/export/csv_exporter.dart';
import 'package:jiyibi/presentation/settings/account_management_page.dart';
import 'package:jiyibi/presentation/settings/category_management_page.dart';
import 'package:jiyibi/presentation/settings/widgets/settings_tile.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(recordStatsProvider);
    final catsAsync = ref.watch(allCategoriesProvider);
    final accountsAsync = ref.watch(allAccountsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Align(
          alignment: Alignment.centerLeft,
          child: Text('我的财务'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
        children: [
          statsAsync.when(
            loading: () => const SizedBox(height: 154),
            error: (error, _) => SettingsTile(
              icon: Icons.error_outline,
              title: '统计加载失败',
              subtitle: '$error',
            ),
            data: (stats) => _FinanceProfile(
              totalRecords: stats.totalRecords,
              distinctDays: stats.distinctDays,
              currentStreak: stats.currentStreak,
            ),
          ),
          const SizedBox(height: 12),
          SettingsSection(
            title: '分类与账户',
            children: [
              SettingsTile(
                icon: Icons.category_outlined,
                title: '分类管理',
                subtitle:
                    catsAsync.whenOrNull(
                      data: (cats) =>
                          '${cats.where((c) => !c.archived).length} 个分类',
                    ) ??
                    '加载中…',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const CategoryManagementPage(),
                  ),
                ),
              ),
              SettingsTile(
                icon: Icons.account_balance_wallet_outlined,
                title: '账户管理',
                subtitle:
                    accountsAsync.whenOrNull(
                      data: (accounts) =>
                          '${accounts.where((a) => !a.archived).length} 个账户',
                    ) ??
                    '加载中…',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const AccountManagementPage(),
                  ),
                ),
              ),
            ],
          ),
          SettingsSection(
            title: '数据',
            children: [
              SettingsTile(
                icon: Icons.file_upload_outlined,
                title: '导出 CSV',
                subtitle: '将流水导出为 CSV 文件',
                onTap: () => _exportCsv(context, ref),
              ),
              SettingsTile(
                icon: Icons.file_download_outlined,
                title: '导入数据',
                subtitle: '从其他记账 App 迁移',
                onTap: () => _showComingSoon(context, '数据导入将在下一版本开放'),
              ),
            ],
          ),
          SettingsSection(
            title: '隐私与安全',
            children: [
              SettingsTile(
                icon: Icons.lock_outline,
                title: '应用锁',
                subtitle: '使用生物识别保护账本',
                onTap: () => _showComingSoon(context, '应用锁将在上线前加固阶段上线'),
              ),
              SettingsTile(
                icon: Icons.backup_outlined,
                title: '数据备份',
                subtitle: '创建受保护的数据副本',
                onTap: () => _showComingSoon(context, '数据备份将在上线前加固阶段上线'),
              ),
            ],
          ),

          SettingsSection(
            title: '关于',
            children: [
              SettingsTile(
                icon: Icons.info_outline,
                title: '版本',
                subtitle: 'v1.0.0 · 财务气象版',
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  Future<void> _exportCsv(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final choice = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('导出 CSV'),
          content: const Text('选择导出范围'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop('current'),
              child: const Text('当月'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop('all'),
              child: const Text('全部'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
          ],
        );
      },
    );

    if (choice == null) return;

    try {
      final repo = ref.read(recordRepoProvider);
      final categoryRepo = ref.read(categoryRepoProvider);
      final month = ref.read(currentMonthProvider);

      final categories = [
        ...await categoryRepo.getAll(type: 'expense', includeArchived: true),
        ...await categoryRepo.getAll(type: 'income', includeArchived: true),
      ];
      final categoryMap = <int, Category>{for (final c in categories) c.id: c};

      final records = choice == 'all'
          ? await repo.getAll()
          : await repo.getRecordsByMonth(month.year, month.month);

      if (records.isEmpty) {
        if (!context.mounted) return;
        messenger.showSnackBar(const SnackBar(content: Text('没有可导出的记录')));
        return;
      }

      await CsvExporter.exportAndShare(
        records: records,
        categoryMap: categoryMap,
        year: choice == 'current' ? month.year : null,
        month: choice == 'current' ? month.month : null,
      );
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('已导出 ${records.length} 条记录')),
      );
    } catch (error) {
      if (!context.mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('导出失败: $error')));
    }
  }
}

class _FinanceProfile extends StatelessWidget {
  const _FinanceProfile({
    required this.totalRecords,
    required this.distinctDays,
    required this.currentStreak,
  });

  final int totalRecords;
  final int distinctDays;
  final int currentStreak;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.account_balance_wallet_rounded,
                  color: theme.colorScheme.onPrimary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '我的账本',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      currentStreak > 0
                          ? '已连续记账 $currentStreak 天'
                          : '今天记一笔，继续积累自己的数据',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _ProfileMetric(label: '总记录', value: '$totalRecords 笔'),
              ),
              Expanded(
                child: _ProfileMetric(label: '记账日', value: '$distinctDays 天'),
              ),
              Expanded(
                child: _ProfileMetric(label: '连续', value: '$currentStreak 天'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileMetric extends StatelessWidget {
  const _ProfileMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
