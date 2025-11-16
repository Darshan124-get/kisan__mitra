import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // Import for ImagePicker
import 'dart:io'; // Import for File class
import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Placeholder data for user information
  String _userName = 'User Name';
  String _userEmail = 'user.email@example.com';
  String _userAddress = 'User Address';
  String? _profileImagePath; // Use imagePath instead of imageUrl for local files
  bool _isLocationAccessEnabled = false;

  // Controllers for text fields
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  // Image picker instance
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('userName') ?? 'User Name';
      _userEmail = prefs.getString('userEmail') ?? 'user.email@example.com';
      _userAddress = prefs.getString('userAddress') ?? 'User Address';
      _profileImagePath = prefs.getString('profileImagePath');
      _isLocationAccessEnabled = prefs.getBool('locationAccess') ?? false;
      
      _nameController.text = _userName;
      _addressController.text = _userAddress;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  // Function to handle profile image update
  void _updateProfileImage() {
    showDialog( // Show dialog to choose source
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Choose Image Source'),
          actions: <Widget>[
            TextButton.icon(
              icon: const Icon(Icons.camera_alt),
              label: const Text('Camera'),
              onPressed: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.camera); // Call image picking with camera source
              },
            ),
            TextButton.icon(
              icon: const Icon(Icons.photo_library),
              label: const Text('Gallery'),
              onPressed: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.gallery); // Call image picking with gallery source
              },
            ),
          ],
        );
      },
    );
  }

  // Function to pick image from source
  Future<void> _pickImage(ImageSource source) async {
    // TODO: Implement permission request similar to PlantDoctorScreen
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 500, // Adjust max width as needed
      );

      if (image != null) {
        setState(() {
          _profileImagePath = image.path;
        });
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('profileImagePath', image.path);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  // Function to save profile changes (placeholder)
  Future<void> _saveProfileChanges() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userName', _nameController.text);
    await prefs.setString('userAddress', _addressController.text);
    
    setState(() {
      _userName = _nameController.text;
      _userAddress = _addressController.text;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile saved successfully')),
    );
  }

  // Function to toggle location access (placeholder)
  Future<void> _toggleLocationAccess(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('locationAccess', value);
    
    setState(() {
      _isLocationAccessEnabled = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Profile'),
        backgroundColor: Colors.green,
        elevation: 0,
        // Remove back button completely
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _saveProfileChanges,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: _updateProfileImage,
              child: CircleAvatar(
                radius: 60,
                backgroundColor: Colors.green[200],
                backgroundImage: _profileImagePath != null ? FileImage(File(_profileImagePath!)) : null, // Use FileImage for local file
                child: _profileImagePath == null
                    ? Icon(
                        Icons.person,
                        size: 70,
                        color: Colors.green[800],
                      )
                    : null,
              ),
            ),
            SizedBox(height: 16),
            Text(
              _userEmail, // Display email (typically not editable directly)
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
            SizedBox(height: 24),

            Card(
              elevation: 2.0,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Basic Information',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Name',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: _addressController,
                      decoration: InputDecoration(
                        labelText: 'Address',
                        prefixIcon: Icon(Icons.location_on_outlined),
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 24),

            Card(
              elevation: 2.0,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Permissions',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    SizedBox(height: 8),
                    ListTile(
                      title: Text('Live Location Access'),
                      trailing: Switch(value: _isLocationAccessEnabled, onChanged: _toggleLocationAccess),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 24),

            Card(
              elevation: 2.0,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Planning and Resources',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    SizedBox(height: 16),
                    ListTile(
                      leading: Icon(Icons.event_note), // Placeholder icon
                      title: Text('Scheduled Planning Reports'),
                      trailing: Icon(Icons.arrow_forward_ios),
                      onTap: () { /* TODO: Navigate to reports screen */ },
                      contentPadding: EdgeInsets.zero,
                    ),
                    ListTile(
                       leading: Icon(Icons.agriculture), // Placeholder icon
                      title: Text('Book Labor/Equipment/Tractor'),
                       trailing: Icon(Icons.arrow_forward_ios),
                      onTap: () { /* TODO: Navigate to booking screen */ },
                       contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 24),

            Card(
              elevation: 2.0,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'History',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    SizedBox(height: 8),
                    // TODO: Add ListView.builder or similar to display history items
                    ListTile(title: Text('History Item 1')), // Placeholder
                    ListTile(title: Text('History Item 2')), // Placeholder
                  ],
                ),
              ),
            ),

            SizedBox(height: 24),

            Card(
              elevation: 2.0,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Crop Growing Expenses',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    SizedBox(height: 8),
                    // TODO: Add ListView.builder or similar to display expense items with dates
                    ListTile(title: Text('2023-10-26: Seeds - \$50')), // Placeholder
                    ListTile(title: Text('2023-10-25: Fertilizer - \$30')), // Placeholder
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 