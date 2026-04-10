import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scopa_flutter/core/router.dart';
import 'package:scopa_flutter/core/theme.dart';

void main() {
  testWidgets('App launches and shows menu screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
          theme: ScopaTheme.theme,
          routerConfig: appRouter,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('SCOPA'), findsOneWidget);
  });
}
