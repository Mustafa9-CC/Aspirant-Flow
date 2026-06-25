import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/models.dart';

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(FocusTaskHandler());
}

class FocusTaskHandler extends TaskHandler {
  int _remainingSeconds = 0;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    // Initialize Hive if needed in isolate
    await Hive.initFlutter();

    // Register adapters precisely as in main.dart
    if (!Hive.isAdapterRegistered(0))
      Hive.registerAdapter(StudySessionAdapter());
    if (!Hive.isAdapterRegistered(1))
      Hive.registerAdapter(SubjectScoreAdapter());
    if (!Hive.isAdapterRegistered(2))
      Hive.registerAdapter(MasteryStatusAdapter());
    if (!Hive.isAdapterRegistered(3))
      Hive.registerAdapter(SyllabusItemAdapter());
    if (!Hive.isAdapterRegistered(4))
      Hive.registerAdapter(AspirantTypeAdapter());
    if (!Hive.isAdapterRegistered(5))
      Hive.registerAdapter(UserSettingsAdapter());

    // Read initial time from Hive
    try {
      final box = await Hive.openBox<UserSettings>('user_settings');
      final settings = box.get('settings');
      if (settings != null) {
        _remainingSeconds = settings.focusSeconds;
      }
    } catch (e) {
      _remainingSeconds = 25 * 60; // fallback
    }
  }

  @override
  void onRepeatEvent(DateTime timestamp) async {
    if (_remainingSeconds > 0) {
      _remainingSeconds--;
      FlutterForegroundTask.updateService(
        notificationTitle: 'Deep Focus Active',
        notificationText:
            '${(_remainingSeconds ~/ 60).toString().padLeft(2, '0')}:${(_remainingSeconds % 60).toString().padLeft(2, '0')} remaining',
      );

      // Send data to main isolate
      FlutterForegroundTask.sendDataToMain(_remainingSeconds);
    }
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    // Clean up if needed
  }
}
