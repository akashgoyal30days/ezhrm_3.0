import 'dart:math';
import 'package:flutter/material.dart';

import '../../../Configuration/ApiUrlConfig.dart';

class CsrActivityStatusCard extends StatelessWidget {
  final String userName;
  final String imagePath;
  final String status; // 'pending', 'approved', or 'rejected'
  final String profileImage;
  final VoidCallback? onTap;

  const CsrActivityStatusCard({
    super.key,
    required this.userName,
    required this.imagePath,
    required this.status,
    required this.profileImage,
    this.onTap,
  });

  // Status color mapping
  Color getStatusColor() {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
      default:
        return Colors.orange;
    }
  }

  // Generate random pastel-like color for user label background
  Color getRandomColor() {
    final random = Random();
    return Color.fromARGB(
      255,
      150 + random.nextInt(100),
      150 + random.nextInt(100),
      150 + random.nextInt(100),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color randomCardColor = getRandomColor();
    final Color statusColor = getStatusColor();

    // Build proper image URLs
    final String activityImageUrl = imagePath.isNotEmpty
        ? '${ApiUrlConfig().baseUrl}/${imagePath.startsWith('/') ? imagePath.substring(1) : imagePath}'
        : '';

    final String profileImageUrl = profileImage.isNotEmpty
        ? '${ApiUrlConfig().baseUrl}/${profileImage.startsWith('/') ? profileImage.substring(1) : profileImage}'
        : '';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        // Add fixed height and width constraints
        height: 200, // Adjust as needed
        width: MediaQuery.of(context).size.width / 2 - 18, // For grid layout
        margin: const EdgeInsets.all(6), // Add some margin
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Background Image
              Positioned.fill(
                child: activityImageUrl.isNotEmpty
                    ? Image.network(
                        activityImageUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[200],
                            child: const Icon(Icons.image_not_supported),
                          );
                        },
                      )
                    : Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.image_not_supported),
                      ),
              ),

              // Status indicator
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              // Bottom user label with avatar
              Positioned(
                bottom: 12,
                left: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: randomCardColor.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 10,
                        backgroundImage: profileImageUrl.isNotEmpty
                            ? NetworkImage(profileImageUrl) as ImageProvider
                            : const AssetImage('assets/images/user.png'),
                        backgroundColor: Colors.transparent,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        userName.isNotEmpty ? userName : 'Unknown User',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),

              // Dark overlay for better text visibility
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.3),
                      ],
                      stops: const [0.6, 1.0],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
