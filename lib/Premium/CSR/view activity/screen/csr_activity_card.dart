import 'dart:math';
import 'package:flutter/material.dart';

import '../../../Configuration/ApiUrlConfig.dart';

class CsrActivityCard extends StatelessWidget {
  final String userName;
  final String imagePath;
  final String colorHex; // Still here, but unused for background now
  final String image;

  const CsrActivityCard({
    super.key,
    required this.userName,
    required this.imagePath,
    required this.colorHex,
    required this.image,
  });

  // Generate random pastel-like color
  Color getRandomColor() {
    final random = Random();
    return Color.fromARGB(
      255,
      150 + random.nextInt(100), // R: 150-249
      150 + random.nextInt(100), // G: 150-249
      150 + random.nextInt(100), // B: 150-249
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color randomCardColor = getRandomColor();

    final String imageUrl = imagePath.isNotEmpty
        ? '${ApiUrlConfig().csrimageBaseUrl}/$imagePath' // change from base url to CSR image base url
        : '';

    final String imageProfile = image.isNotEmpty
        ? '${ApiUrlConfig().csrimageBaseUrl}$image' // change from base url to CSR image base url
        : '';

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: imageUrl.isNotEmpty
                ? Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Image.asset('assets/images/document.png',
                          fit: BoxFit.cover);
                    },
                  )
                : Image.asset('assets/images/document.png', fit: BoxFit.cover),
          ),

          // Bottom user label with avatar
          Positioned(
            bottom: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: randomCardColor.withOpacity(0.85),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 10,
                    backgroundImage: imageProfile.isNotEmpty
                        ? NetworkImage(imageProfile)
                        : const AssetImage('assets/images/user.png')
                            as ImageProvider,
                    backgroundColor: Colors.transparent,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    userName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
