import 'package:flutter/material.dart';
import 'package:gamelog/screens/main_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

// A simple data class for our onboarding page content
class OnboardingPageData {
  final String imagePath;
  final String title;
  final String description;

  OnboardingPageData({
    required this.imagePath,
    required this.title,
    required this.description,
  });
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  bool _isLastPage = false;

  // This is where you would put your custom illustrations!
  // For now, we use placeholders.
  final List<OnboardingPageData> _pages = [
    OnboardingPageData(
      imagePath: 'assets/images/icon.png', // You will need to create these images
      title: 'Welcome to GameLog!',
      description: 'Your personal space to track, manage, and conquer your video game collection.',
    ),
    OnboardingPageData(
      imagePath: 'assets/images/icon.png',
      title: 'Organize Your Library',
      description: 'Effortlessly move games between your Backlog, Now Playing, and Archive lists with a simple swipe.',
    ),
    OnboardingPageData(
      imagePath: 'assets/images/icon.png',
      title: 'Export and Import your Game library',
      description: "Export and import your game collection with a single tap. It's a breeze!",
    ),
    OnboardingPageData(
      imagePath: 'assets/images/icon.png',
      title: 'Never Forget a Game',
      description: "Keep your thoughts organized and your gaming journey on track. Let's get started!",
    ),
  ];

  // This function is called when the user finishes onboarding
  Future<void> _onboardComplete() async {
    final prefs = await SharedPreferences.getInstance();
    // Set the flag to true so this screen doesn't show again
    await prefs.setBool('hasSeenOnboarding', true);

    if (mounted) {
      // Use pushReplacement to prevent the user from going back to onboarding
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24.0),
          child: Column(
            children: [
              // --- SKIP BUTTON ---
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _onboardComplete,
                  child: const Text('SKIP'),
                ),
              ),
              // --- PAGE VIEW ---
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _pages.length,
                  onPageChanged: (index) {
                    setState(() {
                      _isLastPage = index == _pages.length - 1;
                    });
                  },
                  itemBuilder: (context, index) {
                    final page = _pages[index];
                    return _buildPage(
                      imagePath: page.imagePath,
                      title: page.title,
                      description: page.description,
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              // --- BOTTOM NAVIGATION ---
              _buildBottomNavigation(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPage({required String imagePath, required String title, required String description}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Replace with your actual image widget
          // For now, we use an icon as a placeholder
          Icon(Icons.image, size: 200, color: Colors.grey.shade700),
          const SizedBox(height: 48),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // --- PAGE INDICATOR ---
          SmoothPageIndicator(
            controller: _controller,
            count: _pages.length,
            effect: WormEffect(
              dotHeight: 10,
              dotWidth: 10,
              activeDotColor: Theme.of(context).colorScheme.primary,
            ),
          ),

          // --- NEXT / GET STARTED BUTTON ---
          FilledButton(
            onPressed: () {
              if (_isLastPage) {
                _onboardComplete();
              } else {
                _controller.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeIn,
                );
              }
            },
            child: Text(_isLastPage ? 'GET STARTED' : 'NEXT'),
          ),
        ],
      ),
    );
  }
}