import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import '../../core/theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool haptics = true;
  bool music = false;
  bool soundFx = true;
  bool powerups = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Settings', style: T.h2.copyWith(fontSize: 20)),
        centerTitle: true,
      ),
      body: AnimatedBg(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: MediaQuery.of(context).padding.top + 80,
            bottom: 40,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Preferences', style: T.h2.copyWith(color: T.white(0.8))),
              const SizedBox(height: 20),
              GlassCard(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: [
                    _buildSwitch(
                      'Haptic Feedback', 
                      'Feel the puzzle pieces click', 
                      Icons.vibration_rounded, 
                      T.classic, 
                      haptics, 
                      (v) => setState(() => haptics = v)
                    ),
                    const Divider(color: Colors.white10, height: 1),
                    _buildSwitch(
                      'Music', 
                      'Background ambient tracks', 
                      Icons.music_note_rounded, 
                      T.timeAttack, 
                      music, 
                      (v) => setState(() => music = v)
                    ),
                    const Divider(color: Colors.white10, height: 1),
                    _buildSwitch(
                      'Sound Effects', 
                      'Audio for wins and moves', 
                      Icons.volume_up_rounded, 
                      T.daily, 
                      soundFx, 
                      (v) => setState(() => soundFx = v)
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              Text('Game Setup', style: T.h2.copyWith(color: T.white(0.8))),
              const SizedBox(height: 20),
              GlassCard(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: [
                    _buildSwitch(
                      'Enable Powerups', 
                      'Allow hints and auto-solves', 
                      Icons.bolt_rounded, 
                      T.duel, 
                      powerups, 
                      (v) => setState(() => powerups = v)
                    ),
                    const Divider(color: Colors.white10, height: 1),
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: T.custom.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: T.custom.withValues(alpha: 0.3)),
                        ),
                        child: const Icon(Icons.restore_rounded, color: T.custom, size: 22),
                      ),
                      title: Text('Reset Progress', style: T.h2.copyWith(fontSize: 18, color: Colors.redAccent)),
                      subtitle: Text('Clear all achievements', style: T.caption),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white30, size: 16),
                      onTap: () {},
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 60),
              Center(
                child: Text('Version 2.0.0(NeoUI)', style: T.caption.copyWith(color: Colors.white38)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwitch(String title, String subtitle, IconData icon, Color color, bool value, ValueChanged<bool> onChanged) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(title, style: T.h2.copyWith(fontSize: 18)),
      subtitle: Text(subtitle, style: T.caption),
      trailing: CupertinoSwitch(
        value: value,
        activeTrackColor: color,
        inactiveTrackColor: Colors.white.withValues(alpha: 0.1),
        onChanged: onChanged,
      ),
    );
  }
}
