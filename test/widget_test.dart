// import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moslides/main.dart';

void main() {
  testWidgets('MoSlides app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MoSlidesApp());
    expect(find.text('MoSlides'), findsWidgets);
  });
}
