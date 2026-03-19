import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:spotbook/app.dart';

void main() {
  testWidgets('SpotbookApp renders', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: SpotbookApp()),
    );
    await tester.pump();
    expect(find.byType(SpotbookApp), findsOneWidget);
  });
}
