// A home for our static tag data

// We use a simple class to hold the name and maybe an icon for a tag.
class Tag {
  final String name;
  // In the future, you could add: final IconData icon;

  const Tag(this.name);
}

const List<Tag> platformTags = [
  Tag('PlayStation'),
  Tag('Xbox'),
  Tag('Nintendo'),
  Tag('Steam'),
  Tag('PC'),
  Tag('Epic Games'),
  Tag('GOG'),
  Tag('Mobile'),
];

const List<Tag> genreTags = [
  Tag('Action'),
  Tag('Action-Adventure'),
  Tag('Adventure'),
  Tag('RPG'),
  Tag('JRPG'),
  Tag('Strategy'),
  Tag('Simulation'),
  Tag('Puzzle'),
  Tag('Sports'),
  Tag('Racing'),
  Tag('Fighting'),
  Tag('Platformer'),
  Tag('Shooter'),
  Tag('Survival Horror'),
  Tag('Metroidvania'),
  Tag('Roguelike'),
  Tag('Indie'),
];