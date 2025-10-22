import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../design_system/design_tokens.dart';

class ProfileAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? name;
  final double size;
  final bool showBorder;
  final Color? borderColor;
  final VoidCallback? onTap;

  const ProfileAvatar({
    super.key,
    this.imageUrl,
    this.name,
    this.size = 40.0,
    this.showBorder = false,
    this.borderColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final initials = _getInitials(name ?? '');
    final color = _getColorFromName(name ?? '');
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: showBorder
              ? Border.all(
                  color: borderColor ?? Colors.white,
                  width: 2,
                )
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipOval(
          child: imageUrl != null && imageUrl!.isNotEmpty
              ? Image.network(
                  imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildInitialsAvatar(initials, color);
                  },
                )
              : _buildInitialsAvatar(initials, color),
        ),
      ),
    );
  }

  Widget _buildInitialsAvatar(String initials, Color color) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, color.withOpacity(0.7)],
        ),
      ),
      child: Center(
        child: Text(
          initials,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: size * 0.4,
            fontWeight: MemoryHubTypography.semiBold,
          ),
        ),
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    
    final parts = name.trim().split(' ');
    if (parts.length == 1) {
      return parts[0][0].toUpperCase();
    }
    return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
  }

  Color _getColorFromName(String name) {
    if (name.isEmpty) return MemoryHubColors.gray500;
    
    final colors = [
      MemoryHubColors.indigo500,
      MemoryHubColors.pink500,
      MemoryHubColors.purple500,
      MemoryHubColors.cyan500,
      MemoryHubColors.amber500,
      MemoryHubColors.green500,
      MemoryHubColors.teal500,
    ];
    
    final index = name.codeUnitAt(0) % colors.length;
    return colors[index];
  }
}

class ProfileAvatarStack extends StatelessWidget {
  final List<String?> imageUrls;
  final List<String?> names;
  final double size;
  final int maxDisplay;
  final VoidCallback? onTap;

  const ProfileAvatarStack({
    super.key,
    required this.imageUrls,
    required this.names,
    this.size = 40.0,
    this.maxDisplay = 3,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final displayCount = imageUrls.length > maxDisplay ? maxDisplay : imageUrls.length;
    final extraCount = imageUrls.length > maxDisplay ? imageUrls.length - maxDisplay : 0;
    
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: size + (displayCount - 1) * size * 0.6 + (extraCount > 0 ? size * 0.6 : 0),
        height: size,
        child: Stack(
          children: [
            for (int i = 0; i < displayCount; i++)
              Positioned(
                left: i * size * 0.6,
                child: ProfileAvatar(
                  imageUrl: imageUrls[i],
                  name: names.length > i ? names[i] : null,
                  size: size,
                  showBorder: true,
                  borderColor: Theme.of(context).scaffoldBackgroundColor,
                ),
              ),
            if (extraCount > 0)
              Positioned(
                left: displayCount * size * 0.6,
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: MemoryHubColors.gray700,
                    border: Border.all(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '+$extraCount',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: size * 0.35,
                        fontWeight: MemoryHubTypography.semiBold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class ProfileAvatarWithStatus extends StatelessWidget {
  final String? imageUrl;
  final String? name;
  final double size;
  final bool isOnline;
  final VoidCallback? onTap;

  const ProfileAvatarWithStatus({
    super.key,
    this.imageUrl,
    this.name,
    this.size = 40.0,
    this.isOnline = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ProfileAvatar(
          imageUrl: imageUrl,
          name: name,
          size: size,
          onTap: onTap,
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            width: size * 0.3,
            height: size * 0.3,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isOnline ? MemoryHubColors.green500 : MemoryHubColors.gray400,
              border: Border.all(
                color: Theme.of(context).scaffoldBackgroundColor,
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
