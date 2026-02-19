import 'package:flutter/material.dart';

class LoadingOverlay {
  static OverlayEntry? _overlayEntry;

  static void show(BuildContext context) {
    if (_overlayEntry != null) return; // Already showing

    _overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Semi-transparent background
          Positioned.fill(
            child: Container(
              color: Colors.black54,
            ),
          ),
          // Centered spinner
          const Center(
            child: CircularProgressIndicator(),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  static void hide() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
}