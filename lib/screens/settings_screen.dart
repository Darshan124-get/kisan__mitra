import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  final String? initialSection;
  
  const SettingsScreen({super.key, this.initialSection});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedLanguage = 'English';
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;

  final List<Map<String, String>> _languages = [
    {'name': 'English', 'code': 'en'},
    {'name': 'हिन्दी (Hindi)', 'code': 'hi'},
    {'name': 'मराठी (Marathi)', 'code': 'mr'},
    {'name': 'தமிழ் (Tamil)', 'code': 'ta'},
    {'name': 'తెలుగు (Telugu)', 'code': 'te'},
    {'name': 'ગુજરાતી (Gujarati)', 'code': 'gu'},
    {'name': 'ਪੰਜਾਬੀ (Punjabi)', 'code': 'pa'},
    {'name': 'ಕನ್ನಡ (Kannada)', 'code': 'kn'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadSavedSettings();
    
    // Set initial tab based on the section
    if (widget.initialSection != null) {
      switch (widget.initialSection) {
        case 'language':
          _tabController.animateTo(0);
          break;
        case 'notifications':
          _tabController.animateTo(1);
          break;
        case 'theme':
          _tabController.animateTo(2);
          break;
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedLanguage = prefs.getString('selected_language') ?? 'English';
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _darkModeEnabled = prefs.getBool('dark_mode_enabled') ?? false;
    });
  }

  Future<void> _changeLanguage(String language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_language', language);
    
    setState(() {
      _selectedLanguage = language;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Language changed to $language. Please restart the app for changes to take effect.'),
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'Restart',
            onPressed: () {
              // TODO: Implement app restart logic
            },
          ),
        ),
      );
    }
  }

  Future<void> _handleLogout() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: const Text('Logout'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', false);
      
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/login',
          (Route<dynamic> route) => false,
        );
      }
    }
  }

  Future<void> _toggleNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', value);
    setState(() {
      _notificationsEnabled = value;
    });
  }

  Future<void> _toggleDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode_enabled', value);
    setState(() {
      _darkModeEnabled = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.green,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.language),
              text: 'Language',
            ),
            Tab(
              icon: Icon(Icons.notifications),
              text: 'Notifications',
            ),
            Tab(
              icon: Icon(Icons.dark_mode),
              text: 'Theme',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLanguageSettings(),
          _buildNotificationSettings(),
          _buildThemeSettings(),
        ],
      ),
    );
  }

  Widget _buildLanguageSettings() {
    return ListView.builder(
      itemCount: _languages.length,
      itemBuilder: (context, index) {
        final language = _languages[index];
        final isSelected = language['name'] == _selectedLanguage;
        return ListTile(
          title: Text(
            language['name']!,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          trailing: isSelected
              ? const Icon(Icons.check_circle, color: Colors.green)
              : const Icon(Icons.circle_outlined, color: Colors.grey),
          onTap: () => _changeLanguage(language['name']!),
          selected: isSelected,
          selectedTileColor: Colors.green.withOpacity(0.1),
        );
      },
    );
  }

  Widget _buildNotificationSettings() {
    return ListView(
      children: [
        SwitchListTile(
          title: const Text('Enable Notifications'),
          subtitle: const Text('Receive updates about your crops and market prices'),
          value: _notificationsEnabled,
          onChanged: _toggleNotifications,
          activeColor: Colors.green,
        ),
        const Divider(),
        ListTile(
          title: const Text('Notification Sound'),
          subtitle: const Text('Play sound for notifications'),
          trailing: Switch(
            value: _notificationsEnabled,
            onChanged: _toggleNotifications,
            activeColor: Colors.green,
          ),
        ),
        const Divider(),
        ListTile(
          title: const Text('Vibration'),
          subtitle: const Text('Vibrate on notifications'),
          trailing: Switch(
            value: _notificationsEnabled,
            onChanged: _toggleNotifications,
            activeColor: Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildThemeSettings() {
    return ListView(
      children: [
        SwitchListTile(
          title: const Text('Dark Mode'),
          subtitle: const Text('Switch between light and dark theme'),
          value: _darkModeEnabled,
          onChanged: _toggleDarkMode,
          activeColor: Colors.green,
        ),
        const Divider(),
        ListTile(
          title: const Text('System Theme'),
          subtitle: const Text('Follow system theme settings'),
          trailing: Switch(
            value: !_darkModeEnabled,
            onChanged: (value) => _toggleDarkMode(!value),
            activeColor: Colors.green,
          ),
        ),
        const Divider(),
        ListTile(
          title: const Text('Accent Color'),
          subtitle: const Text('Choose your preferred accent color'),
          trailing: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey),
            ),
          ),
          onTap: () {
            // TODO: Implement accent color picker
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Accent color picker coming soon!')),
            );
          },
        ),
      ],
    );
  }
} 