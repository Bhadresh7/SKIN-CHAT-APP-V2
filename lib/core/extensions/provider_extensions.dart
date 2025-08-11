import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:skin_app_migration/core/provider/image_picker_provider.dart';
import 'package:skin_app_migration/core/provider/internet_provider.dart';
import 'package:skin_app_migration/features/auth/providers/my_auth_provider.dart';
import 'package:skin_app_migration/features/message/provider/chat_provider.dart';
import 'package:skin_app_migration/features/super_admin/provider/super_admin_provider.dart';

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
