import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();

  Stream<bool> get onlineChanges async* {
    await for (final result in _connectivity.onConnectivityChanged) {
      yield result.any((element) => element != ConnectivityResult.none);
    }
  }

  Future<bool> isOnline() async {
    final result = await _connectivity.checkConnectivity();
    return result.any((element) => element != ConnectivityResult.none);
  }
}
