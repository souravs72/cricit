import 'dart:convert';
import 'dart:typed_data';

import 'package:cricit/core/api/api_client.dart';
import 'package:cricit/core/settings/settings_controller.dart';
import 'package:cricit/features/trivia/data/trivia_repository.dart';
import 'package:cricit/features/trivia/domain/trivia.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Answers each request from a path -> (status, body) table; unknown paths fail like no network.
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.routes);
  final Map<String, (int, Object)> routes;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final route = routes[options.path];
    if (route == null) {
      throw DioException.connectionError(
        requestOptions: options,
        reason: 'offline',
      );
    }
    return ResponseBody.fromString(
      jsonEncode(route.$2),
      route.$1,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Map<String, dynamic> _error(String code, String message, {String? field}) => {
      'error': {
        'code': code,
        'message': message,
        'request_id': 'r1',
        if (field != null) 'field': field,
      },
    };

final _over = {
  'date': '2026-11-25',
  'total_balls': 6,
  'balls': [
    for (var i = 1; i <= 6; i++)
      {
        'ball_number': i,
        'category': 'domestic',
        'difficulty': 'medium',
        'question': 'Question $i?',
        'options': ['A', 'B', 'C', 'D'],
      },
  ],
};

Future<(ProviderContainer, _FakeAdapter)> _container(
  Map<String, (int, Object)> routes,
) async {
  SharedPreferences.setMockInitialValues({});
  final adapter = _FakeAdapter(routes);
  final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
    ..httpClientAdapter = adapter;
  final container = ProviderContainer(
    overrides: [dioProvider.overrideWithValue(dio)],
  );
  addTearDown(container.dispose);
  await container.read(settingsProvider.notifier).hydrate();
  return (container, adapter);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Daily Over comes only from the server', () {
    test('loads the over without any answers in it', () async {
      final (c, _) = await _container({'/v1/trivia/daily': (200, _over)});
      final result = await c.read(triviaRepositoryProvider).fetchDailyOver();
      expect(result.problem, isNull);
      expect(result.value!.balls, hasLength(6));
      expect(result.value!.balls.first.correctIndex, isNull);
      expect(result.value!.date, '2026-11-25');
    });

    test(
        'a day without a generated over is "being prepared", not a fallback quiz',
        () async {
      final (c, _) = await _container({
        '/v1/trivia/daily': (404, _error('over_not_ready', 'being prepared')),
      });
      final result = await c.read(triviaRepositoryProvider).fetchDailyOver();
      expect(result.value, isNull);
      expect(result.problem, TriviaProblem.notReady);
    });

    test('no network means offline, never a built-in over', () async {
      final (c, _) = await _container({});
      final result = await c.read(triviaRepositoryProvider).fetchDailyOver();
      expect(result.value, isNull);
      expect(result.problem, TriviaProblem.offline);
    });
  });

  group('Answers are checked and locked on the server', () {
    test('shows the answer the server locked in, not the latest tap', () async {
      final (c, _) = await _container({
        '/v1/trivia/verify': (
          200,
          {
            'ball_number': 1,
            'user_answer': 2,
            'is_correct': false,
            'correct_index': 1,
            'explanation': 'Because.',
            'points_earned': 0,
            'total_points': 10,
            'is_over_completed': false,
          },
        ),
      });
      final result = await c
          .read(triviaRepositoryProvider)
          .verifyBall(ballNumber: 1, answer: 1);
      expect(result.value!.userAnswer, 2);
      expect(result.value!.isCorrect, isFalse);
      expect(result.value!.correctIndex, 1);
    });

    test('signed-out and nameless players get a clear reason', () async {
      final (c401, _) = await _container({
        '/v1/trivia/verify': (
          401,
          _error('unauthorized', 'Sign in to continue')
        ),
      });
      final signedOut = await c401
          .read(triviaRepositoryProvider)
          .verifyBall(ballNumber: 1, answer: 0);
      expect(signedOut.problem, TriviaProblem.signInRequired);

      final (cName, _) = await _container({
        '/v1/trivia/verify': (
          400,
          _error(
            'bad_request',
            'Please set up your profile name',
            field: 'name',
          ),
        ),
      });
      final nameless = await cName
          .read(triviaRepositoryProvider)
          .verifyBall(ballNumber: 1, answer: 0);
      expect(nameless.problem, TriviaProblem.nameRequired);
    });

    test('a failed check is offline so the player can retry the same ball',
        () async {
      final (c, _) = await _container({});
      final result = await c
          .read(triviaRepositoryProvider)
          .verifyBall(ballNumber: 3, answer: 0);
      expect(result.problem, TriviaProblem.offline);
    });
  });

  group('Progress and points come from the server', () {
    test('reopening resumes answered balls and syncs server totals', () async {
      final (c, _) = await _container({
        '/v1/trivia/submit': (
          200,
          {
            'points_earned': 0,
            'total_points': 42,
            'streak_days': 3,
            'already_submitted': false,
            'results': [
              {
                'ball_number': 1,
                'user_answer': 0,
                'is_correct': true,
                'correct_index': 0,
                'explanation': 'x',
              },
              {
                'ball_number': 2,
                'user_answer': 3,
                'is_correct': false,
                'correct_index': 1,
                'explanation': 'y',
              },
            ],
          },
        ),
      });
      final result = await c.read(triviaRepositoryProvider).fetchProgress();
      expect(result.value!.map((b) => b.ballNumber), [1, 2]);
      expect(result.value![1].userAnswer, 3);
      expect(c.read(settingsProvider).triviaPoints, 42);
      expect(c.read(settingsProvider).triviaStreak, 3);
    });

    test('profile totals are replaced by the server values', () async {
      final (c, _) = await _container({
        '/v1/trivia/stats': (200, {'trivia_points': 17, 'trivia_streak': 2}),
      });
      await c
          .read(settingsProvider.notifier)
          .completeOnboarding(signedIn: true);
      await c.read(triviaRepositoryProvider).syncProfileStats();
      expect(c.read(settingsProvider).triviaPoints, 17);
      expect(c.read(settingsProvider).triviaStreak, 2);
    });

    test('signed-out profiles never call the server for stats', () async {
      final (c, adapter) = await _container({
        '/v1/trivia/stats': (200, {'trivia_points': 99, 'trivia_streak': 9}),
      });
      await c.read(triviaRepositoryProvider).syncProfileStats();
      expect(adapter.requests, isEmpty);
      expect(c.read(settingsProvider).triviaPoints, 0);
    });
  });
}
