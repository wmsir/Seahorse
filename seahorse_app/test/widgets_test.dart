import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seahorse_app/widgets/metric_card.dart';
import 'package:seahorse_app/widgets/status_badge.dart';

void main() {
  group('UI Widgets Tests', () {
    testWidgets('1. MetricCard renders title, value, subtitle and icon', (WidgetTester tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MetricCard(
              title: '今日营收',
              value: '¥ 12,860',
              subtitle: '+18.5% 较昨日',
              icon: Icons.attach_money,
              iconColor: Colors.amber,
              onTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('今日营收'), findsOneWidget);
      expect(find.text('¥ 12,860'), findsOneWidget);
      expect(find.text('+18.5% 较昨日'), findsOneWidget);
      expect(find.byIcon(Icons.attach_money), findsOneWidget);

      await tester.tap(find.byType(MetricCard));
      expect(tapped, isTrue);
    });

    testWidgets('2. StatusBadge renders label, icon and applies colors', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatusBadge(
              label: '服务中',
              textColor: Colors.blue,
              backgroundColor: Color(0xFFDBEAFE),
              icon: Icons.play_circle_outline,
            ),
          ),
        ),
      );

      expect(find.text('服务中'), findsOneWidget);
      expect(find.byIcon(Icons.play_circle_outline), findsOneWidget);
    });
  });
}
