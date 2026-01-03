import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';

class ConnectivityProvider with ChangeNotifier {
  bool _hasInternet = true;
  Timer? _timer;

  bool get hasInternet => _hasInternet;

  ConnectivityProvider() {
    // Check connectivity every 5 seconds
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => checkConnectivity());
  }

  Future<void> checkConnectivity() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      final newStatus = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      if (newStatus != _hasInternet) {
        _hasInternet = newStatus;
        notifyListeners();
      }
    } on SocketException catch (_) {
      if (_hasInternet) {
        _hasInternet = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
