/// Domain models for the daily 6-ball cricket trivia feature.
class TriviaQuestion {
  const TriviaQuestion({
    required this.ballNumber,
    required this.category,
    required this.difficulty,
    required this.question,
    required this.options,
    this.correctIndex,
    this.explanation,
  });

  final int ballNumber;
  final String category;
  final String difficulty;
  final String question;
  final List<String> options;
  final int? correctIndex;
  final String? explanation;

  factory TriviaQuestion.fromJson(Map<String, dynamic> j) => TriviaQuestion(
        ballNumber: j['ball_number'] as int,
        category: j['category'] as String,
        difficulty: (j['difficulty'] as String? ?? 'medium'),
        question: j['question'] as String,
        options: List<String>.from(j['options'] as List),
        correctIndex: j['correct_index'] as int?,
        explanation: j['explanation'] as String?,
      );
}

/// Today's over as served by the backend. Every over is AI-generated and earns points;
/// answers never ship inside the app.
class DailyOver {
  const DailyOver({required this.date, required this.balls});
  final String date;
  final List<TriviaQuestion> balls;
}

/// Why the over could not be loaded or a ball could not be checked.
enum TriviaProblem {
  /// The server has not generated today's over yet.
  notReady,

  /// Playing needs a signed-in account.
  signInRequired,

  /// The account needs a display name before it can earn points.
  nameRequired,

  /// Network or server failure; safe to retry.
  offline,
}

/// A ball already answered today, restored from the server.
class AnsweredBall {
  const AnsweredBall({
    required this.ballNumber,
    required this.userAnswer,
    required this.isCorrect,
    required this.correctIndex,
    required this.explanation,
  });

  final int ballNumber;
  final int userAnswer;
  final bool isCorrect;
  final int correctIndex;
  final String explanation;
}
