import 'package:uuid/uuid.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/sos_event.dart';
import '../database/emergency_local_repository.dart';
import 'connectivity_service.dart';
import 'api_service.dart';
import 'dart:async';

class EmergencyCommunicationManager {
  final EmergencyLocalRepository _repository = EmergencyLocalRepository();
  final Uuid _uuid = const Uuid();

  SosEvent createLocalSosEvent({
    required double latitude,
    required double longitude,
    required double accuracy,
    String? alamatTerdeteksi,
    required String catatan,
  }) {
    final sosEvent = SosEvent(
      sosId: 'SOS-${DateTime.now().toIso8601String().replaceAll(RegExp(r'[^0-9]'), '').substring(0,8)}-${_uuid.v4().substring(0,6).toUpperCase()}',
      latitude: latitude,
      longitude: longitude,
      accuracy: accuracy,
      alamatTerdeteksi: alamatTerdeteksi,
      catatan: catatan,
      createdAt: DateTime.now().toIso8601String(),
      status: SosStatus.created,
    );
    return sosEvent;
  }

  Future<Map<String, dynamic>?> sendEmergency(SosEvent event, NetworkReachability reachability, NetworkType networkType) async {
    event.status = SosStatus.pendingSync;
    await _repository.saveSosEvent(event);

    if (reachability == NetworkReachability.reachable) {
      return await _attemptOnlineSync(event);
    } else {
      // Offline fallback
      if (networkType == NetworkType.cellular || networkType == NetworkType.unknown) {
        // SMS Fallback manual allowed
        await _attemptSmsFallback(event);
      }
      // Else: remain pending sync
      return null;
    }
  }

  Future<Map<String, dynamic>?> _attemptOnlineSync(SosEvent event) async {
    event.status = SosStatus.syncing;
    event.retryCount += 1;
    await _repository.saveSosEvent(event);

    try {
      final responseData = await ApiService.submitSosWithEvent(event);
      if (responseData != null) {
        event.status = SosStatus.synced;
        await _repository.saveSosEvent(event);
        return responseData;
      } else {
        event.status = SosStatus.failedRetry;
        await _repository.saveSosEvent(event);
        
        event.status = SosStatus.pendingSync;
        await _repository.saveSosEvent(event);
      }
    } catch (_) {
      event.status = SosStatus.pendingSync;
      await _repository.saveSosEvent(event);
    }
    return null;
  }

  Future<void> _attemptSmsFallback(SosEvent event) async {
    final message = "SAFEPath SOS\n\n"
        "SOS ID: ${event.sosId}\n\n"
        "Location:\n"
        "https://maps.google.com/?q=${event.latitude},${event.longitude}\n\n"
        "Time:\n"
        "${event.createdAt}\n\n"
        "Message:\n"
        "${event.catatan}";
    
    final uri = Uri(
      scheme: 'sms',
      path: '112', // standard emergency number placeholder
      queryParameters: {'body': message},
    );

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        event.smsIntentOpened = true;
        await _repository.saveSosEvent(event);
      }
    } catch (_) {
      // ignore
    }
  }
}
