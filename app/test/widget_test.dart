// Basic Flutter widget test for UNOA app.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:unoa/main.dart';

void main() {
  testWidgets('App builds in demo mode', (WidgetTester tester) async {
    // Set demo mode to true for testing
    isDemoMode = true;

    // Build the app wrapped in ProviderScope
    await tester.pumpWidget(
      const ProviderScope(
        child: UnoaApp(),
      ),
    );

    // Verify that the app renders the demo page
    expect(find.text('UNOA'), findsAny);
    expect(find.text('Private Fan Communication'), findsOneWidget);
  });
}
