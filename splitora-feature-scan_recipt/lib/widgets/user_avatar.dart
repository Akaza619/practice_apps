import 'dart:io';
import 'package:flutter/material.dart';
import 'package:splitora_app/theme/app_theme.dart';

class UserAvatar extends StatelessWidget {
  final double radius;
  final String? photoURL;
  final String? displayName;
  final String? firstName;

  const UserAvatar({
    super.key,
    this.radius = 16,
    this.photoURL,
    this.displayName,
    this.firstName,
  });

  @override
  Widget build(BuildContext context) {
    if (photoURL != null && photoURL!.isNotEmpty) {
      final file = File(photoURL!);
      if (file.existsSync()) {
        return CircleAvatar(
          radius: radius,
          backgroundImage: FileImage(file),
          backgroundColor: AppTheme.avatarImageBackground,
        );
      }
      // If photoURL starts with http, try NetworkImage
      if (photoURL!.startsWith('http')) {
        return CircleAvatar(
          radius: radius,
          backgroundImage: NetworkImage(photoURL!),
          backgroundColor: AppTheme.avatarImageBackground,
          onBackgroundImageError: (_, _) {},
        );
      }
    }

    // Fallback to initials
    final String initial = (displayName ?? firstName ?? 'U')[0].toUpperCase();
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppTheme.avatarBackground,
      child: Text(
        initial,
        style: TextStyle(
          color: AppTheme.textPrimary,
          fontSize: radius * 0.8,
        ),
      ),
    );
  }
}
