import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qlbv/main.dart';

void main() {
  testWidgets('App Login Screen Smoke Test', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('QUẢN LÝ LƯƠNG ĐỘI BỐC VÁC'), findsOneWidget);
    expect(find.text('Email đăng nhập'), findsOneWidget);
  });
}

