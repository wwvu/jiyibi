import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:jiyibi/core/providers.dart';
import 'package:jiyibi/core/utils/money_utils.dart';
import 'package:jiyibi/data/database/app_database.dart' show Record;
import 'package:jiyibi/presentation/editor/editor_provider.dart';
import 'package:jiyibi/presentation/editor/widgets/category_grid.dart';
import 'package:jiyibi/presentation/editor/widgets/number_pad.dart';
import 'package:jiyibi/shared/widgets/type_segmented_control.dart';

/// 打开记账弹层（新增模式）。每次打开重置表单。
void showEditorSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    clipBehavior: Clip.antiAlias,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => const EditorSheet(),
  );
}

/// 打开记账弹层（编辑模式），用已有记录预填。
void showEditorSheetForEdit(BuildContext context, Record record) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    clipBehavior: Clip.antiAlias,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => EditorSheet(recordForEdit: record),
  );
}

class EditorSheet extends ConsumerStatefulWidget {
  const EditorSheet({super.key, this.recordForEdit});

  final Record? recordForEdit;

  @override
  ConsumerState<EditorSheet> createState() => _EditorSheetState();
}

class _EditorSheetState extends ConsumerState<EditorSheet> {
  late final TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController(
      text: widget.recordForEdit?.note ?? '',
    );
    Future.microtask(() {
      if (!mounted) return;
      final notifier = ref.read(editorProvider.notifier);
      if (widget.recordForEdit != null) {
        notifier.startEdit(widget.recordForEdit!);
      } else {
        notifier.reset();
      }
    });
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(editorProvider);
    final categoriesAsync = ref.watch(
      state.type == 'expense'
          ? expenseCategoriesProvider
          : incomeCategoriesProvider,
    );
    final theme = Theme.of(context);

    final mediaQuery = MediaQuery.of(context);
    final keyboardHeight = mediaQuery.viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: keyboardHeight),
      child: SizedBox(
        height:
            mediaQuery.size.height -
            mediaQuery.padding.top -
            keyboardHeight -
            8,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
              child: Column(
                children: [
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close),
                        tooltip: '关闭',
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      Text(
                        state.isEditing ? '编辑记录' : '记一笔',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          state.isEditing
                              ? Icons.delete_outline
                              : Icons.more_horiz,
                          color: state.isEditing
                              ? theme.colorScheme.error
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                        onPressed: state.isEditing
                            ? () => _confirmDelete()
                            : null,
                        tooltip: state.isEditing ? '删除' : '更多',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TypeSegmentedControl(
                    type: state.type,
                    onChanged: (type) =>
                        ref.read(editorProvider.notifier).setType(type),
                  ),
                  const SizedBox(height: 16),
                  _AmountDisplay(amountString: state.amountString),
                  const SizedBox(height: 10),
                  _DateRow(date: state.date, onTap: () => _pickDate(context)),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        '分类',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    categoriesAsync.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(),
                      ),
                      error: (error, _) => Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text('分类加载失败: $error'),
                      ),
                      data: (categories) => CategoryGrid(
                        categories: categories,
                        selectedId: state.categoryId,
                        onChanged: (id) =>
                            ref.read(editorProvider.notifier).setCategory(id),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _noteController,
                      decoration: InputDecoration(
                        hintText: '添加备注',
                        prefixIcon: Icon(
                          Icons.edit_outlined,
                          size: 20,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        prefixIconConstraints: const BoxConstraints(
                          minWidth: 40,
                          minHeight: 36,
                        ),
                      ),
                      onChanged: (value) =>
                          ref.read(editorProvider.notifier).setNote(value),
                    ),
                  ],
                ),
              ),
            ),
            if (keyboardHeight == 0) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 0),
                child: NumberPad(
                  onDigit: (digit) =>
                      ref.read(editorProvider.notifier).appendDigit(digit),
                  onDot: () => ref.read(editorProvider.notifier).appendDot(),
                  onDoubleZero: () =>
                      ref.read(editorProvider.notifier).appendDoubleZero(),
                  onBackspace: () =>
                      ref.read(editorProvider.notifier).backspace(),
                  onToday: () =>
                      ref.read(editorProvider.notifier).setDate(DateTime.now()),
                  onDone: () => _save(),
                  doneEnabled: state.canSave,
                ),
              ),
              SizedBox(height: mediaQuery.padding.bottom + 8),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final theme = Theme.of(context);
    final state = ref.read(editorProvider);
    DateTime tempDate = state.date;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('取消'),
                        ),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              DateFormat('yyyy年M月d日 HH:mm').format(tempDate),
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            ref.read(editorProvider.notifier).setDate(tempDate);
                            Navigator.of(context).pop();
                          },
                          child: Text(
                            '确定',
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: theme.colorScheme.outlineVariant),
                  SizedBox(
                    height: 220,
                    child: CupertinoTheme(
                      data: CupertinoThemeData(
                        brightness: theme.brightness,
                        textTheme: CupertinoTextThemeData(
                          dateTimePickerTextStyle: TextStyle(
                            color: theme.colorScheme.onSurface,
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      child: CupertinoDatePicker(
                        mode: CupertinoDatePickerMode.dateAndTime,
                        initialDateTime: state.date,
                        minimumDate: DateTime(2020),
                        maximumDate: DateTime(2100),
                        use24hFormat: true,
                        onDateTimeChanged: (DateTime newDate) {
                          setModalState(() {
                            tempDate = newDate;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _save() async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(editorProvider.notifier).save();
      navigator.pop();
    } on Exception {
      if (!mounted) return;
      messenger.showSnackBar(const SnackBar(content: Text('保存失败，请重试')));
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('删除记录'),
          content: const Text('确定删除这条记录吗？删除后无法恢复。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('删除'),
            ),
          ],
        );
      },
    );
    if (!mounted || confirmed != true) return;

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(editorProvider.notifier).delete();
      navigator.pop();
    } on Exception {
      if (!mounted) return;
      messenger.showSnackBar(const SnackBar(content: Text('删除失败，请重试')));
    }
  }
}

class _AmountDisplay extends StatelessWidget {
  const _AmountDisplay({required this.amountString});

  final String amountString;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final display = amountString.isEmpty ? '0.00' : _formatAmount(amountString);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerRight,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 1),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '¥',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                display,
                style: theme.textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatAmount(String raw) {
    final cents = MoneyUtils.yuanToCents(raw);
    final base = MoneyUtils.formatYuan(cents).replaceFirst('¥', '');
    // 保留输入过程中的中间态：末尾的点或单个小数
    if (raw.endsWith('.')) {
      final integerPart = base.replaceAll(RegExp(r'\.\d+$'), '');
      return '$integerPart.';
    }
    if (raw.contains('.')) {
      final decimals = raw.split('.').last;
      if (decimals.length == 1) {
        final integerPart = base.replaceAll(RegExp(r'\.\d+$'), '');
        return '$integerPart.$decimals';
      }
    }
    return base;
  }
}

class _DateRow extends StatelessWidget {
  const _DateRow({required this.date, required this.onTap});

  final DateTime date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isToday = _isSameDay(date, DateTime.now());

    return Material(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.56),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                isToday
                    ? '今天 ${DateFormat('HH:mm').format(date)}'
                    : DateFormat('M月d日 HH:mm').format(date),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
