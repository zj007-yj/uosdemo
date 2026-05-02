import 'package:flutter_test/flutter_test.dart';

import 'package:uos_demo/main.dart';

void main() {
  testWidgets('app builds', (WidgetTester tester) async {
    await tester.pumpWidget(const UosRtspDemoApp());
    expect(find.textContaining('UOS RTSP'), findsOneWidget);
  });
}
