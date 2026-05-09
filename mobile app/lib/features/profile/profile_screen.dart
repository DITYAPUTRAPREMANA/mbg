import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../auth/login_screen.dart';
import '../home/home_screen.dart';
import '../history/history_screen.dart';
import '../scan/scan_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _fullName = 'Elena Richardson';
  String _email = 'elena.richardson@vitality.tech';
  int _selectedIndex = 3;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    setState(() {
      _email = user?.email ?? _email;
      final metadata = user?.userMetadata;
      _fullName = metadata != null && metadata['full_name'] != null
          ? metadata['full_name'] as String
          : _fullName;
    });
  }

  Future<void> _signOut() async {
    await Supabase.instance.client.auth.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _onNavTap(int index) {
    if (index == _selectedIndex) return;
    if (index == 0) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
      return;
    }
    if (index == 1) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ScanScreen()),
      );
      return;
    }
    if (index == 2) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HistoryScreen()));
      return;
    }
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFF8EE),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.arrow_back, color: Color(0xFF1F4F25)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Profile',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF172914),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.settings, color: Color(0xFF1F4F25)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 24,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
                      child: Column(
                        children: [
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 126,
                                height: 126,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDFF5E5),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFF146620),
                                    width: 3,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.08),
                                      blurRadius: 18,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Container(
                                    width: 102,
                                    height: 102,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF2C3F28),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.person,
                                      size: 52,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 6,
                                right: 24,
                                child: Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF146620),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                  child: const Icon(
                                    Icons.edit,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          Text(
                            _fullName,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF172914),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _email,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              color: const Color(0xFF61725D),
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 22),
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF4FAF2),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 18,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 46,
                                  height: 46,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDFF5E5),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Icon(
                                    Icons.restaurant_menu,
                                    color: Color(0xFF146620),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'MEALS LOGGED',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF146620),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      '412',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 36,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF172914),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Account'),
                    const SizedBox(height: 12),
                    _buildOptionsCard(
                      items: [
                        _OptionItem(
                          icon: Icons.person_outline,
                          title: 'Edit Profile',
                        ),
                        _OptionItem(
                          icon: Icons.notifications_none,
                          title: 'Notifications',
                        ),
                        _OptionItem(
                          icon: Icons.lock_outline,
                          title: 'Privacy & Security',
                        ),
                        _OptionItem(
                          icon: Icons.credit_card_outlined,
                          title: 'Subscriptions',
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Resources'),
                    const SizedBox(height: 12),
                    _buildOptionsCard(
                      items: [
                        _OptionItem(
                          icon: Icons.help_outline,
                          title: 'Help Center',
                        ),
                        _OptionItem(
                          icon: Icons.info_outline,
                          title: 'About Meal Based Nutrition Guide',
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFCE7E5),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextButton(
                        onPressed: _signOut,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.logout,
                              color: Color(0xFFB82A28),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Sign Out',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFB82A28),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildNavItem(Icons.dashboard, 'Dashboard', 0),
            _buildNavItem(Icons.camera_alt_outlined, 'Scan', 1),
            _buildNavItem(Icons.history, 'History', 2),
            _buildNavItem(Icons.person, 'Profile', 3),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF1F4F25),
      ),
    );
  }

  Widget _buildOptionsCard({required List<_OptionItem> items}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: items
            .map(
              (item) => Column(
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE9F4E8),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(item.icon, color: const Color(0xFF146620)),
                    ),
                    title: Text(
                      item.title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF172914),
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right, color: Color(0xFF97A38F)),
                    onTap: () {},
                  ),
                  if (item != items.last)
                    const Divider(height: 1, indent: 86, endIndent: 18, color: Color(0xFFE9F1EA)),
                ],
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = index == _selectedIndex;
    return GestureDetector(
      onTap: () => _onNavTap(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 24,
            color: isSelected ? const Color(0xFF146620) : const Color(0xFF97A38F),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? const Color(0xFF146620) : const Color(0xFF97A38F),
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionItem {
  final IconData icon;
  final String title;

  const _OptionItem({required this.icon, required this.title});
}
