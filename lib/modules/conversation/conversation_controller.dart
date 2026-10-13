import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/models/message_model.dart';
import '../../data/repositories/chat_repository.dart';

class ConversationController extends GetxController {
  final ChatRepository _chatRepository;
  final String conversationId;

  ConversationController(this._chatRepository, this.conversationId);

  final RxList<MessageModel> messages = <MessageModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isSending = false.obs;
  final RxnString errorKey = RxnString();
  final Rxn<MessageModel> replyingTo = Rxn<MessageModel>();
  final RxBool isOtherTyping = false.obs;

  final TextEditingController textController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  StreamSubscription<MessageModel>? _messageSub;
  Timer? _typingTimer;

  @override
  void onInit() {
    super.onInit();
    loadInitial();
    _subscribeToRealtime();
  }

  Future<void> loadInitial() async {
    isLoading.value = true;
    errorKey.value = null;

    final result = await _chatRepository.fetchMessages(conversationId: conversationId);
    result.when(
      ok: (list) {
        messages.assignAll(list);
        isLoading.value = false;
        _chatRepository.markAsRead(conversationId);
      },
      err: (e) {
        errorKey.value = e.message;
        isLoading.value = false;
      },
    );
  }

  void _subscribeToRealtime() {
    _messageSub = _chatRepository.watchMessages(conversationId).listen((newMessage) {
      // Check if message is already in list
      final idx = messages.indexWhere((m) => m.id == newMessage.id || m.clientId == newMessage.clientId);
      if (idx == -1) {
        messages.add(newMessage);
        _scrollToBottom();
      } else {
        messages[idx] = newMessage;
      }

      // If incoming from another user, clear typing indicator
      if (newMessage.senderId != 'me') {
        isOtherTyping.value = false;
        _typingTimer?.cancel();
      }
    });
  }

  Future<void> sendCurrentMessage() async {
    final text = textController.text.trim();
    if (text.isEmpty || isSending.value) return;

    final reply = replyingTo.value;
    textController.clear();
    replyingTo.value = null;
    isSending.value = true;

    // Simulate other user typing back in demo
    _simulateTypingIndicator();

    final result = await _chatRepository.sendMessage(
      conversationId: conversationId,
      content: text,
      replyToId: reply?.id,
      replySnippet: reply != null ? '${reply.senderId}: ${reply.content}' : null,
    );

    result.when(
      ok: (sentMsg) {
        final idx = messages.indexWhere((m) => m.id == sentMsg.id || m.clientId == sentMsg.clientId);
        if (idx == -1) {
          messages.add(sentMsg);
        } else {
          messages[idx] = sentMsg;
        }
        _scrollToBottom();
      },
      err: (e) {
        // Handle failed delivery
      },
    );

    isSending.value = false;
  }

  void _simulateTypingIndicator() {
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(milliseconds: 600), () {
      isOtherTyping.value = true;
      _scrollToBottom();
    });
  }

  void setReplyingTo(MessageModel msg) {
    replyingTo.value = msg;
  }

  void clearReply() {
    replyingTo.value = null;
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void onClose() {
    _messageSub?.cancel();
    _typingTimer?.cancel();
    textController.dispose();
    scrollController.dispose();
    super.onClose();
  }
}
