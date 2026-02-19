import 'package:flutter/material.dart';
import 'package:gamelog/screens/auth_screen.dart'; // <--- Correct import now
// REMOVED: import 'package:gamelog/widgets/welcome_dialog.dart'; // No longer needed
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

// A simple data class for our onboarding page content
class OnboardingPageData {
  final IconData icon;
  final String title;
  final String description;

  const OnboardingPageData({ // Added const
    required this.icon,
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

  final List<OnboardingPageData> _pages = const [ // Added const
    OnboardingPageData(
      icon: Icons.auto_stories_outlined,
      title: 'Welcome to GameLog!',
      description: 'Your personal space to track, manage, and conquer your video game collection.',
    ),
    OnboardingPageData(
      icon: Icons.sync_alt_outlined,
      title: 'Organize Your Library',
      description: 'Effortlessly move games between your Backlog, Now Playing, and Archive lists with a simple swipe.',
    ),
    OnboardingPageData(
      icon: Icons.insights_outlined,
      title: 'Never Forget a Game',
      description: "Keep your thoughts organized and your gaming journey on track. Let's get started!",
    ),
  ];

  Future<void> _onboardComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);

    if (mounted) {
      // Navigate directly to AuthScreen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AuthScreen()),
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
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _onboardComplete,
                  child: const Text('SKIP'),
                ),
              ),
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
                      icon: page.icon,
                      title: page.title,
                      description: page.description,
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              _buildBottomNavigation(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPage({required IconData icon, required String title, required String description}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 200, color: Theme.of(context).colorScheme.primary),
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
          SmoothPageIndicator(
            controller: _controller,
            count: _pages.length,
            effect: WormEffect(
              dotHeight: 10,
              dotWidth: 10,
              activeDotColor: Theme.of(context).colorScheme.primary,
            ),
          ),
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