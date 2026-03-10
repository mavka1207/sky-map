
import 'package:flutter_test/flutter_test.dart';

import 'package:sky_map/main.dart';

void main() {
  testWidgets('Sky map renders title', (WidgetTester tester) async {
    await tester.pumpWidget(const SkyMapApp());
    expect(find.text('Sky Map'), findsOneWidget);
  });
}
