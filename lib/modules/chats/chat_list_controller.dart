import 'dart:async';
import 'package:get/get.dart';
import '../../core/services/ui_service.dart';
import '../../data/models/conversation_model.dart';
import '../../data/repositories/chat_repository.dart';
import '../../routes/app_routes.dart';

class ChatListController extends GetxController {
  final ChatRepository _chatRepository;
  final UiService _uiService;

  ChatListController(this._chatRepository, this._uiService);

  final RxList<ConversationModel> conversations = <ConversationModel>[].obs;
  final RxString searchQuery = ''.obs;
  final RxBool isLoading = false.obs;

  StreamSubscription<List<ConversationModel>>? _convSub;

  List<ConversationModel> get filteredConversations {
    final q = searchQuery.value.trim().toLowerCase();
    if (q.isEmpty) return conversations;
    return conversations.where((c) {
      final titleMatch = c.title.toLowerCase().contains(q);
      final handleMatch = c.otherUser?.handle.toLowerCase().contains(q) ?? false;
      return titleMatch || handleMatch;
    }).toList();
  }

  @override
  void onInit() {
    super.onInit();
    loadConversations();
    _subscribeToConversations();
  }

  Future<void> loadConversations() async {
    isLoading.value = true;
    final res = await _chatRepository.fetchConversations();
    res.when(
      ok: (list) {
        conversations.assignAll(list);
        isLoading.value = false;
      },
      err: (e) {
        isLoading.value = false;
        _uiService.showError(e.message);
      },
    );
  }

  void _subscribeToConversations() {
    _convSub = _chatRepository.watchConversations().listen((updatedList) {
      conversations.assignAll(updatedList);
    });
  }

  Future<void> startDirectChat(String handle) async {
    if (handle.trim().isEmpty) return;

    final res = await _chatRepository.createDirectConversation(handle);
    res.when(
      ok: (conv) {
        Get.toNamed(
          '${AppRoutes.conversation}?id=${conv.id}&title=${Uri.encodeComponent(conv.title)}',
        );
      },
      err: (e) {
        _uiService.showError(e.message);
      },
    );
  }

  @override
  void onClose() {
    _convSub?.cancel();
    super.onClose();
  }
}
