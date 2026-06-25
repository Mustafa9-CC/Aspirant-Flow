import 'package:hive/hive.dart';

part 'models.g.dart';

@HiveType(typeId: 0)
class StudySession extends HiveObject {
  @HiveField(0)
  final DateTime startTime;

  @HiveField(1)
  final int durationSeconds;

  @HiveField(2)
  final String? subject;

  StudySession(
      {required this.startTime, required this.durationSeconds, this.subject});
}

@HiveType(typeId: 1)
class SubjectScore extends HiveObject {
  @HiveField(0)
  final String subjectName;

  @HiveField(1)
  final double score;

  @HiveField(2)
  final double maxScore;

  @HiveField(3)
  final DateTime date;

  SubjectScore(
      {required this.subjectName,
      required this.score,
      required this.maxScore,
      required this.date});
}

@HiveType(typeId: 2)
enum MasteryStatus {
  @HiveField(0)
  pending,
  @HiveField(1)
  read,
  @HiveField(2)
  pyqsSolved,
  @HiveField(3)
  mastered
}

@HiveType(typeId: 3)
class SyllabusItem extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  MasteryStatus status;

  @HiveField(3)
  List<SyllabusItem> subTopics;

  SyllabusItem(
      {required this.id,
      required this.title,
      this.status = MasteryStatus.pending,
      this.subTopics = const []});
}

@HiveType(typeId: 4)
enum AspirantType {
  @HiveField(0)
  neet,
  @HiveField(1)
  jee
}

@HiveType(typeId: 5)
class UserSettings extends HiveObject {
  @HiveField(0)
  final AspirantType type;

  @HiveField(1)
  final bool isOnboardingComplete;

  @HiveField(2)
  final String? themeMode;

  @HiveField(3)
  final List<String> topGoals;

  @HiveField(4)
  final DateTime? testDate;

  @HiveField(5)
  final List<bool> goalCompletion;

  @HiveField(6)
  final int focusSeconds;

  UserSettings({
    required this.type,
    this.isOnboardingComplete = false,
    this.themeMode,
    this.topGoals = const [],
    this.testDate,
    this.goalCompletion = const [],
    this.focusSeconds = 25 * 60,
  });

  // Create a copyWith
  UserSettings copyWith({
    AspirantType? type,
    bool? isOnboardingComplete,
    Object? themeMode = _sentinel,
    List<String>? topGoals,
    DateTime? testDate,
    List<bool>? goalCompletion,
    int? focusSeconds,
  }) {
    return UserSettings(
      type: type ?? this.type,
      isOnboardingComplete: isOnboardingComplete ?? this.isOnboardingComplete,
      themeMode: themeMode == _sentinel ? this.themeMode : themeMode as String?,
      topGoals: topGoals ?? this.topGoals,
      testDate: testDate ?? this.testDate,
      goalCompletion: goalCompletion ?? this.goalCompletion,
      focusSeconds: focusSeconds ?? this.focusSeconds,
    );
  }

  static const _sentinel = Object();
}

@HiveType(typeId: 6)
class StudyDocument extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String path;

  @HiveField(2)
  final String name;

  @HiveField(3)
  final String type;

  @HiveField(4)
  final DateTime dateAdded;

  StudyDocument({
    required this.id,
    required this.path,
    required this.name,
    required this.type,
    required this.dateAdded,
  });
}

@HiveType(typeId: 7)
class StudyNote extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String content;

  @HiveField(3)
  final DateTime lastModified;

  @HiveField(4)
  final List<String> imagePaths;

  @HiveField(5)
  final String? voiceNotePath;

  @HiveField(6)
  final List<String> tags;

  StudyNote({
    required this.id,
    required this.title,
    required this.content,
    required this.lastModified,
    this.imagePaths = const [],
    this.voiceNotePath,
    this.tags = const [],
  });
}
