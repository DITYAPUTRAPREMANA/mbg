import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../home/home_screen.dart';
import '../profile/profile_screen.dart';
import '../scan/scan_screen.dart';
import 'scan_history_repository.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late DateTime _selectedDate;
  late DateTime _currentWeekStart;
  int _selectedIndex = 2;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _currentWeekStart = _getWeekStart(_selectedDate);
  }

  DateTime _getWeekStart(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  String _getMonthYear(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  String _getDayName(DateTime date) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[date.weekday - 1];
  }

  void _previousWeek() {
    setState(() {
      _currentWeekStart = _currentWeekStart.subtract(const Duration(days: 7));
    });
  }

  void _nextWeek() {
    setState(() {
      _currentWeekStart = _currentWeekStart.add(const Duration(days: 7));
    });
  }

  void _selectDate(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
  }

  void _onNavTap(int index) {
    if (index == _selectedIndex) return;
    if (index == 0) {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
    } else if (index == 1) {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const ScanScreen()));
    } else if (index == 3) {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const ProfileScreen()));
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  String _getDateSection(DateTime mealDate) {
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));

    if (mealDate.year == today.year &&
        mealDate.month == today.month &&
        mealDate.day == today.day) {
      return 'TODAY';
    } else if (mealDate.year == yesterday.year &&
        mealDate.month == yesterday.month &&
        mealDate.day == yesterday.day) {
      return 'YESTERDAY';
    } else {
      const days = [
        'MONDAY',
        'TUESDAY',
        'WEDNESDAY',
        'THURSDAY',
        'FRIDAY',
        'SATURDAY',
        'SUNDAY',
      ];
      return days[mealDate.weekday - 1];
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<DateTime> weekDays = List.generate(
      7,
      (i) => _currentWeekStart.add(Duration(days: i)),
    );

    final monthYear = _getMonthYear(_currentWeekStart);

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: ScanHistoryRepository.instance.allResults,
      builder: (context, snapshot) {
        final scannedMeals = (snapshot.data ?? []).map((result) {
          // Parsing tanggal dari database
          final DateTime scannedAt = DateTime.parse(result['created_at']);
          final formattedTime = TimeOfDay.fromDateTime(
            scannedAt,
          ).format(context);

          return _MealItem(
            name:
                result['food_name'] ??
                'Menu Sehat', // Ambil dari Map, bukan properti .title
            time: formattedTime,
            calories: result['total_calories'] ?? 0,
            protein: result['protein'] ?? 0,
            carbs: result['carbs'] ?? 0,
            fat: result['fat'] ?? 0,
            date: scannedAt,
            icon: Icons.restaurant,
          );
        }).toList();

        // Mock meal data still shown when history is empty or to provide initial content.
        final sampleMeals = [
          _MealItem(
            name: 'Matcha & Oat Bowl',
            time: '8:45 AM',
            calories: 320,
            protein: 8,
            carbs: 48,
            fat: 9,
            date: DateTime.now(),
            icon: Icons.restaurant,
          ),
          _MealItem(
            name: 'Grilled Chicken & Veg',
            time: '7:30 PM',
            calories: 510,
            protein: 54,
            carbs: 15,
            fat: 14,
            date: DateTime.now().subtract(const Duration(days: 1)),
            icon: Icons.restaurant,
          ),
        ];

        final allMeals = [...scannedMeals, ...sampleMeals];

        // Group meals by section
        final mealsBySection = <String, List<_MealItem>>{};
        for (final meal in allMeals) {
          final section = _getDateSection(meal.date);
          mealsBySection.putIfAbsent(section, () => []).add(meal);
        }

        final sections = ['TODAY', 'YESTERDAY'];
        final orderedSections = sections
            .where((section) => mealsBySection.containsKey(section))
            .toList();

        return Scaffold(
          backgroundColor: const Color(0xFFF4FAF2),
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 18,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
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
                        'History',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF121E18),
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
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.person,
                          color: Color(0xFF1F4F25),
                        ),
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
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 18,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    monthYear,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF121E18),
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      GestureDetector(
                                        onTap: _previousWeek,
                                        child: const Icon(
                                          Icons.chevron_left,
                                          color: Color(0xFF146620),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      GestureDetector(
                                        onTap: _nextWeek,
                                        child: const Icon(
                                          Icons.chevron_right,
                                          color: Color(0xFF146620),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: List.generate(7, (index) {
                                  final date = weekDays[index];
                                  final isSelected =
                                      date.year == _selectedDate.year &&
                                      date.month == _selectedDate.month &&
                                      date.day == _selectedDate.day;
                                  final dayName = _getDayName(
                                    date,
                                  ).toUpperCase();
                                  final dayNum = date.day;

                                  return GestureDetector(
                                    onTap: () => _selectDate(date),
                                    child: Container(
                                      width: 48,
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? const Color(0xFF146620)
                                            : const Color(0xFFF4F9F1),
                                        borderRadius: BorderRadius.circular(16),
                                        border: !isSelected
                                            ? Border.all(
                                                color: const Color(0xFFE6EDE4),
                                                width: 1,
                                              )
                                            : null,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            dayName,
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: isSelected
                                                  ? Colors.white
                                                  : const Color(0xFF66756A),
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            dayNum.toString(),
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                              color: isSelected
                                                  ? Colors.white
                                                  : const Color(0xFF121E18),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        ...orderedSections.map((section) {
                          final sectionMeals = mealsBySection[section] ?? [];
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                section,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF66756A),
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ...sectionMeals.map((meal) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _buildMealCard(meal),
                                );
                              }),
                              const SizedBox(height: 24),
                            ],
                          );
                        }),
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
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Flexible(child: _buildNavItem(Icons.dashboard, 'Dashboard', 0)),
                Flexible(
                  child: _buildNavItem(Icons.camera_alt_outlined, 'Scan', 1),
                ),
                Flexible(child: _buildNavItem(Icons.history, 'History', 2)),
                Flexible(
                  child: _buildNavItem(Icons.person_outline, 'Profile', 3),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMealCard(_MealItem meal) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: const BoxDecoration(
              color: Color(0xFFDFF5E5),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                bottomLeft: Radius.circular(24),
              ),
            ),
            child: Icon(meal.icon, size: 48, color: const Color(0xFF146620)),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          meal.name,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF121E18),
                          ),
                        ),
                      ),
                      Text(
                        meal.time,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF66756A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${meal.calories} kcal',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF146620),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildMacroLabel(
                        'PROT',
                        '${meal.protein}g',
                        Colors.green,
                      ),
                      _buildMacroLabel(
                        'CARBS',
                        '${meal.carbs}g',
                        Colors.orange,
                      ),
                      _buildMacroLabel('FAT', '${meal.fat}g', Colors.orange),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroLabel(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF97A38F),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
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
            color: isSelected
                ? const Color(0xFF146620)
                : const Color(0xFF97A38F),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected
                  ? const Color(0xFF146620)
                  : const Color(0xFF97A38F),
            ),
          ),
        ],
      ),
    );
  }
}

class _MealItem {
  final String name;
  final String time;
  final num calories;
  final num protein;
  final num carbs;
  final num fat;
  final DateTime date;
  final IconData icon;

  _MealItem({
    required this.name,
    required this.time,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.date,
    required this.icon,
  });
}
