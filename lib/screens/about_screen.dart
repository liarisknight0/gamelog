import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About GameLog'),
      ),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'GameLog',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Version 2.0.0', // Updated version number
              style: TextStyle(color: Colors.grey),
            ),
            SizedBox(height: 24),
            Text(
              'GameLog is a simple, offline-first app designed to help you conquer your video game backlog. It is my first step into Software development. ----Liaris Knight',
            ),
            // The support button has been removed from this screen.
          ],
        ),
      ),
    );
  }
}