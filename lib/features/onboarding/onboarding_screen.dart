import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';

/// Onboarding screen - introduces the app and gets user consent.
class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingScreen({super.key, required this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _currentPage = 0;
  final PageController _pageController = PageController();

  final List<_OnboardingPage> _pages = [
    _OnboardingPage(
      icon: Icons.camera_alt_outlined,
      title: 'Point & Analyze',
      description: 'Point your camera at a belt-driven water pump. VocaViz will identify visible issues with the belt system.',
      color: AppColors.primary,
    ),
    _OnboardingPage(
      icon: Icons.visibility_outlined,
      title: 'See the Problem',
      description: 'Get visual overlays highlighting problem areas. Understand exactly what\'s wrong before you start repairs.',
      color: AppColors.warning,
    ),
    _OnboardingPage(
      icon: Icons.build_outlined,
      title: 'Follow Repair Steps',
      description: 'Step-by-step visual guidance helps you fix the issue safely. Clear instructions even for first-time repairs.',
      color: AppColors.success,
    ),
    _OnboardingPage(
      icon: Icons.offline_bolt_outlined,
      title: 'Works Offline',
      description: 'No internet? No problem. VocaViz works in low-connectivity environments where you need it most.',
      color: AppColors.info,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // App header
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Icon(
                    Icons.water_drop_outlined,
                    size: 64,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    AppConstants.appName,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    AppConstants.appTagline,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),

            // Page content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemBuilder: (context, index) => _buildPage(_pages[index]),
              ),
            ),

            // Page indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (index) => _buildIndicator(index),
              ),
            ),

            const SizedBox(height: 24),

            // Navigation buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentPage > 0)
                    TextButton(
                      onPressed: () => _pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      ),
                      child: const Text('Back'),
                    )
                  else
                    const SizedBox.shrink(),
                  ElevatedButton(
                    onPressed: _currentPage == _pages.length - 1
                        ? widget.onComplete
                        : () => _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                    child: Text(
                      _currentPage == _pages.length - 1 ? 'Get Started' : 'Next',
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(_OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: page.color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              page.icon,
              size: 60,
              color: page.color,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            page.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            page.description,
            style: const TextStyle(fontSize: 16, height: 1.5),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildIndicator(int index) {
    final isActive = index == _currentPage;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive ? AppColors.primary : Colors.grey[300],
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class _OnboardingPage {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  _OnboardingPage({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
}
