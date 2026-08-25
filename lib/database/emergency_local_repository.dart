import 'package:shared_preferences/shared_preferences.dart';
import '../models/sos_event.dart';

class EmergencyLocalRepository {
  static const String _key = 'pending_sos_queue';

  Future<void> saveSosEvent(SosEvent event) async {
    final prefs = await SharedPreferences.getInstance();
    List<SosEvent> queue = await getPendingSosEvents();
    
    int index = queue.indexWhere((e) => e.sosId == event.sosId);
    if (index != -1) {
      queue[index] = event;
    } else {
      queue.add(event);
    }
    
    await prefs.setStringList(_key, queue.map((e) => e.toJson()).toList());
  }

  Future<List<SosEvent>> getPendingSosEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? [];
    return list.map((e) => SosEvent.fromJson(e)).toList();
  }
  
  Future<void> removeSosEvent(String sosId) async {
    final prefs = await SharedPreferences.getInstance();
    List<SosEvent> queue = await getPendingSosEvents();
    queue.removeWhere((e) => e.sosId == sosId);
    await prefs.setStringList(_key, queue.map((e) => e.toJson()).toList());
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
