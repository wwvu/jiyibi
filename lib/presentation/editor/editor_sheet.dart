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

/// 打开记账弹层（新增模式）。每次打开重置表单。
void showEditorSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
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
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
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
                      Text(
                        state.isEditing ? '编辑记录' : '记一笔',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (state.isEditing)
                        IconButton(
                          icon: Icon(
                            Icons.delete_outline,
                            color: theme.colorScheme.error,
                          ),
                          onPressed: () => _confirmDelete(),
                          tooltip: '删除',
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _TypeToggle(
                    type: state.type,
                    onChanged: (type) =>
                        ref.read(editorProvider.notifier).setType(type),
                  ),
                  const SizedBox(height: 16),
                  _AmountDisplay(amountString: state.amountString),
                  const SizedBox(height: 8),
                  _DateRow(date: state.date, onTap: () => _pickDate(context)),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          '分类',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
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
                        hintStyle: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest,
                        prefixIcon: Icon(
                          Icons.edit_outlined,
                          size: 20,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        prefixIconConstraints: const BoxConstraints(
                          minWidth: 40,
                          minHeight: 36,
                        ),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: theme.colorScheme.primary,
                            width: 1.5,
                          ),
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
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
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
    await ref.read(editorProvider.notifier).save();
    navigator.pop();
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
    await ref.read(editorProvider.notifier).delete();
    navigator.pop();
  }
}

class _TypeToggle extends StatelessWidget {
  const _TypeToggle({required this.type, required this.onChanged});

  final String type;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        children: [
          Expanded(
            child: _ToggleButton(
              label: '支出',
              isSelected: type == 'expense',
              color: const Color(0xFFD85A30),
              onTap: () => onChanged('expense'),
            ),
          ),
          Expanded(
            child: _ToggleButton(
              label: '收入',
              isSelected: type == 'income',
              color: const Color(0xFF3B6D11),
              onTap: () => onChanged('income'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleButton extends StatelessWidget {
  const _ToggleButton({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: theme.textTheme.titleSmall?.copyWith(
            color: isSelected
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _AmountDisplay extends StatelessWidget {
  const _AmountDisplay({required this.amountString});

  final String amountString;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final display = amountString.isEmpty ? '0.00' : _formatAmount(amountString);

    return SizedBox(
      width: double.infinity,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              '¥',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 2),
            Text(
              display,
              style: theme.textTheme.displayMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
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

    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.calendar_today_outlined, size: 16),
        label: Text(
          isToday
              ? '今天 ${DateFormat('HH:mm').format(date)}'
              : DateFormat('M月d日 HH:mm').format(date),
          style: theme.textTheme.bodyMedium,
        ),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
