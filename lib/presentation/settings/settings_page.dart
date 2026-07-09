import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:jiyibi/core/providers.dart';
import 'package:jiyibi/core/theme/app_theme.dart';
import 'package:jiyibi/core/theme/theme_provider.dart';
import 'package:jiyibi/data/database/app_database.dart';
import 'package:jiyibi/data/export/csv_exporter.dart';
import 'package:jiyibi/presentation/settings/widgets/settings_tile.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeKey = ref.watch(themeControllerProvider);
    final statsAsync = ref.watch(recordStatsProvider);
    final catsAsync = ref.watch(allCategoriesProvider);
    final accountsAsync = ref.watch(allAccountsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('我的'), centerTitle: true),
      body: ListView(
        children: [
          // 记账统计
          SettingsSection(
            title: '记账统计',
            children: [
              statsAsync.when(
                loading: () => const SettingsTile(
                  icon: Icons.analytics_outlined,
                  title: '加载中…',
                ),
                error: (error, _) => SettingsTile(
                  icon: Icons.error_outline,
                  title: '加载失败',
                  subtitle: '$error',
                ),
                data: (stats) => Column(
                  children: [
                    SettingsTile(
                      icon: Icons.receipt_long_outlined,
                      title: '总记录数',
                      subtitle: '${stats.totalRecords} 条',
                    ),
                    SettingsTile(
                      icon: Icons.calendar_today_outlined,
                      title: '记账天数',
                      subtitle: '${stats.distinctDays} 天',
                    ),
                    SettingsTile(
                      icon: Icons.local_fire_department_outlined,
                      title: '连续记账',
                      subtitle: '${stats.currentStreak} 天',
                    ),
                  ],
                ),
              ),
            ],
          ),

          // 主题
          SettingsSection(
            title: '外观',
            children: [
              SettingsTile(
                icon: Icons.palette_outlined,
                title: '主题外观',
                subtitle: themeKey.label,
                onTap: () => _showThemePicker(context, ref, themeKey),
              ),
            ],
          ),

          // 数据管理
          SettingsSection(
            title: '数据管理',
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
                onTap: () => _showComingSoon(context, '分类管理即将在 V1 迭代上线'),
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
                onTap: () => _showComingSoon(context, '账户管理即将在 V1 迭代上线'),
              ),
            ],
          ),

          // 导入导出
          SettingsSection(
            title: '导入导出',
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
                subtitle: 'V1 迭代',
                onTap: () => _showComingSoon(context, 'CSV 导入将在 V1 迭代上线'),
              ),
            ],
          ),

          // 隐私与安全（加固阶段占位）
          SettingsSection(
            title: '隐私与安全',
            children: [
              SettingsTile(
                icon: Icons.lock_outline,
                title: '应用锁',
                subtitle: '加固阶段',
                onTap: () => _showComingSoon(context, '应用锁将在上线前加固阶段上线'),
              ),
              SettingsTile(
                icon: Icons.backup_outlined,
                title: '数据备份',
                subtitle: '加固阶段',
                onTap: () => _showComingSoon(context, '数据备份将在上线前加固阶段上线'),
              ),
            ],
          ),

          // 关于
          SettingsSection(
            title: '关于',
            children: [
              SettingsTile(
                icon: Icons.info_outline,
                title: '版本',
                subtitle: 'v0.1.0-MVP',
              ),
            ],
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  void _showThemePicker(
    BuildContext context,
    WidgetRef ref,
    AppThemeKey current,
  ) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('选择主题'),
          content: RadioGroup<AppThemeKey>(
            groupValue: current,
            onChanged: (value) {
              if (value == null) return;
              ref.read(themeControllerProvider.notifier).setTheme(value);
              Navigator.of(context).pop();
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final key in AppThemeKey.values)
                  RadioListTile<AppThemeKey>(
                    value: key,
                    title: Text(key.label),
                  ),
              ],
            ),
          ),
        );
      },
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
