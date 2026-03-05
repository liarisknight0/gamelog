import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final TextEditingController _suggestionController = TextEditingController();

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

    // Replace with your actual email address
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
      appBar: AppBar(title: const Text('Support GameLog')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children:[
          // --- SUGGESTION SECTION ---
          Text(
            "Suggest a Feature",
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text("Have an idea to make GameLog better or found a bug? Tell us about it!"),
          const SizedBox(height: 16),

          TextField(
            controller: _suggestionController,
            maxLines: 5, // Slightly taller since we have more screen space now
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
          const Divider(),
          const SizedBox(height: 40),

          // --- SUPPORT BUTTON ---
          Text(
            "Support the Developer",
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Center(
            child: FilledButton.icon(
              onPressed: _launchBuyMeACoffee,
              icon: const Icon(Icons.coffee_rounded),
              label: const Text("Buy Me a Coffee"),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                backgroundColor: const Color(0xFFFFDD00), // Standard Buy Me a Coffee Yellow
                foregroundColor: Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Center(
            child: Text(
              "GameLog is built by an independent developer. Your support helps keep the app ad-free and funds future updates!",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey, height: 1.5),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}