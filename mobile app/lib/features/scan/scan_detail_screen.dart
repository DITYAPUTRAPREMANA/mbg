import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../history/history_screen.dart';
import '../home/home_screen.dart';
import '../profile/profile_screen.dart';
import 'scan_models.dart';

class ScanDetailScreen extends StatelessWidget {
  final ScanResult result;

  const ScanDetailScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FAF2),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
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
                    'Scan Result',
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
                    child: const CircleAvatar(
                      radius: 20,
                      backgroundColor: Color(0xFF146620),
                      child: Icon(Icons.person, color: Colors.white),
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
                    _buildImageCard(context),
                    const SizedBox(height: 24),
                    _buildDetectedIngredients(),
                    const SizedBox(height: 20),
                    _buildTotalCaloriesCard(),
                    const SizedBox(height: 20),
                    _buildMacroRow(),
                    const SizedBox(height: 20),
                    _buildBreakdownCard(),
                    const SizedBox(height: 20),
                    _buildInsightCard(),
                    _buildSourceInfo(),
                    const SizedBox(height: 24),
                    _buildActionButtons(context),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildImageCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 30,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            child: SizedBox(
              height: 260,
              width: double.infinity,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: result.imagePath.isEmpty
                        ? Image.asset(
                            'assets/images/scanning.png',
                            fit: BoxFit.cover,
                          )
                        : Image.file(File(result.imagePath), fit: BoxFit.cover),
                  ),
                  if (result.ingredients.isNotEmpty)
                    _buildBoundingLabel(
                      title: result.ingredients[0].name,
                      subtitle:
                          '${result.ingredients[0].matchPercentage}% Match',
                      top: 20,
                      left: 20,
                    ),
                  if (result.ingredients.length > 1)
                    _buildBoundingLabel(
                      title: result.ingredients[1].name,
                      subtitle:
                          '${result.ingredients[1].matchPercentage}% Match',
                      top: 72,
                      right: 20,
                    ),
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.auto_awesome,
                            color: Color(0xFF146620),
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBoundingLabel({
    required String title,
    required String subtitle,
    double? top,
    double? left,
    double? right,
  }) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF4AB8FF),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Text(
          '$title ($subtitle)',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildDetectedIngredients() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Detected Ingredients',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF121E18),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${result.ingredients.length} Items',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF97A38F),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ...result.ingredients.map(
            (ingredient) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildIngredientRow(ingredient),
            ),
          ),
          _buildAddIngredientButton(),
        ],
      ),
    );
  }

  Widget _buildIngredientRow(ScanIngredient ingredient) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7F2),
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F4E8),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.spa, color: Color(0xFF146620)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ingredient.name,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF121E18),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${ingredient.calories} kcal per 100g',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF66756A),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 72,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE6EDE4)),
            ),
            alignment: Alignment.center,
            child: Text(
              '${ingredient.matchPercentage}%',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF121E18),
              ),
            ),
          ),
          const SizedBox(width: 10),
          const Icon(Icons.close, color: Color(0xFF97A38F)),
        ],
      ),
    );
  }

  Widget _buildAddIngredientButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDDE8DD)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.add, color: Color(0xFF146620)),
          const SizedBox(width: 8),
          Text(
            'ADD INGREDIENT',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF146620),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalCaloriesCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF146620),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TOTAL CALORIES',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withOpacity(0.8),
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '${result.totalCalories}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 46,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'kcal consumed',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.85),
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.bolt, color: Colors.white, size: 40),
        ],
      ),
    );
  }

  Widget _buildMacroRow() {
    return Row(
      children: [
        Expanded(
          child: _buildMacroCard(
            'PROTEIN',
            '${result.totalProtein}g',
            0.45,
            const Color(0xFF2D7A2E),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _buildMacroCard(
            'CARBS',
            '${result.totalCarbs}g',
            0.28,
            const Color(0xFF146620),
          ),
        ),
      ],
    );
  }

  Widget _buildMacroCard(
    String label,
    String value,
    double progress,
    Color color,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF97A38F),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF121E18),
            ),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: LinearProgressIndicator(
              value: progress,
              color: color,
              backgroundColor: const Color(0xFFE4F3E9),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownCard() {
    return Container(
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
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nutritional Breakdown',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF121E18),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Micronutrients & Daily Values',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF97A38F),
            ),
          ),
          const SizedBox(height: 18),
          ...{
            'Fiber (g)': result.totalFiber.toInt(),
            'Protein (g)': result.totalProtein.toInt(),
            'Carbs (g)': result.totalCarbs.toInt(),
            'Fat (g)': result.totalFat.toInt(),
          }.entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: _buildNutrientRow(entry.key, entry.value),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutrientRow(String label, int value) {
    // If the value is for Sodium, we don't treat it as a % for the progress bar
    final isMg = label.contains('mg');
    final progress = isMg
        ? (value / 2300).clamp(0.0, 1.0)
        : (value / 50).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF121E18),
              ),
            ),
            Text(
              value.toString(),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF121E18),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: LinearProgressIndicator(
            value: progress,
            color: const Color(0xFF4AB8FF),
            backgroundColor: const Color(0xFFF1F5FB),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildSourceInfo() {
    return Padding(
      padding: const EdgeInsets.only(top: 16, left: 4),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 14, color: Color(0xFF97A38F)),
          const SizedBox(width: 6),
          Text(
            'Source: MBG AI Model Analysis',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF97A38F),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard() {
    return Container(
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F7E7),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.lightbulb, color: Color(0xFF146620)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nutritional Insight',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF121E18),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Analisis AI mendeteksi komposisi nutrisi berdasarkan bahan makanan yang terlihat pada foto.",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF66756A),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const HistoryScreen()),
              );
            },
            child: Container(
              height: 58,
              decoration: BoxDecoration(
                color: const Color(0xFF146620),
                borderRadius: BorderRadius.circular(18),
              ),
              alignment: Alignment.center,
              child: Text(
                'LOG THIS MEAL',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: GestureDetector(
            onTap: () {},
            child: Container(
              height: 58,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFF146620), width: 1.3),
              ),
              alignment: Alignment.center,
              child: Text(
                'ADJUST DETAILS',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF146620),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
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
          Flexible(
            child: _buildNavItem(
              context,
              Icons.dashboard,
              'Dashboard',
              const HomeScreen(),
            ),
          ),
          Flexible(
            child: _buildNavItem(
              context,
              Icons.camera_alt_outlined,
              'Scan',
              null,
            ),
          ),
          Flexible(
            child: _buildNavItem(
              context,
              Icons.history,
              'History',
              const HistoryScreen(),
            ),
          ),
          Flexible(
            child: _buildNavItem(
              context,
              Icons.person_outline,
              'Profile',
              const ProfileScreen(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    IconData icon,
    String label,
    Widget? destination,
  ) {
    final isSelected = label == 'Scan';
    return GestureDetector(
      onTap: destination == null
          ? null
          : () => Navigator.of(
              context,
            ).pushReplacement(MaterialPageRoute(builder: (_) => destination)),
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
