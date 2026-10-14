import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

class InternetConnectivityService {
  InternetConnectivityService._();

  static Future<bool> hasInternetAccess() async {
    try {
      return await InternetConnection().hasInternetAccess;
    } catch (_) {
      return false;
    }
  }
}