import 'package:get/get.dart';
import '../services/ui_service.dart';
import '../services/wallet_service.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/channel_repository.dart';
import '../../data/repositories/chat_repository.dart';
import '../../data/repositories/firebase_auth_repository.dart';
import '../../data/repositories/firestore_chat_repository.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // 1. App-lifetime core services
    Get.put<UiService>(UiService(), permanent: true);
    Get.put<WalletService>(WalletService(), permanent: true);

    // 2. Real Firestore and Firebase-backed repositories (Section 11)
    Get.put<AuthRepository>(FirebaseAuthRepository(), permanent: true);
    Get.put<ChatRepository>(FirestoreChatRepository(), permanent: true);
    Get.put<ChannelRepository>(FirestoreChannelRepository(), permanent: true);
  }
}
