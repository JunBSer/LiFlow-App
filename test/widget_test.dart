import 'package:flutter_test/flutter_test.dart';

import 'package:liflow/main.dart';
import 'package:liflow/viewmodels/settings_view_model.dart';

void main() {
  testWidgets('App renders splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(MyApp(settingsViewModel: SettingsViewModel()));
    await tester.pump();

    expect(find.text('LiFlow'), findsOneWidget);
  });
}
