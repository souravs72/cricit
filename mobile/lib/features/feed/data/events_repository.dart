import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/device/device_id.dart';

Map<String, dynamic> readerEvent({
  required String name,
  String? postId,
  String? campaignId,
}) {
  return {
    'name': name,
    if (postId != null) 'post_id': postId,
    if (campaignId != null) 'campaign_id': campaignId,
  };
}

/// Best-effort POST /v1/events. Coalesces to at most one request per second.
class EventsRepository {
  EventsRepository(this._dio, {Future<String> Function()? deviceId})
      : _deviceId = deviceId ?? DeviceId.load;

  static const minGap = Duration(seconds: 1);

  final Dio _dio;
  final Future<String> Function() _deviceId;
  final List<Map<String, dynamic>> queue = [];
  Timer? _timer;
  DateTime? _lastSend;

  void enqueue({
    required String name,
    String? postId,
    String? campaignId,
  }) {
    queue.add(
      readerEvent(name: name, postId: postId, campaignId: campaignId),
    );
    schedule();
  }

  void schedule() {
    if (_timer != null || queue.isEmpty) return;
    final elapsed = _lastSend == null
        ? minGap
        : minGap - DateTime.now().difference(_lastSend!);
    final wait = elapsed.isNegative ? Duration.zero : elapsed;
    _timer = Timer(wait, sendQueued);
  }

  Future<void> sendQueued() async {
    _timer?.cancel();
    _timer = null;
    if (queue.isEmpty) return;
    final end = queue.length < 100 ? queue.length : 100;
    final batch = List<Map<String, dynamic>>.from(queue.sublist(0, end));
    queue.removeRange(0, end);
    try {
      await _dio.post<void>(
        '/v1/events',
        data: {
          'device_id': await _deviceId(),
          'events': batch,
        },
      );
      _lastSend = DateTime.now();
    } on DioException catch (e) {
      if (e.response?.statusCode == 429) {
        queue.insertAll(0, batch);
      }
      _lastSend = DateTime.now();
    }
    if (queue.isNotEmpty) schedule();
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}

final eventsRepositoryProvider = Provider((ref) {
  final repo = EventsRepository(ref.watch(dioProvider));
  ref.onDispose(repo.dispose);
  return repo;
});
