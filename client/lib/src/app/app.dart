import 'package:flutter/material.dart';

import 'app_router.dart';
import 'app_theme.dart';

class InfographicApp extends StatelessWidget {
  const InfographicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Генерация инфографики',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: appRouter,
    );
  }
}