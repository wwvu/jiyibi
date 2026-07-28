import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:jiyibi/core/theme/app_theme.dart';
import 'package:jiyibi/presentation/home/home_page.dart';

class JiyibiApp extends StatelessWidget {
  const JiyibiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '记一笔',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.standard,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('zh'), Locale('en')],
      locale: const Locale('zh'),
      home: const HomePage(),
    );
  }
}
