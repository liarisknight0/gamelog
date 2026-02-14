import 'package:flutter/material.dart';

class RoadmapItem {
  final String title;
  final String description;
  final bool isCompleted;
  RoadmapItem(this.title, this.description, this.isCompleted);
}

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<RoadmapItem> roadmap = [
      RoadmapItem("v1.0 Launch", "Basic game tracking and local storage.", true),
      RoadmapItem("API Integration", "Automated game search and cover art.", false),
      RoadmapItem("Sorting and Filtering", "Efficiency", false),
      RoadmapItem("Import/Export Data", "Export your database ain some formate.", false),
      RoadmapItem("Account Sync", "Connect all platforms and import all the games collections.", false),
      RoadmapItem("Cloud Sync", "Sync your library across all devices.", false),
      RoadmapItem("Stats Dashboard", "Visual analytics of your gaming habits.", false),
      RoadmapItem("Social Features", "Share your backlog with friends.", false),
      RoadmapItem("Animation", "making the app alive", false),
      RoadmapItem("HLTB Integration", "Show estimated main and completionist playtime on game details.", false),
      RoadmapItem("Random Game Selector", "Pick a random backlog game to fight choice paralysis.", false),
      RoadmapItem("Shimmer Loading States", "Skeleton loaders for smoother, premium loading experience.", false),
      RoadmapItem("Custom Filter Tags", "Quick filter chips for platform, genre, and custom tags.", false),
      RoadmapItem("Monthly Goals & Year Review", "Track completed games and show progress toward goals.", false),
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

    return Scaffold(
      appBar: AppBar(title: const Text('Support & Feature Drop')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            "The Future of GameLog",
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text("We are constantly working on new features, but some features are subject to change: "),
          const SizedBox(height: 30),

          // --- THE TIMELINE ---
          ...roadmap.map((item) => _buildTimelineItem(context, item)),

          const SizedBox(height: 40),
          const Divider(),
          const SizedBox(height: 20),
          Center(
            child: FilledButton.icon(
              onPressed: () {  },
              icon: const Icon(Icons.coffee),
              label: const Text("Support Development"),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTimelineItem(BuildContext context, RoadmapItem item) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Icon(
              item.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
              color: item.isCompleted ? Colors.green : Theme.of(context).colorScheme.primary,
            ),
            Container(
              width: 2,
              height: 50,
              color: Colors.grey.withValues(alpha: 0.3),
            ),
          ],
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  decoration: item.isCompleted ? TextDecoration.lineThrough : null,
                ),
              ),
              Text(
                item.description,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ],
    );
  }
}