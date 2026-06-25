import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import '../models/models.dart';
import '../services/foreground_service.dart';

class AudioService {
  final AudioPlayer _player = AudioPlayer();

  Future<void> playMonkMode() async {
    try {
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.play(AssetSource('audio/monk_mode.mp3'));
    } catch (e) {
      debugPrint("Audio play error: $e");
    }
  }

  Future<void> stop() async {
    await _player.stop();
  }

  Future<void> setVolume(double volume) async {
    await _player.setVolume(volume);
  }
}

class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> with WidgetsBindingObserver {
  int _remainingSeconds = 25 * 60;
  int _initialSeconds = 25 * 60;
  bool _isRunning = false;
  final AudioService _audioService = AudioService();
  double _volume = 0.5;
  // No longer needed for FlutterForegroundTask data in v6+
  // StreamSubscription? _dataSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initForegroundTask();
  }

  void _initForegroundTask() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        id: 101,
        channelId: 'focus_channel',
        channelName: 'Focus Mode',
        channelDescription: 'Keep focus timer running in background',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(1000),
        autoRunOnBoot: false,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );

    // Register a callback to receive data sent from the TaskHandler.
    FlutterForegroundTask.addTaskDataCallback(_onReceiveTaskData);
  }

  void _onReceiveTaskData(Object data) {
    if (data is int) {
      setState(() {
        _remainingSeconds = data;
        if (_remainingSeconds <= 0 && _isRunning) {
          _stopTimer();
        }
      });
    }
  }

  @override
  void dispose() {
    _audioService.stop();
    FlutterForegroundTask.removeTaskDataCallback(_onReceiveTaskData);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _startTimer() async {
    final box = Hive.box<UserSettings>('user_settings');
    final settings = box.get('settings')!;
    await box.put(
        'settings', settings.copyWith(focusSeconds: _remainingSeconds));

    setState(() => _isRunning = true);
    _audioService.playMonkMode();
    _audioService.setVolume(_volume);

    if (await FlutterForegroundTask.isRunningService) {
      FlutterForegroundTask.restartService();
    } else {
      await FlutterForegroundTask.startService(
        notificationTitle: 'Deep Focus Active',
        notificationText: 'Preparing...',
        callback: startCallback,
      );
    }
  }

  Future<void> _stopTimer() async {
    await FlutterForegroundTask.stopService();
    _audioService.stop();
    setState(() {
      _isRunning = false;
      _remainingSeconds = _initialSeconds;
    });
  }

  Future<void> _handleStartStop() async {
    if (_isRunning) {
      _stopTimer();
    } else {
      final shouldStart = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text('Start Deep Work?',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          content: const Text(
              'Your focus session will start now. Stay focused and avoid distractions.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Maybe later'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('I\'m Ready'),
            ),
          ],
        ),
      );

      if (shouldStart == true) {
        _startTimer();
      }
    }
  }

  String get _timerText {
    final minutes = (_remainingSeconds / 60).floor().toString().padLeft(2, '0');
    final seconds = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _showCountdownPicker(
      Box<UserSettings> box, UserSettings settings) async {
    final picked = await showDatePicker(
      context: context,
      initialDate:
          settings.testDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      box.put('settings', settings.copyWith(testDate: picked));
    }
  }

  void _addGoal(Box<UserSettings> box, UserSettings settings) {
    if (settings.topGoals.length >= 3) return;

    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Goal',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          decoration:
              const InputDecoration(hintText: 'e.g., Solve 50 Bio MCQs'),
          autofocus: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                final newGoals = List<String>.from(settings.topGoals)
                  ..add(controller.text);
                final newCompletion = List<bool>.from(settings.goalCompletion)
                  ..add(false);
                box.put(
                    'settings',
                    settings.copyWith(
                        topGoals: newGoals, goalCompletion: newCompletion));
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _toggleGoal(Box<UserSettings> box, UserSettings settings, int index) {
    final newCompletion = List<bool>.from(settings.goalCompletion);
    if (index < newCompletion.length) {
      newCompletion[index] = !newCompletion[index];
    } else {
      // Safety for race conditions or schema changes
      while (newCompletion.length <= index) newCompletion.add(false);
      newCompletion[index] = true;
    }
    box.put('settings', settings.copyWith(goalCompletion: newCompletion));
  }

  Widget _buildProgressOrb(ThemeData theme, UserSettings settings) {
    final completedCount = settings.goalCompletion.where((e) => e).length;
    final totalCount = settings.topGoals.length;
    final double percent = totalCount == 0 ? 0 : completedCount / totalCount;

    return Container(
      width: 45,
      height: 45,
      margin: const EdgeInsets.only(right: 12),
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: percent,
            strokeWidth: 3,
            backgroundColor: theme.colorScheme.primary.withAlpha(20),
            color: theme.colorScheme.primary,
          ),
          Text(
            '${(percent * 100).toInt()}%',
            style: GoogleFonts.outfit(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress =
        _initialSeconds > 0 ? _remainingSeconds / _initialSeconds : 0.0;

    final settingsBox = Hive.box<UserSettings>('user_settings');

    return Scaffold(
      body: ValueListenableBuilder(
        valueListenable: settingsBox.listenable(),
        builder: (context, box, _) {
          final settings = box.get('settings')!;
          final now = DateTime.now();
          final diff = settings.testDate != null
              ? settings.testDate!.difference(now)
              : null;
          final daysLeft = diff?.inDays ?? 0;

          return SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 20),
                if (!_isRunning)
                  GestureDetector(
                    onTap: () => _showCountdownPicker(settingsBox, settings),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withAlpha(20),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: theme.colorScheme.primary.withAlpha(50)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.event,
                              size: 16, color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            settings.testDate == null
                                ? 'Set Test Date'
                                : '$daysLeft Days until Test',
                            style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
                Text(
                  _isRunning ? 'FOCUS MODE' : 'SET YOUR GOAL',
                  style: GoogleFonts.outfit(
                      letterSpacing: 4,
                      fontWeight: FontWeight.w300,
                      color: theme.colorScheme.primary.withAlpha(150)),
                ),
                const Spacer(),
                if (!_isRunning) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('TOP 3 GOALS',
                                      style: GoogleFonts.outfit(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w900,
                                          color: theme.colorScheme.primary,
                                          letterSpacing: 2)),
                                  const SizedBox(height: 4),
                                  Text(
                                    settings.topGoals.isEmpty
                                        ? 'Day feels wasted? Save it now.'
                                        : settings.goalCompletion
                                                    .every((e) => e) &&
                                                settings.topGoals.isNotEmpty
                                            ? 'You\'ve reclaimed your day. King!'
                                            : 'Win these 3 and you\'ve reclaimed your future.',
                                    style: GoogleFonts.outfit(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                            if (settings.topGoals.isNotEmpty)
                              _buildProgressOrb(theme, settings),
                            if (settings.topGoals.length < 3)
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline,
                                    size: 24),
                                onPressed: () =>
                                    _addGoal(settingsBox, settings),
                                color: theme.colorScheme.primary,
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ...settings.topGoals.asMap().entries.map((e) {
                          final isCompleted =
                              settings.goalCompletion.length > e.key
                                  ? settings.goalCompletion[e.key]
                                  : false;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: isCompleted
                                  ? theme.colorScheme.primary.withAlpha(20)
                                  : theme.colorScheme.surfaceContainerHighest
                                      .withAlpha(80),
                              borderRadius: BorderRadius.circular(16),
                              border: isCompleted
                                  ? Border.all(
                                      color: theme.colorScheme.primary
                                          .withAlpha(100),
                                      width: 1)
                                  : null,
                            ),
                            child: ListTile(
                              onTap: () =>
                                  _toggleGoal(settingsBox, settings, e.key),
                              dense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 4),
                              leading: Icon(
                                  isCompleted
                                      ? Icons.check_circle
                                      : Icons.circle_outlined,
                                  color: isCompleted
                                      ? theme.colorScheme.primary
                                      : Colors.grey,
                                  size: 22),
                              title: Text(e.value,
                                  style: GoogleFonts.outfit(
                                      fontSize: 15,
                                      fontWeight: isCompleted
                                          ? FontWeight.bold
                                          : FontWeight.w500,
                                      decoration: isCompleted
                                          ? TextDecoration.lineThrough
                                          : null,
                                      color: isCompleted
                                          ? theme.colorScheme.primary
                                              .withAlpha(180)
                                          : null)),
                              trailing: IconButton(
                                icon: const Icon(Icons.remove_circle_outline,
                                    size: 18, color: Colors.grey),
                                onPressed: () {
                                  final newGoals =
                                      List<String>.from(settings.topGoals)
                                        ..removeAt(e.key);
                                  final newCompletion =
                                      List<bool>.from(settings.goalCompletion)
                                        ..removeAt(e.key);
                                  settingsBox.put(
                                      'settings',
                                      settings.copyWith(
                                          topGoals: newGoals,
                                          goalCompletion: newCompletion));
                                },
                              ),
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                  const Spacer(),
                ],
                Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 280,
                        height: 280,
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 4,
                          backgroundColor:
                              theme.colorScheme.primary.withAlpha(20),
                          color: theme.colorScheme.primary,
                          strokeCap: StrokeCap.round,
                        ),
                      ),
                      _isRunning
                          ? Text(_timerText,
                              style: GoogleFonts.outfit(
                                  fontSize: 72,
                                  fontWeight: FontWeight.w200,
                                  color: theme.colorScheme.onSurface))
                          : Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('${(_initialSeconds / 60).round()}',
                                    style: GoogleFonts.outfit(
                                        fontSize: 90,
                                        fontWeight: FontWeight.w100,
                                        height: 1)),
                                Text('minutes',
                                    style: GoogleFonts.outfit(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w400,
                                        color: theme.colorScheme.primary)),
                              ],
                            ),
                    ],
                  ),
                ),
                const Spacer(),
                if (!_isRunning) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 2,
                        activeTrackColor: theme.colorScheme.primary,
                        inactiveTrackColor:
                            theme.colorScheme.primary.withAlpha(30),
                        thumbColor: theme.colorScheme.primary,
                        overlayColor: theme.colorScheme.primary.withAlpha(30),
                      ),
                      child: Slider(
                        value: (_initialSeconds / 60).toDouble(),
                        min: 5,
                        max: 180,
                        divisions: 35,
                        onChanged: (val) {
                          setState(() {
                            final newSeconds = (val * 60).toInt();
                            _remainingSeconds = newSeconds;
                            _initialSeconds = newSeconds;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                if (_isRunning)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 60, vertical: 20),
                    child: Row(
                      children: [
                        Icon(Icons.volume_mute,
                            size: 20,
                            color: theme.colorScheme.primary.withAlpha(150)),
                        Expanded(
                          child: Slider(
                            value: _volume,
                            onChanged: (v) {
                              setState(() => _volume = v);
                              _audioService.setVolume(v);
                            },
                          ),
                        ),
                        Icon(Icons.volume_up,
                            size: 20,
                            color: theme.colorScheme.primary.withAlpha(150)),
                      ],
                    ),
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (!_isRunning)
                      const SizedBox(
                          width: 48), // Spacer instead of apps button
                    const SizedBox(width: 24),
                    GestureDetector(
                      onTap: _handleStartStop,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                  color:
                                      theme.colorScheme.primary.withAlpha(80),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10))
                            ]),
                        child: Icon(
                            _isRunning
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            color: theme.colorScheme.onPrimary,
                            size: 40),
                      ),
                    ),
                    const SizedBox(width: 24),
                    if (!_isRunning)
                      _buildIconButton(context, Icons.history_edu, () {}),
                  ],
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildIconButton(
      BuildContext context, IconData icon, VoidCallback onTap) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withAlpha(100),
            borderRadius: BorderRadius.circular(20)),
        child: Icon(icon, color: theme.colorScheme.primary),
      ),
    );
  }
}
