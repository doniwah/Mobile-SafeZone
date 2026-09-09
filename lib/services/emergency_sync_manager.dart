import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/sos_event.dart';
import '../database/emergency_local_repository.dart';
import 'connectivity_service.dart';
import 'api_service.dart';
import 'dart:async';
import 'dart:math';

class EmergencySyncManager {
  static final EmergencySyncManager _instance = EmergencySyncManager._internal();
  factory EmergencySyncManager() => _instance;
  EmergencySyncManager._internal();

  final EmergencyLocalRepository _repository = EmergencyLocalRepository();
  StreamSubscription? _connectivitySubscription;
  Timer? _retryTimer;
  bool _isSyncing = false;

  void initialize() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
      if (results.contains(ConnectivityResult.wifi) || results.contains(ConnectivityResult.mobile)) {
        syncPendingEmergencies();
      }
    });
    // Trigger on startup
    syncPendingEmergencies();
    
    // Start background exponential backoff loop
    _scheduleNextRetry(const Duration(seconds: 15));
  }

  void dispose() {
    _connectivitySubscription?.cancel();
    _retryTimer?.cancel();
  }

  void _scheduleNextRetry(Duration delay) {
    _retryTimer?.cancel();
    _retryTimer = Timer(delay, () async {
      await syncPendingEmergencies();
      // Schedule next retry with exponential backoff (capped at 5 minutes)
      final nextDelay = Duration(seconds: min(300, delay.inSeconds * 2));
      _scheduleNextRetry(nextDelay);
    });
  }

  Future<void> syncPendingEmergencies() async {
    if (_isSyncing) return;
    
    final reachability = await ConnectivityService.checkBackendReachability();
    if (reachability != NetworkReachability.reachable) return;

    _isSyncing = true;
    try {
      final queue = await _repository.getPendingSosEvents();
      for (final event in queue) {
        if (event.status == SosStatus.pendingSync || event.status == SosStatus.failedRetry) {
          event.status = SosStatus.syncing;
          event.retryCount += 1;
          await _repository.saveSosEvent(event);

          final responseData = await ApiService.submitSosWithEvent(event);
          if (responseData != null) {
            event.status = SosStatus.synced;
            await _repository.saveSosEvent(event);
          } else {
            event.status = SosStatus.failedRetry;
            await _repository.saveSosEvent(event);
            event.status = SosStatus.pendingSync;
            await _repository.saveSosEvent(event);
          }
        }
      }
    } finally {
      _isSyncing = false;
    }
  }
}
