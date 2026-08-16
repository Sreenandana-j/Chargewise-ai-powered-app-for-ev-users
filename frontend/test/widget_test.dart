import 'package:ev_route_planner/app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App loads smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const EvRoutePlannerApp());
    expect(find.byType(EvRoutePlannerApp), findsOneWidget);
  });
}
