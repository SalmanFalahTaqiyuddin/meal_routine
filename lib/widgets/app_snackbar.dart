import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:nyobaapihehe/config/app_theme.dart';

class AppSnackbar {
  static final AudioPlayer _player = AudioPlayer();

  static void show(BuildContext context, {required String message}) async {
    // Efek suara
    try {
      await _player.play(AssetSource('sounds/fail.mp3'));
    } catch (e) {
      debugPrint("Audio error: $e");
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'SF Pro',
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: AppTheme.primaryGreen, // Menggunakan 0xFF285B45
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        margin: const EdgeInsets.fromLTRB(40, 0, 40, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
