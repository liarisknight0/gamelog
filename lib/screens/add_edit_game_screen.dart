import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gamelog/models/game.dart';
import 'package:gamelog/models/tag_data.dart';
import 'package:gamelog/providers/game_provider.dart';
import 'package:gamelog/screens/online_search_screen.dart';
import 'package:gamelog/services/igdb_service.dart';
import 'package:gamelog/widgets/tag_selector.dart';
import 'package:hive/hive.dart';

class AddEditGameScreen extends ConsumerStatefulWidget {
  final Game? game;
  final GameStatus? defaultStatus;

  const AddEditGameScreen({super.key, this.game, this.defaultStatus});

  @override
  ConsumerState<AddEditGameScreen> createState() => _AddEditGameScreenState();
}

class _AddEditGameScreenState extends ConsumerState<AddEditGameScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();

  String? _coverUrl;
  String? _summary;
  double? _rating;
  String? _selectedPlatform;
  String? _selectedGenre;
  GameStatus? _selectedStatus;
  String? _notes;
  bool? _isPhysical;
  double? _progress;

  @override
  void initState() {
    super.initState();
    if (widget.game != null) {
      _titleController.text = widget.game!.title;
      _selectedPlatform = widget.game!.platform;
      _selectedGenre = widget.game!.genre;
      _selectedStatus = widget.game!.status;
      _coverUrl = widget.game!.coverUrl;
      _summary = widget.game!.summary;
      _rating = widget.game!.rating;
      _notes = widget.game!.notes;
      _isPhysical = widget.game!.isPhysical;
      _progress = widget.game!.progress;
    } else {
      _selectedStatus = widget.defaultStatus ?? GameStatus.backlog;
      _isPhysical = false;
      _progress = 0.0;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _searchOnline() async {
    final result = await Navigator.of(context).push<ApiGame>(
      MaterialPageRoute(builder: (_) => const OnlineSearchScreen()),
    );
    if (result != null) {
      setState(() {
        _titleController.text = result.title;
        _coverUrl = result.coverUrl;
        _summary = result.summary;
        _rating = result.rating;
        _selectedPlatform = result.platforms.split(',').first.trim();
        _selectedGenre = result.genres.split(',').first.trim();
      });
    }
  }

  void _saveForm() {
    if (_formKey.currentState!.validate()) {
      if (_selectedPlatform == null || _selectedGenre == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a platform and genre.')));
        return;
      }

      final isEditing = widget.game != null;
      final gameData = Game(
        title: _titleController.text,
        platform: _selectedPlatform!,
        genre: _selectedGenre!,
        status: _selectedStatus!,
        dateAdded: widget.game?.dateAdded ?? DateTime.now(),
        coverUrl: _coverUrl,
        summary: _summary,
        rating: _rating,
        notes: _notes,
        isPhysical: _isPhysical,
        progress: _progress,
      );

      final notifier = ref.read(gameListProvider.notifier);
      if (isEditing) {
        final originalKey = widget.game!.key;
        Hive.box<Game>('games').put(originalKey, gameData);
        notifier.refresh();
      } else {
        notifier.addGame(gameData);
      }
      Navigator.of(context).pop();
    }
  }

  void _deleteGame() {
    if (widget.game == null) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Game?'),
        content: Text('Are you sure you want to permanently delete "${widget.game!.title}"?'),
        actions: [
          TextButton(child: const Text('Cancel'), onPressed: () => Navigator.of(ctx).pop()),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
            onPressed: () {
              ref.read(gameListProvider.notifier).deleteGame(widget.game!);
              Navigator.of(ctx).pop(); // Close dialog
              Navigator.of(context).pop(); // Close edit screen
            },
          ),
        ],
      ),
    );
  }

  void _showPlatformSelector() async {
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Select a Platform'),
        content: SizedBox(
          width: double.maxFinite,
          child: TagSelector(
            title: 'Select a Platform', // <--- FIX HERE: Added required title
            tags: platformTags,
            currentlySelected: _selectedPlatform,
          ),
        ),
      ),
    );
    if (result != null) setState(() => _selectedPlatform = result);
  }

  void _showGenreSelector() async {
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Select a Genre'),
        content: SizedBox(
          width: double.maxFinite,
          child: TagSelector(
            title: 'Select a Genre', // <--- FIX HERE: Added required title
            tags: genreTags,
            currentlySelected: _selectedGenre,
          ),
        ),
      ),
    );
    if (result != null) setState(() => _selectedGenre = result);
  }

  void _showStatusSelector() async {
    final result = await showDialog<GameStatus>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Select Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: GameStatus.values.map((status) {
            return ListTile(
              title: Text(_getStatusText(status)),
              trailing: _selectedStatus == status ? const Icon(Icons.check, color: Colors.green) : null,
              onTap: () {
                Navigator.pop(ctx, status);
              },
            );
          }).toList(),
        ),
      ),
    );
    if (result != null) setState(() => _selectedStatus = result);
  }

  String _getStatusText(GameStatus status) {
    switch (status) {
      case GameStatus.nowPlaying: return 'Now Playing';
      case GameStatus.notStarted: return 'Not Started';
      case GameStatus.beaten: return 'Beaten';
      case GameStatus.paused: return 'Paused';
      case GameStatus.dropped: return 'Dropped';
      case GameStatus.backlog: return 'Backlog';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.game != null;
    final appBarTitle = isEditing ? 'Edit Game' : 'Add New Game';

    return Scaffold(
      appBar: AppBar(
        title: Text(appBarTitle),
        actions: [
          if (isEditing)
            IconButton(onPressed: _deleteGame, icon: const Icon(Icons.delete))
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(child: _buildFormFields()),
              const SizedBox(height: 20),
              SafeArea(
                top: false,
                child: _buildSaveButton(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormFields() {
    return ListView(
      children: [
        if (widget.game == null)
          Padding(
            padding: const EdgeInsets.only(bottom: 24.0),
            child: OutlinedButton.icon(
              icon: const Icon(Icons.search),
              label: const Text('Search Online First'),
              onPressed: _searchOnline,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        if (_coverUrl != null)
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: _coverUrl!,
                  height: 180,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => const SizedBox(
                      height: 180,
                      width: 130,
                      child: Center(child: CircularProgressIndicator())),
                  errorWidget: (context, url, error) => const Icon(Icons.error, size: 50),
                ),
              ),
            ),
          ),
        TextFormField(
          controller: _titleController,
          decoration: const InputDecoration(labelText: 'Title'),
          validator: (value) => value!.trim().isEmpty ? 'Please enter a title.' : null,
        ),
        const SizedBox(height: 16),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Platform'),
          subtitle: Text(_selectedPlatform ?? 'Not selected'),
          trailing: const Icon(Icons.arrow_drop_down),
          onTap: _showPlatformSelector,
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Genre'),
          subtitle: Text(_selectedGenre ?? 'Not selected'),
          trailing: const Icon(Icons.arrow_drop_down),
          onTap: _showGenreSelector,
        ),
        const SizedBox(height: 16),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Status'),
          subtitle: Text(_getStatusText(_selectedStatus ?? GameStatus.backlog)),
          trailing: const Icon(Icons.arrow_drop_down),
          onTap: _showStatusSelector,
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        icon: const Icon(Icons.save),
        label: Text(widget.game != null ? 'Save Changes' : 'Add Game'),
        onPressed: _saveForm,
      ),
    );
  }
}