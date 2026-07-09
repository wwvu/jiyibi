import 'package:flutter/material.dart';

/// 自定义数字键盘。4×4 网格：1-9, 0, ., 00, ⌫, 今天, 完成。
class NumberPad extends StatelessWidget {
  const NumberPad({
    super.key,
    required this.onDigit,
    required this.onDot,
    required this.onDoubleZero,
    required this.onBackspace,
    required this.onToday,
    required this.onDone,
    required this.doneEnabled,
  });

  final ValueChanged<String> onDigit;
  final VoidCallback onDot;
  final VoidCallback onDoubleZero;
  final VoidCallback onBackspace;
  final VoidCallback onToday;
  final VoidCallback onDone;
  final bool doneEnabled;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 252,
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      _PadKey(label: '1', onTap: () => onDigit('1')),
                      _PadKey(label: '2', onTap: () => onDigit('2')),
                      _PadKey(label: '3', onTap: () => onDigit('3')),
                    ],
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      _PadKey(label: '4', onTap: () => onDigit('4')),
                      _PadKey(label: '5', onTap: () => onDigit('5')),
                      _PadKey(label: '6', onTap: () => onDigit('6')),
                    ],
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      _PadKey(label: '7', onTap: () => onDigit('7')),
                      _PadKey(label: '8', onTap: () => onDigit('8')),
                      _PadKey(label: '9', onTap: () => onDigit('9')),
                    ],
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      _PadKey(label: '0', onTap: () => onDigit('0')),
                      _PadKey(label: '.', onTap: onDot),
                      _PadKey(label: '00', onTap: onDoubleZero),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Column(
              children: [
                Expanded(
                  child: _PadKey(
                    icon: Icons.backspace_outlined,
                    onTap: onBackspace,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: _PadKey(
                    label: '完成',
                    onTap: onDone,
                    primary: true,
                    enabled: doneEnabled,
                  ),
                ),
                Expanded(
                  child: _PadKey(label: '今天', onTap: onToday, small: true),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PadKey extends StatelessWidget {
  const _PadKey({
    this.label,
    this.onTap,
    this.icon,
    this.primary = false,
    this.enabled = true,
    this.small = false,
  });

  final String? label;
  final VoidCallback? onTap;
  final IconData? icon;
  final bool primary;
  final bool enabled;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final backgroundColor = primary
        ? (enabled
            ? colorScheme.primary
            : colorScheme.surfaceContainerHighest)
        : colorScheme.surfaceContainerLow;
    final foregroundColor = primary
        ? (enabled ? colorScheme.onPrimary : colorScheme.onSurfaceVariant)
        : colorScheme.onSurface;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Material(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: enabled ? onTap : null,
            child: Center(
              child: icon != null
                  ? Icon(icon, color: foregroundColor, size: 24)
                  : Text(
                      label!,
                      style: (small
                              ? theme.textTheme.bodyLarge
                              : theme.textTheme.headlineSmall)
                          ?.copyWith(
                            color: foregroundColor,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
