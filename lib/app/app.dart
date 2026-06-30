import 'package:flutter/material.dart';
import 'routes.dart';
import 'themes.dart';

class QuiverDeskApp extends StatelessWidget {
  const QuiverDeskApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'QuiverDesk',
      debugShowCheckedModeBanner: false,
      theme: QDTheme.light,
      routerConfig: appRouter,
    );
  }
}
