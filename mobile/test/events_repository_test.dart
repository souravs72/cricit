import 'package:cricit/features/feed/data/events_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const postId = '0192f1a0-0000-7000-8000-000000000001';
  const campaignId = '0192f1a0-0000-7000-8000-0000000000ad';

  test('readerEvent matches POST /v1/events item shape', () {
    expect(
      readerEvent(name: 'view', postId: postId),
      {'name': 'view', 'post_id': postId},
    );
    expect(
      readerEvent(name: 'ad_click', campaignId: campaignId),
      {'name': 'ad_click', 'campaign_id': campaignId},
    );
  });

  test('sendQueued posts device_id and at most 100 events', () async {
    Map<String, dynamic>? body;
    final dio = Dio()
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            body = options.data as Map<String, dynamic>?;
            handler.resolve(
              Response(requestOptions: options, statusCode: 204),
            );
          },
        ),
      );
    final repo = EventsRepository(dio, deviceId: () async => 'device-01');
    for (var i = 0; i < 101; i++) {
      repo.enqueue(name: 'view', postId: postId);
    }
    await repo.sendQueued();
    expect(body?['device_id'], 'device-01');
    expect((body?['events'] as List).length, 100);
    expect(repo.queue, hasLength(1));
    repo.dispose();
  });

  test('429 puts the batch back on the queue', () async {
    final dio = Dio()
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.reject(
              DioException(
                requestOptions: options,
                response: Response(requestOptions: options, statusCode: 429),
                type: DioExceptionType.badResponse,
              ),
            );
          },
        ),
      );
    final repo = EventsRepository(dio, deviceId: () async => 'device-01');
    repo.enqueue(name: 'view', postId: postId);
    await repo.sendQueued();
    expect(repo.queue, hasLength(1));
    repo.dispose();
  });
}
