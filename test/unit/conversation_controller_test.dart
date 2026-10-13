import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';
import 'package:elite_chat/core/errors/result.dart';
import 'package:elite_chat/data/models/message_model.dart';
import 'package:elite_chat/data/repositories/chat_repository.dart';
import 'package:elite_chat/modules/conversation/conversation_controller.dart';

class MockChatRepository extends Mock implements ChatRepository {}

void main() {
  late MockChatRepository repo;

  setUp(() {
    Get.testMode = true;
    repo = MockChatRepository();
    when(() => repo.watchMessages(any())).thenAnswer((_) => const Stream.empty());
    when(() => repo.markAsRead(any())).thenAnswer((_) async => const Ok(null));
  });

  tearDown(Get.reset);

  test('loads initial messages successfully per testing.md', () async {
    final fakeMsg = MessageModel(
      id: 'm1',
      conversationId: 'c1',
      senderId: 'user_alice',
      clientId: 'cid_1',
      content: 'Hello World',
      createdAt: DateTime.now(),
    );

    when(() => repo.fetchMessages(conversationId: 'c1')).thenAnswer(
      (_) async => Ok<List<MessageModel>>([fakeMsg]),
    );

    final controller = ConversationController(repo, 'c1');
    await controller.loadInitial();

    expect(controller.messages.length, 1);
    expect(controller.messages.first.content, 'Hello World');
    expect(controller.isLoading.value, isFalse);
    expect(controller.errorKey.value, isNull);
  });

  test('exposes an error message when loading messages fails', () async {
    when(() => repo.fetchMessages(conversationId: 'c1')).thenAnswer(
      (_) async => Err<List<MessageModel>>(AppException.network('Connection timeout')),
    );

    final controller = ConversationController(repo, 'c1');
    await controller.loadInitial();

    expect(controller.messages.isEmpty, isTrue);
    expect(controller.isLoading.value, isFalse);
    expect(controller.errorKey.value, contains('Connection timeout'));
  });
}
