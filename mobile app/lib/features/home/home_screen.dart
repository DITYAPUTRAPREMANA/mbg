import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../history/history_screen.dart';
import '../profile/profile_screen.dart';
import '../scan/scan_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  static const List<IconData> _navIcons = [
    Icons.dashboard,
    Icons.camera_alt_outlined,
    Icons.history,
    Icons.person_outline,
  ];

  static const List<String> _navLabels = [
    'Dashboard',
    'Scan',
    'History',
    'Profile',
  ];

  void _onNavTap(int index) {
    if (index == 1) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ScanScreen()),
      );
      return;
    }

    if (index == 2) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const HistoryScreen()),
      );
      return;
    }

    if (index == 3) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ProfileScreen()),
      );
      return;
    }

    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FAF2),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.menu, color: Color(0xFF1F4F25)),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Dashboard',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF121E18),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.person, color: Color(0xFF1F4F25)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    Text(
                      'Featured Insight',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF121E18),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            height: 180,
                            decoration: BoxDecoration(
                              color: const Color(0xFF101010),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(28),
                                topRight: Radius.circular(28),
                              ),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.image,
                                size: 64,
                                color: Colors.white24,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF146620),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    'AI TRENDS',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  'How Generative AI is Personalizing the Future of Precision Nutrition',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF121E18),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'New breakthroughs in LLMs are allowing apps to create hyper-personalized nutrition guidance in real time.',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    color: const Color(0xFF66756A),
                                    height: 1.6,
                                  ),
                                ),
                                const SizedBox(height: 18),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.bolt,
                                      size: 18,
                                      color: Color(0xFF146620),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Vitality Labs • Oct 24, 2023',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        color: const Color(0xFF93A08F),
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
                    Text(
                      'Trending Now',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF121E18),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildSmallCard(
                      category: 'NUTRITION',
                      title: 'The Hidden Benefits of Fermented Foods on Brain',
                      subtitle: 'Journal of Health • 2h ago',
                    ),
                    const SizedBox(height: 12),
                    _buildSmallCard(
                      category: 'RECIPES',
                      title: 'Sourdough 2.0: Modern Science Behind the…',
                      subtitle: 'Culinary Weekly • 5h ago',
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'For You',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF121E18),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildSmallCard(
                      category: 'BIOHACKING',
                      title: 'Optimizing Circadian Rhythms Through Meal…',
                      subtitle: 'Vitality AI • 1d ago',
                    ),
                    const SizedBox(height: 12),
                    _buildSmallCard(
                      category: 'SUSTAINABILITY',
                      title:
                          'Vertical Farming: Why It’s Changing the Nutrients in…',
                      subtitle: 'Eco Tech • 3d ago',
                    ),
                    const SizedBox(height: 28),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFF146620),
                        borderRadius: BorderRadius.circular(28),
                      ),
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Get the Weekly Digest',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Curated research and nutrition news delivered every Sunday.',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.9),
                              height: 1.6,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.14),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'your@email.com',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Container(
                                height: 50,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: TextButton(
                                  onPressed: () {},
                                  child: Text(
                                    'Subscribe',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF146620),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 100),
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
          children: List.generate(_navIcons.length, (index) {
            final isSelected = index == _selectedIndex;
            return GestureDetector(
              onTap: () => _onNavTap(index),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _navIcons[index],
                    color: isSelected
                        ? const Color(0xFF146620)
                        : const Color(0xFF97A38F),
                    size: 24,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _navLabels[index],
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: isSelected
                          ? const Color(0xFF146620)
                          : const Color(0xFF97A38F),
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildSmallCard({
    required String category,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            category,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF2C6A35),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF121E18),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: const Color(0xFF7C8A7A),
            ),
          ),
        ],
      ),
    );
  }
}
