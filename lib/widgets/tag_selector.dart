import 'package:flutter/material.dart';
import 'package:gamelog/models/tag_data.dart';

class TagSelector extends StatelessWidget {
  final String title;
  final List<Tag> tags;
  final String? currentlySelected;

  const TagSelector({
    super.key,
    required this.title,
    required this.tags,
    this.currentlySelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          // Wrap allows items to flow to the next line if they don't fit
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: tags.map((tag) {
              final isSelected = tag.name == currentlySelected;
              return ChoiceChip(
                label: Text(tag.name),
                selected: isSelected,
                onSelected: (selected) {
                  // When a chip is tapped, pop the sheet and return the value.
                  Navigator.pop(context, tag.name);
                },
                selectedColor: Theme.of(context).colorScheme.primary,
                labelStyle: TextStyle(
                  color: isSelected ? Theme.of(context).colorScheme.onPrimary : null,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}