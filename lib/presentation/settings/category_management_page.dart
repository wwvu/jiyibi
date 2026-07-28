import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:jiyibi/core/providers.dart';
import 'package:jiyibi/data/database/app_database.dart';
import 'package:jiyibi/shared/widgets/category_icon.dart';
import 'package:jiyibi/shared/widgets/type_segmented_control.dart';

class CategoryManagementPage extends ConsumerStatefulWidget {
  const CategoryManagementPage({super.key});

  @override
  ConsumerState<CategoryManagementPage> createState() =>
      _CategoryManagementPageState();
}

class _CategoryManagementPageState
    extends ConsumerState<CategoryManagementPage> {
  var _type = 'expense';

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(allCategoriesProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('分类管理'),
        actions: [
          IconButton(
            onPressed: () => _editCategory(context),
            icon: const Icon(Icons.add_rounded),
            tooltip: '新增分类',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: TypeSegmentedControl(
              type: _type,
              onChanged: (type) => setState(() => _type = type),
            ),
          ),
          Expanded(
            child: categoriesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => const Center(child: Text('分类加载失败，请重试')),
              data: (categories) {
                final visible = categories
                    .where((category) => category.type == _type)
                    .toList();
                final activeCount = visible
                    .where((category) => !category.archived)
                    .length;
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  itemCount: visible.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final category = visible[index];
                    return _CategoryTile(
                      category: category,
                      canArchive: category.archived || activeCount > 1,
                      onEdit: () => _editCategory(context, category: category),
                      onArchiveChanged: () =>
                          _setArchived(category, !category.archived),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editCategory(BuildContext context, {Category? category}) async {
    final draft = await showDialog<_CategoryDraft>(
      context: context,
      builder: (context) => _CategoryDialog(category: category),
    );
    if (draft == null || !context.mounted) return;

    try {
      final repo = ref.read(categoryRepoProvider);
      final defaultColor = Theme.of(context).colorScheme.primary.toARGB32();
      if (category == null) {
        final all = await repo.getAll(type: _type, includeArchived: true);
        await repo.insert(
          CategoriesCompanion.insert(
            name: draft.name,
            icon: draft.icon,
            color: Value(defaultColor),
            type: Value(_type),
            sortOrder: Value(all.length + 1),
          ),
        );
      } else {
        await repo.update(
          category.id,
          CategoriesCompanion(name: Value(draft.name), icon: Value(draft.icon)),
        );
      }
      ref.invalidateCategoryProviders();
    } on Exception {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('保存失败，请检查分类名称是否重复')));
    }
  }

  Future<void> _setArchived(Category category, bool archived) async {
    if (archived) {
      final active = await ref
          .read(categoryRepoProvider)
          .getAll(type: category.type);
      if (active.length <= 1) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('每种收支至少保留一个可用分类')));
        return;
      }
    }
    await ref.read(categoryRepoProvider).setArchived(category.id, archived);
    ref.invalidateCategoryProviders();
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.category,
    required this.canArchive,
    required this.onEdit,
    required this.onArchiveChanged,
  });

  final Category category;
  final bool canArchive;
  final VoidCallback onEdit;
  final VoidCallback onArchiveChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = Color(category.color);
    return Material(
      color: category.archived
          ? theme.colorScheme.surfaceContainerLow
          : theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        leading: CategoryIcon(
          name: category.name,
          storedIcon: category.icon,
          color: color,
          size: 42,
          iconSize: 21,
        ),
        title: Text(
          category.name,
          style: TextStyle(
            color: category.archived
                ? theme.colorScheme.onSurfaceVariant
                : null,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: category.archived ? const Text('已归档') : null,
        trailing: PopupMenuButton<String>(
          tooltip: '分类操作',
          onSelected: (action) {
            if (action == 'edit') onEdit();
            if (action == 'archive') onArchiveChanged();
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.edit_outlined),
                title: Text('编辑'),
              ),
            ),
            PopupMenuItem(
              value: 'archive',
              enabled: canArchive,
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  category.archived
                      ? Icons.unarchive_outlined
                      : Icons.archive_outlined,
                ),
                title: Text(category.archived ? '恢复' : '归档'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryDraft {
  const _CategoryDraft({required this.name, required this.icon});

  final String name;
  final String icon;
}

class _CategoryDialog extends StatefulWidget {
  const _CategoryDialog({this.category});

  final Category? category;

  @override
  State<_CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<_CategoryDialog> {
  late final TextEditingController _nameController;
  late String _selectedIcon;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name ?? '');
    _selectedIcon = CategoryIcons.keyFor(
      name: widget.category?.name ?? '',
      storedIcon: widget.category?.icon,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: Text(widget.category == null ? '新增分类' : '编辑分类'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            autofocus: true,
            maxLength: 20,
            decoration: InputDecoration(
              labelText: '名称',
              errorText: _errorText,
              counterText: '',
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Text('图标', style: Theme.of(context).textTheme.labelLarge),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: 280,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final option in CategoryIcons.options)
                  Tooltip(
                    message: option.label,
                    child: InkWell(
                      onTap: () => setState(() => _selectedIcon = option.key),
                      customBorder: const CircleBorder(),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: option.key == _selectedIcon
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerHigh,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          option.icon,
                          size: 21,
                          color: option.key == _selectedIcon
                              ? Theme.of(context).colorScheme.onPrimary
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
              ],
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
    if (name.isEmpty) {
      setState(() => _errorText = '分类名称不能为空');
      return;
    }
    Navigator.of(context).pop(_CategoryDraft(name: name, icon: _selectedIcon));
  }
}
