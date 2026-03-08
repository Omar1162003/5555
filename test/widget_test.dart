// test/widget_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:city_library/main.dart';
import 'package:city_library/core/theme/theme_provider.dart';

void main() {
  testWidgets('CityLibraryApp renders', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => ThemeProvider(),
        child: const CityLibraryApp(),
      ),
    );
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}