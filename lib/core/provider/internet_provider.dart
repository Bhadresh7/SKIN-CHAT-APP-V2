import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:skin_app_migration/core/constants/app_status.dart';

class InternetProvider extends ChangeNotifier {
  StreamSubscription? _connectivitySubscription;
  String connectivityStatus = AppStatus.kDisconnected;

  void initConnectivity() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      List<ConnectivityResult> result,
    ) {
      if (result.isNotEmpty) {
        connectivityStatus = AppStatus.kConnected;
      } else {
        connectivityStatus = AppStatus.kDisconnected;
      }
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}
