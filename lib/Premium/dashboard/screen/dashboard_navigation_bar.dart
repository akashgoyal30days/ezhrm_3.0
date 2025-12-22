import 'package:flutter/material.dart';

class DashboardNavigationBar extends StatelessWidget {
  final int currentIndex; // <-- Add this
  final Function(int) onTap; // <-- Add this

  const DashboardNavigationBar({
    super.key,
    required this.currentIndex, // <-- Required parameter
    required this.onTap, // <-- Required parameter
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(left: 0, right: 0, top: 5, bottom: 5),
      child: BottomNavigationBar(
        selectedItemColor: Color(0xFF268AE4),
        unselectedItemColor: Colors.grey,
        currentIndex: currentIndex,
        onTap: onTap,
        type: BottomNavigationBarType.fixed, // Keeps labels always visible
        showSelectedLabels: true, // Always show selected label
        showUnselectedLabels: true, // Always show unselected label
        elevation: 0, // Removes shadow
        iconSize: 24, // Standard icon size
        selectedFontSize: 12, // Selected label size
        unselectedFontSize: 12, // Unselected label size
        items: [
          BottomNavigationBarItem(
            icon: SizedBox(
              width: 42,
              height: 36, // Make same height as active state
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                      height:
                          4), // space above icon, to match line height below in activeIcon
                  Image.asset(
                    'assets/images/home_Vector.png',
                    width: 28,
                    height: 28,
                  ),
                ],
              ),
            ),
            activeIcon: SizedBox(
              width: 42,
              height: 36, // same total height as icon container
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    height: 2,
                    width: 42, // Wider to cover label text "Home"
                    color: Color(0xFF268AE4),
                  ),
                  SizedBox(height: 4), // small gap between line and icon
                  Image.asset(
                    'assets/images/home_Vector.png',
                    width: 28,
                    height: 28,
                    color: Color(0xFF268AE4),
                  ),
                ],
              ),
            ),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: SizedBox(
              width: 60, // slightly wider - accommodates long text underline
              height: 36, // SAME height as activeIcon
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                      height:
                          4), // reserves space for underline in active state
                  Image.asset(
                    'assets/images/bell_vector.png',
                    width: 28,
                    height: 28,
                  ),
                ],
              ),
            ),
            activeIcon: SizedBox(
              width: 60, // same width as icon
              height: 36, // same height to prevent shifting
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    height: 2,
                    // Make underline at least as wide as label text
                    width: 60,
                    color: Color(0xFF268AE4),
                  ),
                  SizedBox(height: 4),
                  Image.asset(
                    'assets/images/bell_vector.png',
                    width: 24,
                    height: 24,
                    color: Color(0xFF268AE4),
                  ),
                ],
              ),
            ),
            label: 'Notifications',
          ),
          BottomNavigationBarItem(
            icon: SizedBox(
              width: 42,
              height: 36,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: 4),
                  Image.asset(
                    'assets/images/profile_Vector.png',
                    width: 28,
                    height: 28,
                  ),
                ],
              ),
            ),
            activeIcon: SizedBox(
              width: 42,
              height: 36,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    height: 2,
                    width: 42,
                    color: Color(0xFF268AE4),
                  ),
                  SizedBox(height: 4),
                  Image.asset(
                    'assets/images/profile_Vector.png',
                    width: 28,
                    height: 28,
                    color: Color(0xFF268AE4),
                  ),
                ],
              ),
            ),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: SizedBox(
              width: 42,
              height: 36,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: 4),
                  Image.asset(
                    'assets/images/logout_Vector.png',
                    width: 28,
                    height: 28,
                  ),
                ],
              ),
            ),
            activeIcon: SizedBox(
              width: 42,
              height: 36,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    height: 2,
                    width: 42,
                    color: Color(0xFF268AE4),
                  ),
                  SizedBox(height: 4),
                  Image.asset(
                    'assets/images/logout_Vector.png',
                    width: 28,
                    height: 28,
                    color: Color(0xFF268AE4),
                  ),
                ],
              ),
            ),
            label: 'Logout',
          ),
        ],
      ),
    );
  }
}
