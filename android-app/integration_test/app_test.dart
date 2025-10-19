import 'package:integration_test/integration_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:pensieve/main_simple.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App smoke test - launches and shows HomeScreen', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    expect(find.byType(Scaffold), findsWidgets);
  });
}
