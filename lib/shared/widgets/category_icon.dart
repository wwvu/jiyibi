import 'package:flutter/material.dart';

class CategoryIconOption {
  const CategoryIconOption(this.key, this.label, this.icon);

  final String key;
  final String label;
  final IconData icon;
}

class CategoryIcons {
  const CategoryIcons._();

  static const options = <CategoryIconOption>[
    CategoryIconOption('food', '餐饮', Icons.restaurant_rounded),
    CategoryIconOption('transport', '交通', Icons.directions_bus_rounded),
    CategoryIconOption('shopping', '购物', Icons.shopping_bag_rounded),
    CategoryIconOption('fun', '娱乐', Icons.sports_esports_rounded),
    CategoryIconOption('health', '医疗', Icons.medical_services_rounded),
    CategoryIconOption('home', '居家', Icons.home_rounded),
    CategoryIconOption('study', '学习', Icons.school_rounded),
    CategoryIconOption('salary', '工资', Icons.payments_rounded),
    CategoryIconOption('work', '兼职', Icons.work_rounded),
    CategoryIconOption('wallet', '收入', Icons.account_balance_wallet_rounded),
    CategoryIconOption('travel', '旅行', Icons.flight_rounded),
    CategoryIconOption('digital', '数码', Icons.devices_rounded),
    CategoryIconOption('gift', '礼物', Icons.card_giftcard_rounded),
    CategoryIconOption('sport', '运动', Icons.fitness_center_rounded),
    CategoryIconOption('other', '其他', Icons.more_horiz_rounded),
  ];

  static IconData resolve({required String name, String? storedIcon}) {
    for (final option in options) {
      if (option.key == storedIcon) return option.icon;
    }
    return optionForName(name).icon;
  }

  static String keyFor({required String name, String? storedIcon}) {
    for (final option in options) {
      if (option.key == storedIcon) return option.key;
    }
    return optionForName(name).key;
  }

  static CategoryIconOption optionForName(String name) {
    if (name.contains('餐') || name.contains('吃') || name.contains('饮')) {
      return options[0];
    }
    if (name.contains('交通') || name.contains('车')) return options[1];
    if (name.contains('购物') || name.contains('买')) return options[2];
    if (name.contains('娱乐') || name.contains('游戏')) return options[3];
    if (name.contains('医疗') || name.contains('健康')) return options[4];
    if (name.contains('居家') || name.contains('住房')) return options[5];
    if (name.contains('学习') || name.contains('教育')) return options[6];
    if (name.contains('工资')) return options[7];
    if (name.contains('兼职') || name.contains('工作')) return options[8];
    if (name.contains('收入') || name.contains('奖金')) return options[9];
    if (name.contains('旅行')) return options[10];
    if (name.contains('数码')) return options[11];
    if (name.contains('礼物')) return options[12];
    if (name.contains('运动') || name.contains('健身')) return options[13];
    return options[14];
  }
}

class CategoryIcon extends StatelessWidget {
  const CategoryIcon({
    super.key,
    required this.name,
    required this.color,
    this.storedIcon,
    this.size = 40,
    this.iconSize = 20,
    this.selected = false,
  });

  final String name;
  final String? storedIcon;
  final Color color;
  final double size;
  final double iconSize;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: selected ? color : color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Icon(
        CategoryIcons.resolve(name: name, storedIcon: storedIcon),
        size: iconSize,
        color: selected ? Theme.of(context).colorScheme.surface : color,
      ),
    );
  }
}
