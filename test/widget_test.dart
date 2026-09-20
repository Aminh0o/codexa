import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:codexa/main.dart';

void main() {
  testWidgets('App launches without crash', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: CodexaApp()),
    );
    // The app should build without throwing
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
