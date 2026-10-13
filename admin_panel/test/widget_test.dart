import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:elite_chat_admin/controllers/admin_controller.dart';
import 'package:elite_chat_admin/main.dart';

void main() {
  setUp(() {
    Get.testMode = true;
    Get.put(AdminController());
  });

  tearDown(Get.reset);

  testWidgets('Admin app smoke test renders login', (WidgetTester tester) async {
    await tester.pumpWidget(const EliteChatAdminApp());
    await tester.pump();
    expect(find.text('EliteChat Operations'), findsOneWidget);
  });
}
