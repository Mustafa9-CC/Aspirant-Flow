import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/models.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  Future<void> _launchUrl(String url) async {
    if (!await launchUrl(Uri.parse(url),
        mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile & Settings'),
        centerTitle: true,
      ),
      body: ValueListenableBuilder<Box<UserSettings>>(
        valueListenable: Hive.box<UserSettings>('user_settings').listenable(),
        builder: (context, box, _) {
          final settings = box.get('settings');
          final aspirantType = settings?.type ?? AspirantType.neet;
          final currentTheme = settings?.themeMode;

          // Ensure settings object exists for callbacks
          final safeSettings = settings ?? UserSettings(type: aspirantType);

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),

                // Settings Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Settings',
                          style: GoogleFonts.outfit(
                              fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),

                      // Aspirant Type Switch
                      Card(
                        elevation: 0,
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest
                            .withAlpha(50),
                        child: SwitchListTile(
                          title: Text('Exam Goal',
                              style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w600)),
                          subtitle: Text(aspirantType == AspirantType.neet
                              ? 'NEET (Medical)'
                              : 'JEE (Engineering)'),
                          value: aspirantType == AspirantType.jee,
                          onChanged: (bool isJee) {
                            final newType =
                                isJee ? AspirantType.jee : AspirantType.neet;
                            final newSettings =
                                settings?.copyWith(type: newType) ??
                                    UserSettings(type: newType);
                            box.put('settings', newSettings);
                          },
                          secondary: Icon(aspirantType == AspirantType.neet
                              ? FontAwesomeIcons.userDoctor
                              : FontAwesomeIcons.computer),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Test Date Selector
                      Card(
                        elevation: 0,
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest
                            .withAlpha(50),
                        child: ListTile(
                          title: Text('Target Exam Date',
                              style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w600)),
                          subtitle: Text(settings?.testDate == null
                              ? 'Not set'
                              : '${settings!.testDate!.day}/${settings.testDate!.month}/${settings.testDate!.year}'),
                          trailing: const Icon(Icons.calendar_today_outlined,
                              size: 20),
                          onTap: () async {
                            final DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: settings?.testDate ??
                                  DateTime.now().add(const Duration(days: 30)),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now()
                                  .add(const Duration(days: 1825)), // 5 years
                            );
                            if (picked != null) {
                              final newSettings =
                                  settings?.copyWith(testDate: picked) ??
                                      UserSettings(
                                          type: aspirantType, testDate: picked);
                              box.put('settings', newSettings);
                            }
                          },
                          leading: const Icon(Icons.timer),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Theme Selector
                      Text('Appearance',
                          style: GoogleFonts.outfit(
                              fontSize: 18, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 4,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 1,
                        children: [
                          _buildThemeCard(context, 'Default', Colors.teal,
                              currentTheme ?? 'Default', box, safeSettings),
                          _buildThemeCard(
                              context,
                              'Midnight',
                              Colors.indigo.shade900,
                              currentTheme ?? 'Default',
                              box,
                              safeSettings),
                          _buildThemeCard(context, 'Pink', Colors.pink,
                              currentTheme ?? 'Default', box, safeSettings),
                          _buildThemeCard(context, 'Yellow', Colors.amber,
                              currentTheme ?? 'Default', box, safeSettings),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Developer Info
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(12),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Aspirant Flow',
                        style: GoogleFonts.outfit(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Developed by',
                        style: GoogleFonts.outfit(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Syed Laiban Shah',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'for the sake of Allah and spreading righteousness',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.primary,
                            fontStyle: FontStyle.italic),
                      ),
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 24),

                      // Links Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildSocialIcon(
                            FontAwesomeIcons.instagram,
                            'https://www.instagram.com/laiban__shah/',
                            Colors.pink,
                          ),
                          _buildSocialIcon(
                            FontAwesomeIcons.youtube,
                            'https://youtube.com/@lantern_oflight?si=kNqbk7383P69yhVN',
                            Colors.red,
                          ),
                          _buildSocialIcon(
                            FontAwesomeIcons.whatsapp,
                            'https://www.whatsapp.com/channel/0029VaeYmbP5PO0zmfC6Yl2J',
                            Colors.green,
                          ),
                          _buildSocialIcon(
                            FontAwesomeIcons.github,
                            'https://github.com/laibanshah?tab=repositories',
                            Colors.black,
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Portfolio Button
                      OutlinedButton.icon(
                          onPressed: () => _launchUrl(
                              'https://utopian-balmoral-588.notion.site/CodeFLow-UI-2d1454504bb280718f2bd5bcca63311e?source=copy_link'),
                          icon: const Icon(Icons.link),
                          label: const Text('Check out Portfolio'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                          )),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildThemeCard(BuildContext context, String name, Color color,
      String currentTheme, Box<UserSettings> box, UserSettings settings) {
    final isSelected = (name == 'Default' &&
            (currentTheme == 'Default' || currentTheme == null)) ||
        currentTheme == name ||
        (name == 'Midnight' && currentTheme == 'Manga');

    return InkWell(
      onTap: () {
        // Map Midnight to Manga for internal logic
        final newValue =
            name == 'Default' ? null : (name == 'Midnight' ? 'Manga' : name);
        final newSettings = settings.copyWith(themeMode: newValue);
        box.put('settings', newSettings);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: color.withAlpha(isSelected ? 255 : 40),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : color.withAlpha(100),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isSelected)
              const Icon(Icons.check_circle, color: Colors.white, size: 20)
            else
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
            const SizedBox(height: 4),
            Text(
              name,
              style: GoogleFonts.outfit(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialIcon(IconData icon, String url, Color color) {
    return IconButton(
      onPressed: () => _launchUrl(url),
      icon: FaIcon(icon, color: color, size: 28),
      tooltip: url,
    );
  }
}
