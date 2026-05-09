import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../auth/login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FBF2),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                children: const [
                  _WelcomePage(),
                  _AnalysisPage(),
                  _TrackingPage(),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _PageIndicator(currentPage: _currentPage, pageCount: 3),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 28),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _currentPage == 0
                      ? const SizedBox.shrink()
                      : TextButton(
                          onPressed: () {
                            if (_currentPage > 0) {
                              _pageController.previousPage(
                                duration: const Duration(milliseconds: 400),
                                curve: Curves.easeOut,
                              );
                            }
                          },
                          child: Text(
                            'Back',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              color: const Color(0xFF4E5D51),
                            ),
                          ),
                        ),
                  ElevatedButton(
                    onPressed: () {
                      if (_currentPage < 2) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 450),
                          curve: Curves.easeOut,
                        );
                      } else {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F9464),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 16,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _currentPage < 2 ? 'Next' : 'Get Started',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.chevron_right,
                          color: Colors.white,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PageIndicator extends StatelessWidget {
  final int currentPage;
  final int pageCount;

  const _PageIndicator({required this.currentPage, required this.pageCount});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        pageCount,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 5),
          width: currentPage == index ? 28 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: currentPage == index
                ? const Color(0xFF1F8E5A)
                : const Color(0xFFD9E3D4),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}

class _WelcomePage extends StatelessWidget {
  const _WelcomePage();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 16),
          const _WelcomeHeroCard(),
          const SizedBox(height: 32),
          Text(
            'Welcome to MBG',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF142E19),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Experience the future of health with high-precision AI nutrition tracking and personalized metabolic insights.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              color: const Color(0xFF5D6A5C),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _InfoTile(
                svgPath: 'assets/icons/scan.svg',
                iconColor: Color(0xFF2E6FED),
                label: 'Instant Scan',
                description: 'Log meals in seconds with computer vision.',
              ),
              SizedBox(width: 14),
              _InfoTile(
                svgPath: 'assets/icons/insight.svg',
                iconColor: Color(0xFFF17D1F),
                label: 'Bio-Insights',
                description: 'Data-driven guidance for your goals.',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WelcomeHeroCard extends StatelessWidget {
  const _WelcomeHeroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 30,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            children: [
              Container(
                height: 220,
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F8F1),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      top: 20,
                      right: 20,
                      child: Row(
                        children: [
                          _IndicatorDot(color: const Color(0xFF4AB15E)),
                          const SizedBox(width: 6),
                          _IndicatorDot(color: const Color(0xFF2E6FED)),
                          const SizedBox(width: 6),
                          _IndicatorDot(color: const Color(0xFFF6BA33)),
                        ],
                      ),
                    ),
                    Center(
                      child: Container(
                        height: 150,
                        width: 150,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0F9464).withOpacity(0.16),
                              blurRadius: 22,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Center(
                          child: SvgPicture.asset(
                            'assets/icons/Scan.svg',
                            width: 56,
                            height: 56,
                            colorFilter: const ColorFilter.mode(
                              Color(0xFF0F9464),
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),
            ],
          ),
          Positioned(
            bottom: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F9464),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.flash_on,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Precision AI',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF183E28),
                        ),
                      ),
                      Text(
                        '99.8% Accuracy',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: const Color(0xFF5B6C60),
                        ),
                      ),
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
}

class _IndicatorDot extends StatelessWidget {
  final Color color;

  const _IndicatorDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _FeatureMiniCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _FeatureMiniCard({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFE7F6EE),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: const Color(0xFF1B9465), size: 18),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF243B2E),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: const Color(0xFF6B746B),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnalysisPage extends StatelessWidget {
  const _AnalysisPage();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          Expanded(
            child: Center(
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 360),
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2F7E63), Color(0xFF1B5540)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.16),
                      blurRadius: 24,
                      offset: const Offset(0, 16),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    const Positioned.fill(
                      child: Opacity(
                        opacity: 0.08,
                        child: _BowlBackgroundPattern(),
                      ),
                    ),
                    Center(
                      child: Container(
                        width: 320,
                        height: 320,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.12),
                              blurRadius: 24,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(32),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.asset(
                                'assets/images/Scanning.png',
                                fit: BoxFit.cover,
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withOpacity(0.2),
                                    ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 16,
                                left: 16,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.9),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    'Avocado',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF1F6E52),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 60,
                                right: 16,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.9),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    'Salmon',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF1F6E52),
                                    ),
                                  ),
                                ),
                              ),
                              // Positioned(
                              //   left: 24,
                              //   right: 24,
                              //   bottom: 16,
                              //   child: Container(
                              //     padding: const EdgeInsets.symmetric(
                              //       horizontal: 16,
                              //       vertical: 12,
                              //     ),
                              //     decoration: BoxDecoration(
                              //       color: Colors.white.withOpacity(0.95),
                              //       borderRadius: BorderRadius.circular(22),
                              //     ),
                              //     child: Center(
                              //       child: Text(
                              //         'Analyzing...',
                              //         style: GoogleFonts.plusJakartaSans(
                              //           fontSize: 14,
                              //           fontWeight: FontWeight.w600,
                              //           color: const Color(0xFF2D5943),
                              //         ),
                              //       ),
                              //     ),
                              //   ),
                              // ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Instant Nutritional Analysis',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 30,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF152C1F),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Know what you eat in seconds. Point your camera at any meal to unlock detailed macro and micro nutrient profiles.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              color: const Color(0xFF5D6A5C),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _BowlBackgroundPattern extends StatelessWidget {
  const _BowlBackgroundPattern();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _BowlPatternPainter());
  }
}

class _BowlPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final center = Offset(size.width * 0.5, size.height * 0.5);
    final radius = size.width * 0.35;

    for (var i = 0; i < 4; i++) {
      canvas.drawCircle(center, radius - (i * 20), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CornerLabel extends StatelessWidget {
  final String label;

  const _CornerLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF1F6E52),
        ),
      ),
    );
  }
}

class _TrackingPage extends StatelessWidget {
  const _TrackingPage();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Daily Calories',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              color: const Color(0xFF7C8A7A),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '1,840 / 2,200 kcal',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF111F15),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF0F9464).withOpacity(0.2),
                          width: 8,
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          '84%',
                          style: TextStyle(
                            color: Color(0xFF0F9464),
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _NutritionBar(
                  label: 'Protein',
                  value: 0.88,
                  progressColor: const Color(0xFF0F9464),
                  text: '142g / 160g',
                ),
                const SizedBox(height: 16),
                _NutritionBar(
                  label: 'Fats',
                  value: 0.83,
                  progressColor: const Color(0xFFF29537),
                  text: '58g / 70g',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 18,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recent Meal History',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF445344),
                  ),
                ),
                const SizedBox(height: 18),
                _MealRow(
                  label: 'Grilled Chicken Salad',
                  note: 'Lunch • 420 kcal',
                  imagePath: 'assets/images/chicken.png',
                ),
                const Divider(
                  height: 32,
                  thickness: 1,
                  color: Color(0xFFF0F3EE),
                ),
                _MealRow(
                  label: 'Berry Oatmeal Bowl',
                  note: 'Breakfast • 310 kcal',
                  imagePath: 'assets/images/oatmeal.png',
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Track Your Nutrition',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 30,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF132115),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Reach your goals faster with detailed nutritional insights and automated logging.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              color: const Color(0xFF5D6A5C),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _MealRow extends StatelessWidget {
  final String label;
  final String note;
  final String imagePath;

  const _MealRow({
    required this.label,
    required this.note,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: const Color(0xFFE6F2E9),
            borderRadius: BorderRadius.circular(16),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(imagePath, fit: BoxFit.cover),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF212F25),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                note,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: const Color(0xFF6A746D),
                ),
              ),
            ],
          ),
        ),
        const Icon(Icons.chevron_right, color: Color(0xFF9AA69A), size: 18),
      ],
    );
  }
}

class _NutritionBar extends StatelessWidget {
  final String label;
  final double value;
  final Color progressColor;
  final String text;

  const _NutritionBar({
    required this.label,
    required this.value,
    required this.progressColor,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
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
                color: const Color(0xFF283A2F),
              ),
            ),
            Text(
              text,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: const Color(0xFF6A746D),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 12,
            color: const Color(0xFFE7F1EA),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: value,
              child: Container(
                decoration: BoxDecoration(
                  color: progressColor,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String svgPath;
  final Color iconColor;
  final String label;
  final String description;

  const _InfoTile({
    required this.svgPath,
    required this.iconColor,
    required this.label,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F8F2),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: SvgPicture.asset(
                svgPath,
                width: 18,
                height: 18,
                colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1F3329),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: const Color(0xFF5F6E63),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
