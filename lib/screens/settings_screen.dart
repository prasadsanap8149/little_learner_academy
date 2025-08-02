import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/game_provider.dart';
import '../services/sound_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SoundService _soundService = SoundService();
  bool _soundEnabled = true;
  bool _musicEnabled = true;
  double _soundVolume = 0.8;
  double _musicVolume = 0.6;
  String _selectedLanguage = 'English';
  
  final List<Map<String, String>> _languages = [
    {'code': 'en', 'name': 'English', 'flag': '🇺🇸'},
    {'code': 'es', 'name': 'Español', 'flag': '🇪🇸'},
    {'code': 'fr', 'name': 'Français', 'flag': '🇫🇷'},
    {'code': 'de', 'name': 'Deutsch', 'flag': '🇩🇪'},
    {'code': 'hi', 'name': 'हिंदी', 'flag': '🇮🇳'},
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _initializeSoundService();
  }

  Future<void> _initializeSoundService() async {
    try {
      await _soundService.initialize();
    } catch (e) {
      print('Error initializing sound service: $e');
    }
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _soundEnabled = prefs.getBool('sound_enabled') ?? true;
      _musicEnabled = prefs.getBool('music_enabled') ?? true;
      _soundVolume = prefs.getDouble('sound_volume') ?? 0.8;
      _musicVolume = prefs.getDouble('music_volume') ?? 0.6;
      _selectedLanguage = prefs.getString('selected_language') ?? 'English';
    });
    
    // Apply settings to sound service
    await _soundService.loadSettings(
      soundEnabled: _soundEnabled,
      musicEnabled: _musicEnabled,
      soundVolume: _soundVolume,
      musicVolume: _musicVolume,
    );
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sound_enabled', _soundEnabled);
    await prefs.setBool('music_enabled', _musicEnabled);
    await prefs.setDouble('sound_volume', _soundVolume);
    await prefs.setDouble('music_volume', _musicVolume);
    await prefs.setString('selected_language', _selectedLanguage);
  }

  @override
  Widget build(BuildContext context) {
    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF6B73FF),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF6B73FF), Color(0xFF9A8EFF)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isTablet ? 32 : 16),
            child: Column(
              children: [
                // Sound Settings Card
                _buildSettingsCard(
                  title: '🔊 Sound Settings',
                  children: [
                    _buildSwitchTile(
                      icon: Icons.volume_up,
                      title: 'Sound Effects',
                      subtitle: 'Enable game sound effects',
                      value: _soundEnabled,
                      onChanged: (value) {
                        setState(() => _soundEnabled = value);
                        _soundService.setMuted(!value);
                        _saveSettings();
                        if (value) _soundService.playClick();
                      },
                    ),
                    if (_soundEnabled) ...[
                      _buildSliderTile(
                        icon: Icons.volume_down,
                        title: 'Effects Volume',
                        value: _soundVolume,
                        onChanged: (value) {
                          setState(() => _soundVolume = value);
                          _soundService.setEffectsVolume(value);
                          _saveSettings();
                        },
                      ),
                    ],
                    const Divider(color: Colors.grey),
                    _buildSwitchTile(
                      icon: Icons.music_note,
                      title: 'Background Music',
                      subtitle: 'Enable background music',
                      value: _musicEnabled,
                      onChanged: (value) {
                        setState(() => _musicEnabled = value);
                        if (value) {
                          _soundService.playBackgroundMusic();
                        } else {
                          _soundService.stopBackgroundMusic();
                        }
                        _saveSettings();
                      },
                    ),
                    if (_musicEnabled) ...[
                      _buildSliderTile(
                        icon: Icons.music_off,
                        title: 'Music Volume',
                        value: _musicVolume,
                        onChanged: (value) {
                          setState(() => _musicVolume = value);
                          _soundService.setMusicVolume(value);
                          _saveSettings();
                        },
                      ),
                    ],
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Language Settings Card
                _buildSettingsCard(
                  title: '🌐 Language Settings',
                  children: [
                    _buildLanguageTile(),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // App Information Card
                _buildSettingsCard(
                  title: 'ℹ️ App Information',
                  children: [
                    _buildInfoTile(
                      icon: Icons.info_outline,
                      title: 'About',
                      subtitle: 'Little Learners Academy v1.0.0',
                      onTap: () => _showAboutDialog(),
                    ),
                    _buildInfoTile(
                      icon: Icons.privacy_tip_outlined,
                      title: 'Privacy Policy',
                      subtitle: 'View our privacy policy',
                      onTap: () => _showPrivacyPolicy(),
                    ),
                    _buildInfoTile(
                      icon: Icons.help_outline,
                      title: 'Help & Support',
                      subtitle: 'Get help and contact support',
                      onTap: () => _showHelpDialog(),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Account Settings Card
                _buildSettingsCard(
                  title: '👤 Account',
                  children: [
                    _buildInfoTile(
                      icon: Icons.logout,
                      title: 'Logout',
                      subtitle: 'Sign out of your account',
                      titleColor: Colors.red,
                      iconColor: Colors.red,
                      onTap: () => _showLogoutDialog(gameProvider),
                    ),
                  ],
                ),
                
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsCard({
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Color(0xFFF8F9FA)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
              ),
              const SizedBox(height: 16),
              ...children,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF6B73FF).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: const Color(0xFF6B73FF)),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: Color(0xFF2D3748),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 12,
        ),
      ),
      trailing: Switch.adaptive(
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFF6B73FF),
      ),
    );
  }

  Widget _buildSliderTile({
    required IconData icon,
    required String title,
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, left: 56),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 14,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
            ),
            child: Slider(
              value: value,
              onChanged: onChanged,
              activeColor: const Color(0xFF6B73FF),
              inactiveColor: Colors.grey[300],
              min: 0.0,
              max: 1.0,
              divisions: 10,
              label: '${(value * 100).round()}%',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageTile() {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF6B73FF).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.language, color: Color(0xFF6B73FF)),
      ),
      title: const Text(
        'Language',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: Color(0xFF2D3748),
        ),
      ),
      subtitle: Text(
        _selectedLanguage,
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 12,
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),                      onTap: () {
                        try {
                          _soundService.playClick();
                        } catch (e) {
                          print('Error playing click sound: $e');
                        }
                        _showLanguageDialog();
                      },
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? titleColor,
    Color? iconColor,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (iconColor ?? const Color(0xFF6B73FF)).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor ?? const Color(0xFF6B73FF)),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: titleColor ?? const Color(0xFF2D3748),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 12,
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Select Language',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _languages.length,
            itemBuilder: (context, index) {
              final language = _languages[index];
              final isSelected = language['name'] == _selectedLanguage;
              
              return ListTile(
                leading: Text(
                  language['flag']!,
                  style: const TextStyle(fontSize: 24),
                ),
                title: Text(
                  language['name']!,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? const Color(0xFF6B73FF) : null,
                  ),
                ),
                trailing: isSelected
                    ? const Icon(Icons.check, color: Color(0xFF6B73FF))
                    : null,
                onTap: () {
                  setState(() => _selectedLanguage = language['name']!);
                  _saveSettings();
                  try {
                    _soundService.playClick();
                  } catch (e) {
                    print('Error playing click sound: $e');
                  }
                  Navigator.of(context).pop();
                  
                  // Show coming soon message for non-English languages
                  if (language['code'] != 'en') {
                    _showComingSoonDialog(language['name']!);
                  }
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF6B73FF)),
            ),
          ),
        ],
      ),
    );
  }

  void _showComingSoonDialog(String language) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('🚧 Coming Soon!'),
        content: Text(
          '$language support is currently in development and will be available in a future update.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'OK',
              style: TextStyle(color: Color(0xFF6B73FF)),
            ),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: 'Little Learners Academy',
      applicationVersion: '1.0.0',
      applicationIcon: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: const Color(0xFF6B73FF),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(
          Icons.school,
          color: Colors.white,
          size: 32,
        ),
      ),
      children: [
        const SizedBox(height: 16),
        const Text(
          'An engaging educational platform designed for children aged 3-12 years, offering interactive learning experiences across Math, Language, Science, and General Knowledge.',
        ),
      ],
    );
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Text(
            'Little Learners Academy is committed to protecting your privacy. We collect minimal data necessary for the app to function and never share personal information with third parties. All data is encrypted and stored securely.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Close',
              style: TextStyle(color: Color(0xFF6B73FF)),
            ),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Help & Support'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Need help? Contact us:'),
            SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.email, color: Color(0xFF6B73FF), size: 20),
                SizedBox(width: 8),
                Text('support@littlelearnersacademy.com'),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.web, color: Color(0xFF6B73FF), size: 20),
                SizedBox(width: 8),
                Text('www.littlelearnersacademy.com'),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Close',
              style: TextStyle(color: Color(0xFF6B73FF)),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(GameProvider gameProvider) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Confirm Logout',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Are you sure you want to logout? Your progress will be saved.',
        ),
        actions: [
          TextButton(
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.grey),
            ),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          TextButton(
            child: const Text(
              'Logout',
              style: TextStyle(color: Colors.red),
            ),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await gameProvider.logout(context);
    }
  }
}
