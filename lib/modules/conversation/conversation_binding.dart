import 'package:get/get.dart';
import '../../data/repositories/chat_repository.dart';
import 'conversation_controller.dart';

class ConversationBinding extends Bindings {
  @override
  void dependencies() {
    final convId = Get.parameters['id'] ?? '';
    Get.lazyPut<ConversationController>(
      () => ConversationController(
        Get.find<ChatRepository>(),
        convId,
      ),
      tag: convId,
    );
  }
}
