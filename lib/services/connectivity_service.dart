import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'api_service.dart';
import 'dart:async';

enum NetworkReachability {
  reachable,
  unreachable,
}

enum NetworkType {
  wifi,
  cellular,
  none,
  unknown
}

class ConnectivityService {
  static Future<NetworkType> getNetworkType() async {
    try {
      final connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult.contains(ConnectivityResult.wifi)) return NetworkType.wifi;
      if (connectivityResult.contains(ConnectivityResult.mobile)) return NetworkType.cellular;
      if (connectivityResult.contains(ConnectivityResult.none)) return NetworkType.none;
      return NetworkType.unknown;
    } catch (_) {
      return NetworkType.unknown;
    }
  }

  static Future<NetworkReachability> checkBackendReachability() async {
    try {
      // Use a dedicated health endpoint for reachability check
      final url = Uri.parse('${ApiService.baseUrl}/health');
      final response = await http.get(url).timeout(const Duration(seconds: 2));
      if (response.statusCode >= 200 && response.statusCode < 500) {
        return NetworkReachability.reachable;
      }
      return NetworkReachability.unreachable;
    } catch (_) {
      return NetworkReachability.unreachable;
    }
  }
}
