import 'package:flutter/material.dart';

class Review{
  final String userName;
  final String profileImageUrl;
  final double rating;
  final String comment;

  Review({
    required this.userName,
    required this.profileImageUrl,
    required this.rating,
    required this.comment
  });
}

class WebReviewCard extends StatelessWidget {
  final Review review;

  const WebReviewCard({super.key, required this.review});
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 24,
          backgroundImage: NetworkImage(review.profileImageUrl),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                review.userName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    '★★★★★'.substring(0, review.rating.round()),
                    style: const TextStyle(
                      color: Colors.amber,
                      fontSize: 14
                    ),
                  )
                ],
              ),
              const SizedBox(height: 8),
              Text(
                review.comment,
                style: const TextStyle(
                  fontSize: 15,
                ),
              )
            ],
          ),
        )
      ],
    );
  }
}