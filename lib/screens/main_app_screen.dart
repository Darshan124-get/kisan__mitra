import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kisan_mitra/screens/plant_doctor_screen.dart';
import 'package:kisan_mitra/screens/market_rate_screen.dart';
import 'package:kisan_mitra/screens/weather_screen.dart';
import 'package:kisan_mitra/screens/nearby_resources_screen.dart';
import 'package:kisan_mitra/screens/profile_screen.dart';
import 'package:kisan_mitra/screens/settings_screen.dart';
import 'package:kisan_mitra/screens/laborer/laborer_dashboard_screen.dart';
import 'package:kisan_mitra/screens/laborer/my_services_screen.dart';
import 'package:kisan_mitra/screens/laborer/my_jobs_screen.dart';
import 'package:kisan_mitra/services/api_config.dart';
import 'package:kisan_mitra/screens/login_screen.dart';

class MainAppScreen extends StatefulWidget {
  const MainAppScreen({super.key});

  @override
  State<MainAppScreen> createState() => _MainAppScreenState();
}

class _MainAppScreenState extends State<MainAppScreen> {
  int _selectedIndex = 0;
  String? _userRole;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _checkAuthAndLoadRole();
  }

  Future<void> _checkAuthAndLoadRole() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    final token = await ApiConfig.getToken();
    
    // If isLoggedIn is true but no token exists, clear login state
    if (isLoggedIn && (token == null || token.isEmpty)) {
      print('⚠️ [MainAppScreen] isLoggedIn=true but no token found. Clearing login state.');
      await prefs.setBool('isLoggedIn', false);
      await prefs.remove('userRole');
      await prefs.remove('userEmail');
      await prefs.remove('userId');
      
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
        return;
      }
    }
    
    setState(() {
      _userRole = prefs.getString('userRole') ?? 'farmer';
    });
  }

  Future<void> _loadUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userRole = prefs.getString('userRole') ?? 'farmer';
    });
  }

  List<Widget> get _screens {
    if (_userRole == 'laborer') {
      // Laborer screens
      return [
        const LaborerDashboardScreen(),
        const MyServicesScreen(),
        const MyJobsScreen(),
        const ProfileScreen(),
      ];
    }
    // Farmer screens (existing)
    return [
      const PlantDoctorScreen(),
      const MarketRateScreen(),
      const WeatherHomePage(),
      const NearbyResourcesScreen(),
    ];
  }

  List<BottomNavigationBarItem> get _navItems {
    if (_userRole == 'laborer') {
      return const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.work),
          label: 'Find Work',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.list),
          label: 'My Jobs',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ];
    }
    // Existing farmer nav items
    return const [
      BottomNavigationBarItem(
        icon: Icon(Icons.medical_services_outlined),
        label: 'Plant Doctor',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.bar_chart_outlined),
        label: 'Market Rate',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.cloud_outlined),
        label: 'Weather',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.location_on_outlined),
        label: 'Nearby Help',
      ),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  bool _shouldShowAppBar() {
    // Show AppBar only for screens that don't have their own AppBar
    // PlantDoctorScreen, WeatherScreen, NearbyResourcesScreen have their own AppBars
    // Laborer screens (LaborerDashboardScreen, MyServicesScreen, MyJobsScreen) have their own Scaffolds with AppBars
    if (_userRole == 'laborer') {
      return false; // Laborer screens have their own AppBars, don't show MainAppScreen AppBar
    }
    // For farmer: only MarketRateScreen needs AppBar from MainAppScreen
    return _selectedIndex == 1; // Market Rate screen
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: _shouldShowAppBar() ? AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
        title: Text(
          _getAppBarTitle(),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.green,
        elevation: 0,
      ) : null,
      drawer: _buildDrawer(context),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: _navItems,
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.green[800],
        unselectedItemColor: Colors.black54,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed, // Ensures all labels are shown
      ),
    );
  }

  String _getAppBarTitle() {
    if (_userRole == 'laborer') {
      switch (_selectedIndex) {
        case 0:
          return 'Dashboard';
        case 1:
          return 'Find Work';
        case 2:
          return 'My Jobs';
        case 3:
          return 'Profile';
        default:
          return 'Kisan Mitra';
      }
    } else {
      switch (_selectedIndex) {
        case 0:
          return 'Plant Doctor';
        case 1:
          return 'Market Rate';
        case 2:
          return 'Weather';
        case 3:
          return 'Nearby Help';
        default:
          return 'Kisan Mitra';
      }
    }
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Colors.green,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.agriculture,
                    size: 40,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Kisan Mitra',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _userRole == 'laborer' ? 'Laborer' : 'Farmer',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          ExpansionTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            children: [
              ListTile(
                leading: const Icon(Icons.language),
                title: const Text('Language'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(initialSection: 'language'),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.notifications),
                title: const Text('Notifications'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(initialSection: 'notifications'),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.dark_mode),
                title: const Text('Theme'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(initialSection: 'theme'),
                    ),
                  );
                },
              ),
            ],
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profile'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfileScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.support),
            title: const Text('Support'),
            onTap: () {
              Navigator.pop(context);
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Support'),
                  content: const Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Contact us at:'),
                      SizedBox(height: 8),
                      Text('Email: support@kisanmitra.com'),
                      SizedBox(height: 8),
                      Text('Phone: +91 1800-XXX-XXXX'),
                      SizedBox(height: 16),
                      Text('Working Hours:'),
                      Text('Monday - Friday: 9:00 AM - 6:00 PM'),
                      Text('Saturday: 9:00 AM - 1:00 PM'),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.help),
            title: const Text('Help'),
            onTap: () {
              Navigator.pop(context);
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Help Center'),
                  content: const Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('How to use Kisan Mitra:'),
                      SizedBox(height: 8),
                      Text('1. Use Plant Doctor to diagnose plant diseases'),
                      Text('2. Check weather forecasts for your area'),
                      Text('3. View market rates for crops'),
                      Text('4. Find nearby labor and tractors'),
                      SizedBox(height: 16),
                      Text('For more help:'),
                      Text('• Visit our website: www.kisanmitra.com/help'),
                      Text('• Watch tutorial videos'),
                      Text('• Read our FAQ section'),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () async {
              Navigator.pop(context);
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),
    );
  }
} 