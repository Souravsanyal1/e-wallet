import 'package:get/get.dart';
import '../services/ui_service.dart';
import '../services/wallet_service.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/channel_repository.dart';
import '../../data/repositories/chat_repository.dart';
import '../../data/repositories/mock_auth_repository.dart';
import '../../data/repositories/mock_chat_repository.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // 1. App-lifetime core services
    Get.put<UiService>(UiService(), permanent: true);
    Get.put<WalletService>(WalletService(), permanent: true);

    // 2. Repositories (Mock implementations provide rich interactive demo & offline testing)
    Get.put<AuthRepository>(MockAuthRepository(), permanent: true);
    Get.put<ChatRepository>(MockChatRepository(), permanent: true);
    Get.put<ChannelRepository>(MockChannelRepository(), permanent: true);
  }
}
