import 'package:flutter_test/flutter_test.dart';

import 'package:liflow/main.dart';

void main() {
  testWidgets('App renders splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    expect(find.text('LiFlow'), findsOneWidget);
  });
}
