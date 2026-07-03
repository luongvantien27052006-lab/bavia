import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('widget test harness renders a basic Bavia screen',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: Text('Bavia Coffee')),
        ),
      ),
    );

    expect(find.text('Bavia Coffee'), findsOneWidget);
  });
}
