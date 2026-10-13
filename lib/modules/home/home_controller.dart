import 'package:get/get.dart';
import '../../core/services/ui_service.dart';
import '../../core/services/wallet_service.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/channel_repository.dart';
import '../../data/repositories/chat_repository.dart';
import '../channels/channels_view.dart';
import '../chats/chat_list_controller.dart';
import '../groups/groups_view.dart';
import '../profile/profile_view.dart';
import '../wallet/wallet_view.dart';

class HomeController extends GetxController {
  final RxInt currentTabIndex = 0.obs;
  final RxnString activeConversationId = RxnString('c_alice');

  void changeTab(int index) {
    currentTabIndex.value = index;
  }

  void selectConversation(String id) {
    activeConversationId.value = id;
  }
}

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HomeController>(() => HomeController());
    Get.lazyPut<ChatListController>(
      () => ChatListController(Get.find<ChatRepository>(), Get.find<UiService>()),
    );
    Get.lazyPut<GroupsController>(
      () => GroupsController(Get.find<ChatRepository>()),
    );
    Get.lazyPut<ChannelsController>(
      () => ChannelsController(Get.find<ChannelRepository>(), Get.find<UiService>()),
    );
    Get.lazyPut<WalletController>(
      () => WalletController(
        Get.find<WalletService>(),
        Get.find<ChannelRepository>(),
        Get.find<UiService>(),
      ),
    );
    Get.lazyPut<ProfileController>(
      () => ProfileController(
        Get.find<AuthRepository>(),
        Get.find<WalletService>(),
        Get.find<UiService>(),
      ),
    );
  }
}
