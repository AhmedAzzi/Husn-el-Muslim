import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _clickSoundEnabled = true;
  bool _vibrationEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _clickSoundEnabled = prefs.getBool('click_sound_enabled') ?? true;
      _vibrationEnabled = prefs.getBool('vibration_enabled') ?? true;
    });
  }

  Future<void> _toggleClickSound(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('click_sound_enabled', value);
    setState(() {
      _clickSoundEnabled = value;
    });
  }

  Future<void> _toggleVibration(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('vibration_enabled', value);
    setState(() {
      _vibrationEnabled = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF1A1A24),
        appBar: AppBar(
          backgroundColor: const Color(0xFF693B42),
          iconTheme: const IconThemeData(color: Colors.white),
          title: const Text(
            'الإعدادات',
            style: TextStyle(fontFamily: 'Amiri', color: Colors.white),
          ),
        ),
        body: ListView(
          children: [
            SwitchListTile(
              activeThumbColor: const Color(0xFF693B42),
              title: const Text(
                'صوت النقرة',
                style: TextStyle(
                  fontFamily: 'Amiri',
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
              value: _clickSoundEnabled,
              onChanged: _toggleClickSound,
            ),
            const Divider(color: Colors.grey, height: 1),
            SwitchListTile(
              activeThumbColor: const Color(0xFF693B42),
              title: const Text(
                'الاهتزاز',
                style: TextStyle(
                  fontFamily: 'Amiri',
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
              value: _vibrationEnabled,
              onChanged: _toggleVibration,
            ),
            const Divider(color: Colors.grey, height: 1),
          ],
        ),
      ),
    );
  }
}
