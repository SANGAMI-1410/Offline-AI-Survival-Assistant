import 'package:flutter_test/flutter_test.dart';

import 'package:forest_ai/main.dart';

void main() {
  testWidgets('ForestAI welcome screen smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ForestAiApp());

    expect(find.text('ForestAI'), findsOneWidget);
    expect(find.text('Works 100% offline in forests'), findsOneWidget);
    expect(find.text('Upload Forest Dataset'), findsOneWidget);
  });
}
