import 'package:community/screens/activity_feed_screen.dart';
import 'package:community/screens/home_screen.dart';
import 'package:community/screens/profile_screen.dart';
import 'package:community/screens/create_event_screen.dart';
import 'package:community/screens/organizer_dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  void _onItemTapped(int index, int totalItems) {
    // Ensure the index is valid before setting the state.
    if (index < totalItems) {
      setState(() {
        _selectedIndex = index;
      });
    } else {
      // If the index is out of bounds (e.g., after role change), reset to home.
      setState(() => _selectedIndex = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _getUserRole(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        final isOrganizer = snapshot.data == 'organizer';
        final widgetOptions = _buildWidgetOptions(isOrganizer);
        final bottomNavItems = _buildBottomNavBarItems(isOrganizer);

        // If the current index is out of bounds, reset it.
        if (_selectedIndex >= widgetOptions.length) {
          _selectedIndex = 0;
        }

        return Scaffold(
          body: IndexedStack(
            index: _selectedIndex,
            children: widgetOptions,
          ),
          bottomNavigationBar: BottomNavigationBar(
            items: bottomNavItems,
            currentIndex: _selectedIndex,
            onTap: (index) => _onItemTapped(index, bottomNavItems.length),
            type: BottomNavigationBarType.fixed,
            selectedItemColor: const Color(0xFF6C5CE7),
            unselectedItemColor: Colors.grey.shade600,
            showUnselectedLabels: false,
            showSelectedLabels: false,
            backgroundColor: Colors.white,
            elevation: 5.0,
          ),
        );
      },
    );
  }

  Future<String?> _getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_role');
  }

  List<Widget> _buildWidgetOptions(bool isOrganizer) {
    return [
      const HomeScreen(),
      const ActivityFeedScreen(),
      if (isOrganizer) const CreateEventScreen(), // The "plus" button screen
      // The last tab is either the Dashboard or Profile
      isOrganizer ? const OrganizerDashboardScreen() : const ProfileScreen(),
    ];
  }

  List<BottomNavigationBarItem> _buildBottomNavBarItems(bool isOrganizer) {
    return [
      const BottomNavigationBarItem(
        icon: Icon(Icons.home_outlined),
        activeIcon: Icon(Icons.home),
        label: 'Home',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.dynamic_feed_outlined),
        activeIcon: Icon(Icons.dynamic_feed),
        label: 'Feed',
      ),
      if (isOrganizer)
        const BottomNavigationBarItem(
          icon: Icon(Icons.add_circle_outline, size: 32),
          activeIcon: Icon(Icons.add_circle, size: 32),
          label: 'Create',
        ),
      BottomNavigationBarItem(
        icon: const Icon(Icons.person_outline),
        activeIcon: const Icon(Icons.person),
        label: isOrganizer ? 'Dashboard' : 'Profile',
      ),
    ];
  }
}
