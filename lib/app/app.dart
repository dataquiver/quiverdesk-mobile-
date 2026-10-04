import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'routes.dart';
import 'themes.dart';

class QuiverDeskApp extends StatefulWidget {
  const QuiverDeskApp({super.key});

  @override
  State<QuiverDeskApp> createState() => _QuiverDeskAppState();
}

class _QuiverDeskAppState extends State<QuiverDeskApp> {
  bool _isOffline = false;
  late final StreamSubscription<List<ConnectivityResult>> _sub;

  @override
  void initState() {
    super.initState();
    _sub = Connectivity().onConnectivityChanged.listen((results) {
      final offline = results.every((r) => r == ConnectivityResult.none);
      if (offline != _isOffline && mounted) setState(() => _isOffline = offline);
    });
    Connectivity().checkConnectivity().then((results) {
      if (results.every((r) => r == ConnectivityResult.none) && mounted) {
        setState(() => _isOffline = true);
      }
    });
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'QuiverDesk',
      debugShowCheckedModeBanner: false,
      theme: QDTheme.light,
      routerConfig: appRouter,
      builder: (context, child) => Material(
        color: const Color(0xFFF8FAFC),
        child: Column(
          children: [
            AnimatedSize(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOut,
              child: _isOffline
                  ? Material(
                      color: const Color(0xFF1E293B),
                      child: SafeArea(
                        bottom: false,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                          child: Row(
                            children: const [
                              Icon(Icons.wifi_off_rounded, color: Colors.white, size: 15),
                              SizedBox(width: 8),
                              Text('No internet connection',
                                  style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            Expanded(child: child ?? const SizedBox.shrink()),
          ],
        ),
      ),
    );
  }
}
