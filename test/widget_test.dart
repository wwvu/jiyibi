import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jiyibi/app.dart';

void main() {
  testWidgets('jiyibi app shows bottom tabs', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: JiyibiApp()));
    // 只 pump 几帧，不 pumpAndSettle（DetailPage 的 FutureProvider 无 DB 会一直 loading）
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('首页'), findsWidgets);
    expect(find.text('明细'), findsWidgets);
    expect(find.text('洞察'), findsWidgets);
    expect(find.text('我的'), findsWidgets);
  });
}
