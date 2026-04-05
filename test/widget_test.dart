import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:booking_app/presentation/widgets/common/form_widgets.dart';

void main() {
  testWidgets('AppPrimaryButton renders label', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppPrimaryButton(
            text: 'Sign In',
            color: Colors.red,
            onPressed: _noop,
          ),
        ),
      ),
    );

    expect(find.text('Sign In'), findsOneWidget);
  });
}

void _noop() {}
