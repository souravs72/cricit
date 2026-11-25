import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/settings/settings_controller.dart';
import '../domain/trivia.dart';

final triviaRepositoryProvider = Provider((ref) => TriviaRepository(ref));

class BallVerificationResult {
  const BallVerificationResult({
    required this.ballNumber,
    required this.userAnswer,
    required this.isCorrect,
    required this.correctIndex,
    required this.explanation,
    this.totalPoints,
    this.isOverCompleted = false,
  });

  final int ballNumber;

  /// The answer the server locked in for this ball.
  final int userAnswer;
  final bool isCorrect;
  final int correctIndex;
  final String explanation;
  final int? totalPoints;
  final bool isOverCompleted;
}

/// Either a value or the reason it could not be produced.
class TriviaOutcome<T> {
  const TriviaOutcome.ok(T this.value) : problem = null;
  const TriviaOutcome.failed(TriviaProblem this.problem) : value = null;

  final T? value;
  final TriviaProblem? problem;
}

TriviaProblem _problemFor(Object error) {
  if (error is! DioException) return TriviaProblem.offline;
  final api = toApiException(error);
  if (api.status == 401) return TriviaProblem.signInRequired;
  if (api.code == 'over_not_ready') return TriviaProblem.notReady;
  final body = error.response?.data;
  Object? field;
  if (body is Map<String, dynamic>) {
    final err = body['error'];
    if (err is Map<String, dynamic>) field = err['field'];
  }
  if (api.status == 400 && field == 'name') return TriviaProblem.nameRequired;
  return TriviaProblem.offline;
}

/// Talks to the Daily Over endpoints. There is no offline question bank: every over
/// comes from the server and every answer is checked (and locked in) there.
class TriviaRepository {
  TriviaRepository(this._ref);
  final Ref _ref;

  Future<TriviaOutcome<DailyOver>> fetchDailyOver() async {
    try {
      final res = await _ref
          .read(dioProvider)
          .get<Map<String, dynamic>>('/v1/trivia/daily');
      final data = res.data!;
      final balls = (data['balls'] as List)
          .map((b) => TriviaQuestion.fromJson(b as Map<String, dynamic>))
          .toList();
      return TriviaOutcome.ok(
        DailyOver(date: data['date'] as String, balls: balls),
      );
    } catch (e) {
      return TriviaOutcome.failed(_problemFor(e));
    }
  }

  /// Balls this user already answered today, so a reopened sheet resumes where it left off.
  Future<TriviaOutcome<List<AnsweredBall>>> fetchProgress() async {
    try {
      final res = await _ref.read(dioProvider).post<Map<String, dynamic>>(
        '/v1/trivia/submit',
        data: {'answers': List.filled(6, 0)},
      );
      final results = (res.data!['results'] as List? ?? const [])
          .cast<Map<String, dynamic>>()
          .map(
            (r) => AnsweredBall(
              ballNumber: r['ball_number'] as int,
              userAnswer: r['user_answer'] as int,
              isCorrect: r['is_correct'] as bool,
              correctIndex: r['correct_index'] as int,
              explanation: r['explanation'] as String? ?? '',
            ),
          )
          .toList();
      await _syncFrom(res.data!);
      return TriviaOutcome.ok(results);
    } catch (e) {
      return TriviaOutcome.failed(_problemFor(e));
    }
  }

  Future<TriviaOutcome<BallVerificationResult>> verifyBall({
    required int ballNumber,
    required int answer,
  }) async {
    try {
      final res = await _ref.read(dioProvider).post<Map<String, dynamic>>(
        '/v1/trivia/verify',
        data: {'ball_number': ballNumber, 'answer': answer},
      );
      final d = res.data!;
      return TriviaOutcome.ok(
        BallVerificationResult(
          ballNumber: ballNumber,
          userAnswer: d['user_answer'] as int? ?? answer,
          isCorrect: d['is_correct'] as bool,
          correctIndex: d['correct_index'] as int,
          explanation: d['explanation'] as String? ?? '',
          totalPoints: d['total_points'] as int?,
          isOverCompleted: d['is_over_completed'] as bool? ?? false,
        ),
      );
    } catch (e) {
      return TriviaOutcome.failed(_problemFor(e));
    }
  }

  /// Finalises the over on the server (scoring uses the server's locked answers) and
  /// copies the server's totals into local settings for the profile card.
  Future<void> finishOver() async {
    try {
      final res = await _ref.read(dioProvider).post<Map<String, dynamic>>(
        '/v1/trivia/submit',
        data: {'answers': List.filled(6, 0)},
      );
      await _syncFrom(res.data!);
    } catch (_) {
      // The server already banked the points when ball 6 was verified; the profile
      // refreshes from /v1/trivia/stats next time it opens.
    }
  }

  Future<void> syncProfileStats() async {
    if (!_ref.read(settingsProvider).signedIn) return;
    try {
      final res = await _ref
          .read(dioProvider)
          .get<Map<String, dynamic>>('/v1/trivia/stats');
      final d = res.data!;
      await _ref.read(settingsProvider.notifier).syncTriviaStats(
            points: d['trivia_points'] as int? ?? 0,
            streak: d['trivia_streak'] as int? ?? 0,
          );
    } catch (_) {
      // Keep the last synced totals; they come from the server, never from local play.
    }
  }

  Future<void> _syncFrom(Map<String, dynamic> d) async {
    final total = d['total_points'] as int?;
    final streak = d['streak_days'] as int?;
    if (total == null || streak == null) return;
    await _ref.read(settingsProvider.notifier).syncTriviaStats(
          points: total,
          streak: streak,
        );
  }
}
