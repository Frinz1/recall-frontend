import 'package:flutter_test/flutter_test.dart';
import 'package:recall/app.dart';

void main() {
  testWidgets('Recall app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const RecallApp());
    expect(find.text('Recall'), findsWidgets);
  });
}
