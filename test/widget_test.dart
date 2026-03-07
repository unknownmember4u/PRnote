import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prnote/main.dart';

void main() {
  testWidgets('PRnote app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: PRnoteApp()));
    
    // Wait for the splash screen duration (2s) + animation time
    await tester.pump(const Duration(seconds: 3));
    
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
