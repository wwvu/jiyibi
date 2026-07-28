import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:jiyibi/core/providers.dart';
import 'package:jiyibi/core/utils/money_utils.dart';
import 'package:jiyibi/data/database/app_database.dart';

class AccountManagementPage extends ConsumerWidget {
  const AccountManagementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(allAccountsProvider);
    final balancesAsync = ref.watch(accountBalancesProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('账户管理'),
        actions: [
          IconButton(
            onPressed: () => _editAccount(context, ref),
            icon: const Icon(Icons.add_rounded),
            tooltip: '新增账户',
          ),
        ],
      ),
      body: accountsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(child: Text('账户加载失败，请重试')),
        data: (accounts) {
          final balances = balancesAsync.value ?? const <int, int>{};
          final activeCount = accounts
              .where((account) => !account.archived)
              .length;
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            itemCount: accounts.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final account = accounts[index];
              return _AccountTile(
                account: account,
                currentBalanceCents:
                    balances[account.id] ?? account.balanceCents,
                canArchive: account.archived || activeCount > 1,
                onEdit: () => _editAccount(context, ref, account: account),
                onArchiveChanged: () =>
                    _setArchived(context, ref, account, !account.archived),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _editAccount(
    BuildContext context,
    WidgetRef ref, {
    Account? account,
  }) async {
    final draft = await showDialog<_AccountDraft>(
      context: context,
      builder: (context) => _AccountDialog(account: account),
    );
    if (draft == null) return;

    try {
      final repo = ref.read(accountRepoProvider);
      if (account == null) {
        await repo.insert(
          AccountsCompanion.insert(
            name: draft.name,
            icon: Value(draft.icon),
            balanceCents: Value(draft.openingBalanceCents),
          ),
        );
      } else {
        await repo.update(
          account.id,
          AccountsCompanion(
            name: Value(draft.name),
            icon: Value(draft.icon),
            balanceCents: Value(draft.openingBalanceCents),
          ),
        );
      }
      ref.invalidateAccountProviders();
    } on Exception {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('保存失败，请检查账户名称是否重复')));
    }
  }

  Future<void> _setArchived(
    BuildContext context,
    WidgetRef ref,
    Account account,
    bool archived,
  ) async {
    final accounts = await ref.read(accountRepoProvider).getAll();
    if (archived && accounts.length <= 1) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('至少保留一个可用账户')));
      return;
    }
    await ref.read(accountRepoProvider).setArchived(account.id, archived);
    ref.invalidateAccountProviders();
  }
}

class _AccountTile extends StatelessWidget {
  const _AccountTile({
    required this.account,
    required this.currentBalanceCents,
    required this.canArchive,
    required this.onEdit,
    required this.onArchiveChanged,
  });

  final Account account;
  final int currentBalanceCents;
  final bool canArchive;
  final VoidCallback onEdit;
  final VoidCallback onArchiveChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: account.archived
          ? theme.colorScheme.surfaceContainerLow
          : theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        leading: Container(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            account.icon,
            style: TextStyle(
              color: theme.colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        title: Text(
          account.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(account.archived ? '已归档' : '当前余额'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 120),
              child: Text(
                MoneyUtils.formatYuan(currentBalanceCents),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            PopupMenuButton<String>(
              tooltip: '账户操作',
              onSelected: (action) {
                if (action == 'edit') onEdit();
                if (action == 'archive') onArchiveChanged();
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Text('编辑')),
                PopupMenuItem(
                  value: 'archive',
                  enabled: canArchive,
                  child: Text(account.archived ? '恢复' : '归档'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountDraft {
  const _AccountDraft({
    required this.name,
    required this.icon,
    required this.openingBalanceCents,
  });

  final String name;
  final String icon;
  final int openingBalanceCents;
}

class _AccountDialog extends StatefulWidget {
  const _AccountDialog({this.account});

  final Account? account;

  @override
  State<_AccountDialog> createState() => _AccountDialogState();
}

class _AccountDialogState extends State<_AccountDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _iconController;
  late final TextEditingController _balanceController;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.account?.name ?? '');
    _iconController = TextEditingController(text: widget.account?.icon ?? '');
    _balanceController = TextEditingController(
      text: widget.account == null
          ? '0.00'
          : MoneyUtils.formatYuanPlain(widget.account!.balanceCents),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _iconController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.account == null ? '新增账户' : '编辑账户'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            autofocus: true,
            maxLength: 20,
            decoration: InputDecoration(labelText: '名称', errorText: _errorText),
          ),
          TextField(
            controller: _iconController,
            maxLength: 2,
            decoration: const InputDecoration(labelText: '图标文字'),
          ),
          TextField(
            controller: _balanceController,
            keyboardType: const TextInputType.numberWithOptions(
              signed: true,
              decimal: true,
            ),
            decoration: const InputDecoration(
              labelText: '期初余额',
              prefixText: '¥ ',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(onPressed: _submit, child: const Text('保存')),
      ],
    );
  }

  void _submit() {
    final name = _nameController.text.trim();
    final icon = _iconController.text.trim();
    final balanceText = _balanceController.text.trim();
    final validBalance = RegExp(
      r'^[+-]?\d+(\.\d{0,2})?$',
    ).hasMatch(balanceText);
    final balanceCents = MoneyUtils.yuanToCents(balanceText);
    final isZero = RegExp(r'^[+-]?0+(\.0{0,2})?$').hasMatch(balanceText);
    if (name.isEmpty ||
        icon.isEmpty ||
        !validBalance ||
        (balanceCents == 0 && !isZero)) {
      setState(() => _errorText = '请完整填写有效的账户信息');
      return;
    }
    Navigator.of(context).pop(
      _AccountDraft(name: name, icon: icon, openingBalanceCents: balanceCents),
    );
  }
}
