import 'package:flutter/material.dart';

import 'app_theme.dart';

/// Round profile photo with a fallback (initial or icon) and an optional
/// small camera badge for "tap to change".
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.url,
    this.name = '',
    this.radius = 24,
    this.fallbackIcon,
    this.editable = false,
    this.onTap,
  });

  final String? url;
  final String name;
  final double radius;
  final IconData? fallbackIcon;
  final bool editable;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final hasPhoto = url != null && url!.isNotEmpty;
    final initial = name.trim().isEmpty ? '' : name.trim().characters.first;
    Widget avatar = CircleAvatar(
      radius: radius,
      backgroundColor: context.colors.primaryContainer,
      foregroundColor: context.accent,
      foregroundImage: hasPhoto ? NetworkImage(url!) : null,
      child: initial.isNotEmpty && fallbackIcon == null
          ? Text(
              initial,
              style: TextStyle(
                fontSize: radius * 0.8,
                fontWeight: FontWeight.w800,
              ),
            )
          : Icon(fallbackIcon ?? Icons.person_rounded, size: radius),
    );
    if (editable) {
      avatar = Stack(
        clipBehavior: Clip.none,
        children: [
          avatar,
          PositionedDirectional(
            bottom: -2,
            end: -2,
            child: Container(
              padding: EdgeInsets.all(radius * 0.14),
              decoration: BoxDecoration(
                color: AppColors.brand,
                shape: BoxShape.circle,
                border: Border.all(
                  color: context.colors.surfaceContainerLowest,
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.photo_camera_rounded,
                size: radius * 0.42,
                color: AppColors.onBrand,
              ),
            ),
          ),
        ],
      );
    }
    if (onTap == null) return avatar;
    return GestureDetector(onTap: onTap, child: avatar);
  }
}
