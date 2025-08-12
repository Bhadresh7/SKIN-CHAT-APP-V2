import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:skin_app_migration/providers/chat_provider.dart';
import 'package:skin_app_migration/providers/image_picker_provider.dart';
import 'package:skin_app_migration/providers/internet_provider.dart';
import 'package:skin_app_migration/providers/my_auth_provider.dart';
import 'package:skin_app_migration/providers/super_admin_provider.dart';

extension ProviderExtensions on BuildContext {
  // read the data from the provider without rebuild
  MyAuthProvider get readAuthProvider => read<MyAuthProvider>();

  // watch for rebuilds in the ui
  MyAuthProvider get watchAuthProvider => watch<MyAuthProvider>();

  //   internet provider extensions
  InternetProvider get readInternetProvider => read<InternetProvider>();

  //image provider
  ImagePickerProvider get readImagePickerProvider =>
      read<ImagePickerProvider>();

  ChatProvider get readChatProvider => read<ChatProvider>();

  ChatProvider get watchChatProvider => watch<ChatProvider>();

  SuperAdminProvider get readSuperAdminProvider => read<SuperAdminProvider>();
}
