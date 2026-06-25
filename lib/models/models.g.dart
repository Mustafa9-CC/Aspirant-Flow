// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class StudySessionAdapter extends TypeAdapter<StudySession> {
  @override
  final int typeId = 0;

  @override
  StudySession read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StudySession(
      startTime: fields[0] as DateTime,
      durationSeconds: fields[1] as int,
      subject: fields[2] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, StudySession obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.startTime)
      ..writeByte(1)
      ..write(obj.durationSeconds)
      ..writeByte(2)
      ..write(obj.subject);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StudySessionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SubjectScoreAdapter extends TypeAdapter<SubjectScore> {
  @override
  final int typeId = 1;

  @override
  SubjectScore read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SubjectScore(
      subjectName: fields[0] as String,
      score: fields[1] as double,
      maxScore: fields[2] as double,
      date: fields[3] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, SubjectScore obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.subjectName)
      ..writeByte(1)
      ..write(obj.score)
      ..writeByte(2)
      ..write(obj.maxScore)
      ..writeByte(3)
      ..write(obj.date);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubjectScoreAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SyllabusItemAdapter extends TypeAdapter<SyllabusItem> {
  @override
  final int typeId = 3;

  @override
  SyllabusItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SyllabusItem(
      id: fields[0] as String,
      title: fields[1] as String,
      status: fields[2] as MasteryStatus,
      subTopics: (fields[3] as List).cast<SyllabusItem>(),
    );
  }

  @override
  void write(BinaryWriter writer, SyllabusItem obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.status)
      ..writeByte(3)
      ..write(obj.subTopics);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SyllabusItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class UserSettingsAdapter extends TypeAdapter<UserSettings> {
  @override
  final int typeId = 5;

  @override
  UserSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserSettings(
      type: fields[0] as AspirantType,
      isOnboardingComplete: fields[1] as bool,
      themeMode: fields[2] as String?,
      topGoals: (fields[3] as List).cast<String>(),
      testDate: fields[4] as DateTime?,
      goalCompletion: (fields[5] as List).cast<bool>(),
      focusSeconds: fields[6] as int,
    );
  }

  @override
  void write(BinaryWriter writer, UserSettings obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.type)
      ..writeByte(1)
      ..write(obj.isOnboardingComplete)
      ..writeByte(2)
      ..write(obj.themeMode)
      ..writeByte(3)
      ..write(obj.topGoals)
      ..writeByte(4)
      ..write(obj.testDate)
      ..writeByte(5)
      ..write(obj.goalCompletion)
      ..writeByte(6)
      ..write(obj.focusSeconds);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class StudyDocumentAdapter extends TypeAdapter<StudyDocument> {
  @override
  final int typeId = 6;

  @override
  StudyDocument read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StudyDocument(
      id: fields[0] as String,
      path: fields[1] as String,
      name: fields[2] as String,
      type: fields[3] as String,
      dateAdded: fields[4] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, StudyDocument obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.path)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.type)
      ..writeByte(4)
      ..write(obj.dateAdded);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StudyDocumentAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class StudyNoteAdapter extends TypeAdapter<StudyNote> {
  @override
  final int typeId = 7;

  @override
  StudyNote read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StudyNote(
      id: fields[0] as String,
      title: fields[1] as String,
      content: fields[2] as String,
      lastModified: fields[3] as DateTime,
      imagePaths: (fields[4] as List).cast<String>(),
      voiceNotePath: fields[5] as String?,
      tags: (fields[6] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, StudyNote obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.content)
      ..writeByte(3)
      ..write(obj.lastModified)
      ..writeByte(4)
      ..write(obj.imagePaths)
      ..writeByte(5)
      ..write(obj.voiceNotePath)
      ..writeByte(6)
      ..write(obj.tags);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StudyNoteAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MasteryStatusAdapter extends TypeAdapter<MasteryStatus> {
  @override
  final int typeId = 2;

  @override
  MasteryStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return MasteryStatus.pending;
      case 1:
        return MasteryStatus.read;
      case 2:
        return MasteryStatus.pyqsSolved;
      case 3:
        return MasteryStatus.mastered;
      default:
        return MasteryStatus.pending;
    }
  }

  @override
  void write(BinaryWriter writer, MasteryStatus obj) {
    switch (obj) {
      case MasteryStatus.pending:
        writer.writeByte(0);
        break;
      case MasteryStatus.read:
        writer.writeByte(1);
        break;
      case MasteryStatus.pyqsSolved:
        writer.writeByte(2);
        break;
      case MasteryStatus.mastered:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MasteryStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AspirantTypeAdapter extends TypeAdapter<AspirantType> {
  @override
  final int typeId = 4;

  @override
  AspirantType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return AspirantType.neet;
      case 1:
        return AspirantType.jee;
      default:
        return AspirantType.neet;
    }
  }

  @override
  void write(BinaryWriter writer, AspirantType obj) {
    switch (obj) {
      case AspirantType.neet:
        writer.writeByte(0);
        break;
      case AspirantType.jee:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AspirantTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
