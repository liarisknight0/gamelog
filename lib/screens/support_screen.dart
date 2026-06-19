import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class RoadmapItem {
  final String title;
  final String description;
  final bool isCompleted;
  RoadmapItem(this.title, this.description, this.isCompleted);
}

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final TextEditingController _suggestionController = TextEditingController();

  // --- THE ROADMAP DATA ---
  final List<RoadmapItem> roadmap = [
    RoadmapItem("v1.0 Launch", "Core game tracking with offline local storage.", true),
    RoadmapItem("API Integration", "Automated game search, metadata, and cover art.", true),
    RoadmapItem("Sorting & Filtering", "Advanced sorting and filters for faster navigation.", true),
    RoadmapItem("Import / Export Data", "Export and back up your library in supported formats.", true),
    RoadmapItem("Stats Dashboard", "Visual insights into playtime, completion, and habits.", false),
    RoadmapItem("Social Features", "Share your backlog and progress with friends.", false),
    RoadmapItem("HLTB Integration", "Show estimated main and completionist playtime on game details.", false),
    RoadmapItem("Random Game Selector", "Pick a random backlog game to fight choice paralysis.", false),
    RoadmapItem("Shimmer Loading States", "Skeleton loaders for smoother, premium loading experience.", false),
    RoadmapItem("Custom Filter Tags", "Quick filter chips for platform, genre, and custom tags.", false),
    RoadmapItem("Custom Accent Colors", "User-selected accent colors for a personalized theme.", false),
    RoadmapItem("Shareable Collection Cards", "Generate shareable images of completed games.", false),
    RoadmapItem("Platform Icons", "Replace text chips with official platform icons.", false),
    RoadmapItem("AMOLED Black Theme", "True black theme optimized for OLED displays.", false),
    RoadmapItem("Release Countdown", "Countdown timers and launch-day notifications for upcoming games.", false),
    RoadmapItem("Gaming Journal", "Private notes for thoughts, tips, and personal memories.", false),
    RoadmapItem("Home Screen Widget", "Widget showing the currently played game.", false),
    RoadmapItem("Multi-Playthrough Support", "Track multiple playthroughs per game.", false),
    RoadmapItem("Digital vs Physical Library", "Mark and filter games as physical or digital.", false),
    RoadmapItem("Collection Worth Tracking", "Track price paid and total library value.", false),
    RoadmapItem("Finished Date Timeline", "Timeline view of games completed over the years.", false),
  ];

  @override
  void dispose() {
    _suggestionController.dispose();
    super.dispose();
  }

  /// Opens the user's email app with the suggestion pre-filled.
  Future<void> _sendSuggestion() async {
    final String text = _suggestionController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please type a suggestion first!")),
      );
      return;
    }

    const String myEmail = "liarisknight@gmail.com";
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: myEmail,
      query: 'subject=GameLog Feature Suggestion&body=$text',
    );

    try {
      if (await canLaunchUrl(emailLaunchUri)) {
        await launchUrl(emailLaunchUri);
        _suggestionController.clear();
      } else {
        throw 'Could not launch';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not open email app.")),
        );
      }
    }
  }

  /// Opens the "Buy Me a Coffee" link in an external browser.
  Future<void> _launchBuyMeACoffee() async {
    // TODO: Replace this with your actual Buy Me a Coffee link
    const String url = "https://buymeacoffee.com/liarisknight";

    final Uri uri = Uri.parse(url);

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not open support link.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Support & Feature Drop')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // --- ROADMAP SECTION ---
          Text(
            "Feature Roadmap",
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text("Here is what we are building next for GameLog."),
          const SizedBox(height: 24),

          ...roadmap.map((item) => _buildTimelineItem(context, item)),

          const Divider(height: 40),

          // --- SUGGESTION SECTION ---
          Text(
            "Suggest a Feature",
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text("Have an idea to make GameLog better? Tell us about it!"),
          const SizedBox(height: 16),

          TextField(
            controller: _suggestionController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: "I want to see...",
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: _sendSuggestion,
              icon: const Icon(Icons.send_rounded, size: 18),
              label: const Text("Submit Suggestion"),
            ),
          ),

          const SizedBox(height: 40),

          // --- SUPPORT BUTTON ---
          Center(
            child: FilledButton.icon(
              onPressed: _launchBuyMeACoffee,
              icon: const Icon(Icons.coffee_rounded),
              label: const Text("Support the Developer"),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Center(
            child: Text(
              "Your support helps us keep GameLog ad-free forever.",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(BuildContext context, RoadmapItem item) {
    final color = item.isCompleted ? Colors.green : Theme.of(context).colorScheme.primary;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Icon(
              item.isCompleted ? Icons.check_circle : Icons.circle_outlined,
              size: 20,
              color: color,
            ),
            Container(
              width: 2,
              height: 40,
              color: Colors.grey.withValues(alpha: 0.2),
            ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: item.isCompleted ? Colors.grey : null,
                  decoration: item.isCompleted ? TextDecoration.lineThrough : null,
                ),
              ),
              Text(
                item.description,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }
}