import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/providers.dart';
import '../../core/utils/money_utils.dart';
import '../../data/database/app_database.dart' show RecordsCompanion, Record;

class EditorState {
  const EditorState({
    this.type = 'expense',
    this.amountString = '',
    this.categoryId,
    this.note = '',
    this.editingId,
    required this.date,
  });

  final String type; // 'expense' | 'income'
  final String amountString;
  final int? categoryId;
  final String note;
  final DateTime date;

  /// 非 null 表示编辑模式（editingId = 记录 id）；null 表示新增模式。
  final int? editingId;

  bool get isEditing => editingId != null;

  int get amountCents => MoneyUtils.yuanToCents(amountString);

  bool get canSave => amountCents > 0 && categoryId != null;

  EditorState copyWith({
    String? type,
    String? amountString,
    int? categoryId,
    String? note,
    DateTime? date,
    int? editingId,
    bool clearEditingId = false,
    bool clearCategoryId = false,
  }) {
    return EditorState(
      type: type ?? this.type,
      amountString: amountString ?? this.amountString,
      categoryId: clearCategoryId ? null : (categoryId ?? this.categoryId),
      note: note ?? this.note,
      date: date ?? this.date,
      editingId: clearEditingId ? null : (editingId ?? this.editingId),
    );
  }
}

final editorProvider = NotifierProvider<EditorNotifier, EditorState>(
  EditorNotifier.new,
);

class EditorNotifier extends Notifier<EditorState> {
  int _categoryLoadId = 0;

  @override
  EditorState build() {
    _loadLastCategory('expense', ++_categoryLoadId);
    return EditorState(date: DateTime.now());
  }

  void reset() {
    state = EditorState(date: DateTime.now());
    _loadLastCategory('expense', ++_categoryLoadId);
  }

  /// 进入编辑模式：用已有记录预填表单。
  void startEdit(Record record) {
    _categoryLoadId++;
    final amountString = _centsToAmountString(record.amountCents);
    state = EditorState(
      type: record.type,
      amountString: amountString,
      categoryId: record.categoryId,
      note: record.note ?? '',
      date: record.date,
      editingId: record.id,
    );
  }

  void setType(String type) {
    if (type == state.type) return;
    state = state.copyWith(type: type, clearCategoryId: true);
    if (!state.isEditing) {
      _loadLastCategory(type, ++_categoryLoadId);
    }
  }

  void setCategory(int categoryId) {
    _categoryLoadId++;
    state = state.copyWith(categoryId: categoryId);
  }

  void setNote(String note) {
    state = state.copyWith(note: note);
  }

  void setDate(DateTime date) {
    state = state.copyWith(date: date);
  }

  void appendDigit(String digit) {
    if (digit.length != 1 || int.tryParse(digit) == null) return;
    final current = state.amountString;
    final dotIndex = current.indexOf('.');
    if (dotIndex >= 0 && current.length - dotIndex - 1 >= 2) return;
    final next = current == '0' ? digit : current + digit;
    state = state.copyWith(amountString: next);
  }

  void appendDot() {
    final current = state.amountString;
    if (current.contains('.')) return;
    final next = current.isEmpty ? '0.' : '$current.';
    state = state.copyWith(amountString: next);
  }

  void appendDoubleZero() {
    final current = state.amountString;
    if (current.isEmpty || current == '0') return;
    final dotIndex = current.indexOf('.');
    if (dotIndex >= 0) {
      final decimals = current.length - dotIndex - 1;
      if (decimals >= 2) return;
      if (decimals == 1) {
        state = state.copyWith(amountString: '${current}0');
        return;
      }
    }
    state = state.copyWith(amountString: '${current}00');
  }

  void backspace() {
    final current = state.amountString;
    if (current.isEmpty) return;
    state = state.copyWith(
      amountString: current.substring(0, current.length - 1),
    );
  }

  void clearAmount() {
    state = state.copyWith(amountString: '');
  }

  Future<void> save() async {
    if (!state.canSave) return;

    final repo = ref.read(recordRepoProvider);

    if (state.isEditing) {
      await repo.update(
        state.editingId!,
        RecordsCompanion(
          type: Value(state.type),
          amountCents: Value(state.amountCents),
          categoryId: Value(state.categoryId),
          note: Value(state.note.isEmpty ? null : state.note),
          date: Value(state.date),
        ),
      );
    } else {
      await repo.insert(
        RecordsCompanion.insert(
          date: state.date,
          type: Value(state.type),
          amountCents: state.amountCents,
          categoryId: Value(state.categoryId),
          note: Value(state.note.isEmpty ? null : state.note),
        ),
      );

      final prefs = await SharedPreferences.getInstance();
      final key = state.type == 'expense'
          ? 'lastExpenseCategory'
          : 'lastIncomeCategory';
      await prefs.setInt(key, state.categoryId!);
    }

    ref.invalidateRecordDerivedProviders();
  }

  Future<void> delete() async {
    if (!state.isEditing) return;
    await ref.read(recordRepoProvider).delete(state.editingId!);
    ref.invalidateRecordDerivedProviders();
  }

  String _centsToAmountString(int cents) {
    if (cents == 0) return '';
    final abs = cents.abs();
    final yuan = abs ~/ 100;
    final frac = abs % 100;
    final prefix = cents < 0 ? '-' : '';
    if (frac == 0) return '$prefix$yuan';
    if (frac % 10 == 0) return '$prefix$yuan.${frac ~/ 10}';
    return '$prefix$yuan.$frac';
  }

  Future<void> _loadLastCategory(String type, int requestId) async {
    final prefs = await SharedPreferences.getInstance();
    if (requestId != _categoryLoadId || state.type != type || state.isEditing) {
      return;
    }
    final key = type == 'expense'
        ? 'lastExpenseCategory'
        : 'lastIncomeCategory';
    final id = prefs.getInt(key);
    if (id != null && requestId == _categoryLoadId) {
      state = state.copyWith(categoryId: id);
    }
  }
}
