import 'dart:convert';
import 'dart:math';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import '../local/sqlite_service.dart';
import '../network/dio_client.dart';

/// Processes the local `sync_queue` table whenever connectivity returns,
/// retrying failed requests with exponential backoff and reconciling
/// server-authoritative records on a 409 concurrency conflict.
class SyncManager {
  final SQLiteService _sqliteService = SQLiteService();
  final DioClient _dioClient = DioClient();
  bool _isSyncing = false;

  void initialize() {
    Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      if (results.any((r) => r == ConnectivityResult.wifi || r == ConnectivityResult.mobile)) {
        triggerSync();
      }
    });
  }

  Future<void> triggerSync() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      final db = await _sqliteService.database;
      final queueItems = await db.query(
        'sync_queue',
        where: 'status = ?',
        whereArgs: ['PENDING'],
        orderBy: 'created_at ASC',
      );

      for (final item in queueItems) {
        final id = item['id'] as int;
        final endpoint = item['endpoint'] as String;
        final method = item['http_method'] as String;
        final payloadStr = item['payload'] as String;
        final retryCount = item['retry_count'] as int;
        final entityId = item['entity_id'] as String;
        final entityType = item['entity_type'] as String;
        final table = entityType == 'TASK' ? 'tasks' : 'notes';

        try {
          Response response;
          final data = jsonDecode(payloadStr);

          if (method == 'POST') {
            response = await _dioClient.dio.post(endpoint, data: data);
          } else if (method == 'PUT') {
            response = await _dioClient.dio.put('$endpoint/$entityId', data: data);
          } else if (method == 'DELETE') {
            response = await _dioClient.dio.delete('$endpoint/$entityId');
          } else {
            continue;
          }

          if (response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 204) {
            await db.transaction((txn) async {
              await txn.delete('sync_queue', where: 'id = ?', whereArgs: [id]);
              if (method != 'DELETE') {
                final serverVersion = response.data['data']?['version'];
                if (serverVersion != null) {
                  await txn.update(
                    table,
                    {'sync_status': 'SYNCED', 'version': serverVersion},
                    where: 'id = ?',
                    whereArgs: [entityId],
                  );
                } else {
                  await txn.update(
                    table,
                    {'sync_status': 'SYNCED'},
                    where: 'id = ?',
                    whereArgs: [entityId],
                  );
                }
              }
            });
          }
        } on DioException catch (e) {
          if (e.response?.statusCode == 409) {
            // Concurrency Conflict: Overwrite local data with authoritative server record
            final serverData = e.response?.data['details']?['serverRecord'];
            if (serverData != null) {
              await db.transaction((txn) async {
                await txn.delete('sync_queue', where: 'id = ?', whereArgs: [id]);
                await txn.update(
                  table,
                  {
                    'title': serverData['title'],
                    'content': serverData['content'],
                    'version': serverData['version'],
                    'sync_status': 'SYNCED',
                  },
                  where: 'id = ?',
                  whereArgs: [entityId],
                );
              });
            }
          } else {
            // Exponential backoff: wait = min(2^attempt * 1000ms, 30000ms)
            final nextRetry = retryCount + 1;
            if (nextRetry >= 5) {
              await db.update('sync_queue', {'status': 'FAILED'}, where: 'id = ?', whereArgs: [id]);
            } else {
              final waitTimeMs = min(pow(2, nextRetry).toInt() * 1000, 30000);
              await Future.delayed(Duration(milliseconds: waitTimeMs));
              await db.update('sync_queue', {'retry_count': nextRetry}, where: 'id = ?', whereArgs: [id]);
            }
          }
        }
      }
    } finally {
      _isSyncing = false;
    }
  }
}
