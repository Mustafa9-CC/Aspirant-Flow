import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'models/models.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'theme/app_theme.dart';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  FlutterForegroundTask.initCommunicationPort();

  Hive.registerAdapter(StudySessionAdapter());
  Hive.registerAdapter(SubjectScoreAdapter());
  Hive.registerAdapter(MasteryStatusAdapter());
  Hive.registerAdapter(SyllabusItemAdapter());
  Hive.registerAdapter(AspirantTypeAdapter());
  Hive.registerAdapter(UserSettingsAdapter());
  Hive.registerAdapter(StudyDocumentAdapter());
  Hive.registerAdapter(StudyNoteAdapter());

  final settingsBox = await Hive.openBox<UserSettings>('user_settings');
  await Hive.openBox<StudySession>('study_sessions');
  await Hive.openBox<SubjectScore>('subject_scores');
  await Hive.openBox<SyllabusItem>('syllabus');
  await Hive.openBox<StudyDocument>('study_documents');
  await Hive.openBox<StudyNote>('study_notes');

  runApp(MyApp(settingsBox: settingsBox));
}

class MyApp extends StatelessWidget {
  final Box<UserSettings> settingsBox;

  const MyApp({super.key, required this.settingsBox});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: settingsBox.listenable(),
      builder: (context, Box<UserSettings> box, _) {
        final settings = box.get('settings');
        // Default to NEET if undefined
        final themeMode = settings?.themeMode;

        ThemeData theme;
        if (themeMode == 'Manga') {
          theme = AppTheme.mangaTheme;
        } else if (themeMode == 'Pink') {
          theme = AppTheme.pinkTheme;
        } else if (themeMode == 'Yellow') {
          theme = AppTheme.yellowTheme;
        } else {
          // Default to NEET/JEE based on type
          final isNeet = settings?.type != AspirantType.jee;
          theme = isNeet ? AppTheme.neetTheme : AppTheme.jeeTheme;
        }

        return MaterialApp(
          title: 'Aspirant Flow',
          debugShowCheckedModeBanner: false,
          theme: theme,
          home: settings?.isOnboardingComplete == true
              ? const HomeScreen()
              : const OnboardingScreen(),
        );
      },
    );
  }
}
