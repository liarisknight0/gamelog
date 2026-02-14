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
      RoadmapItem("API Integration", "Automated game search and cover art.", true),
      RoadmapItem("Stats Dashboard", "Visual analytics of your gaming habits.", false),
      RoadmapItem("Cloud Sync", "Sync your library across all devices.", false),
      RoadmapItem("Social Features", "Share your backlog with friends.", false),
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
          const Text("We are constantly working on new features. Here is what is coming next:"),
          const SizedBox(height: 30),

          // --- THE TIMELINE ---
          ...roadmap.map((item) => _buildTimelineItem(context, item)),

          const SizedBox(height: 40),
          const Divider(),
          const SizedBox(height: 20),
          Center(
            child: FilledButton.icon(
              onPressed: () { /* Link to Buy Me a Coffee or similar */ },
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