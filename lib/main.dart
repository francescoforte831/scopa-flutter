import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scopa_flutter/core/router.dart';
import 'package:scopa_flutter/core/theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Lock to portrait orientation for the best card game experience.
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const ProviderScope(child: ScopaApp()));
}

/// Root application widget.
class ScopaApp extends StatelessWidget {
  const ScopaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Scopa',
      debugShowCheckedModeBanner: false,
      theme: ScopaTheme.theme,
      routerConfig: appRouter,
    );
  }
}
