import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/models.dart';
import '../theme/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  AspirantType _selectedType = AspirantType.neet;

  Future<void> _completeOnboarding() async {
    final box = Hive.box<UserSettings>('user_settings');
    await box.put(
        'settings',
        UserSettings(
          type: _selectedType,
          isOnboardingComplete: true,
        ));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = _selectedType == AspirantType.neet
        ? AppTheme.neetTheme.colorScheme
        : AppTheme.jeeTheme.colorScheme;

    return Theme(
      data: _selectedType == AspirantType.neet
          ? AppTheme.neetTheme
          : AppTheme.jeeTheme,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildSelectionPage(colorScheme),
                  ],
                ),
              ),
              _buildBottomControls(colorScheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionPage(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Welcome to\nAspirant Flow',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Your minimalist path to success.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 48),
          _buildTypeCard('Medical (NEET)', AspirantType.neet,
              Icons.medical_services_outlined, colorScheme),
          const SizedBox(height: 16),
          _buildTypeCard('Engineering (JEE)', AspirantType.jee,
              Icons.engineering_outlined, colorScheme),
        ],
      ),
    );
  }

  Widget _buildTypeCard(
      String title, AspirantType type, IconData icon, ColorScheme colorScheme) {
    final isSelected = _selectedType == type;
    final color =
        type == AspirantType.neet ? AppTheme.medicalTeal : AppTheme.jeeNavy;

    return Material(
      color: isSelected ? color.withAlpha(25) : Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: isSelected ? 0 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected ? color : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: () => setState(() => _selectedType = type),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(width: 16),
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              if (isSelected) Icon(Icons.check_circle, color: color)
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomControls(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: () async {
              await _completeOnboarding();
            },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(200, 48),
            ),
            child: const Text('Get Started'),
          ),
        ],
      ),
    );
  }
}
