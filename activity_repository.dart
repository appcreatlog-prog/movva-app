import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'activity_model.dart';
import 'backend_config.dart';

/// Cache local + sincronização com Supabase quando há sessão autenticada.
class ActivityRepository {
  String get _key => 'movva.activities.v2.${_userId ?? 'guest'}';
  SupabaseClient? get _client => BackendConfig.client;
  String? get _userId => _client?.auth.currentUser?.id;

  Future<List<ActivityRecord>> _getLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      final records = list.map((e) => ActivityRecord.fromJson(Map<String, dynamic>.from(e as Map))).toList();
      records.sort((a, b) => b.date.compareTo(a.date));
      return records;
    } catch (_) { return []; }
  }

  Future<void> _putLocal(List<ActivityRecord> records) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(records.map((r) => r.toJson()).toList()));
  }

  Future<List<ActivityRecord>> getAll() async {
    final local = await _getLocal();
    final client = _client;
    final uid = _userId;
    if (client == null || uid == null) return local;
    try {
      final rows = await client.from('activities').select('id,mode,date,seconds,meters,calories,points').eq('user_id', uid).order('date', ascending: false);
      final remote = (rows as List).map((e) => ActivityRecord.fromJson(Map<String, dynamic>.from(e as Map))).toList();
      final byId = <String, ActivityRecord>{for (final a in remote) a.id: a, for (final a in local) a.id: a};
      final merged = byId.values.toList()..sort((a,b)=>b.date.compareTo(a.date));
      await _putLocal(merged);
      // Envia ao servidor atividades locais ainda não existentes; upsert é idempotente.
      for (final a in local) { await _upsertRemote(a, client, uid); }
      return merged;
    } catch (_) {
      // A aplicação continua utilizável se estiver sem internet.
      return local;
    }
  }

  Future<void> _upsertRemote(ActivityRecord record, SupabaseClient client, String uid) async {
    await client.from('activities').upsert({...record.toJson(), 'user_id': uid});
  }

  Future<void> save(ActivityRecord record) async {
    final records = await _getLocal();
    records.removeWhere((r) => r.id == record.id);
    records.insert(0, record);
    await _putLocal(records);
    final client = _client; final uid = _userId;
    if (client != null && uid != null) {
      try { await _upsertRemote(record, client, uid); } catch (_) { /* fica na fila local para sincronizar depois */ }
    }
  }

  Future<void> delete(String id) async {
    final records = await _getLocal();
    records.removeWhere((r) => r.id == id);
    await _putLocal(records);
    final client = _client; final uid = _userId;
    if (client != null && uid != null) {
      try { await client.from('activities').delete().eq('id', id).eq('user_id', uid); } catch (_) {}
    }
  }

  Future<void> clear() async {
    await _putLocal([]);
    final client = _client; final uid = _userId;
    if (client != null && uid != null) {
      try { await client.from('activities').delete().eq('user_id', uid); } catch (_) {}
    }
  }
}
