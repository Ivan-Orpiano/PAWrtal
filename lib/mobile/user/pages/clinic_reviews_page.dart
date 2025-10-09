import 'package:capstone_app/data/models/clinic_model.dart';
import 'package:flutter/material.dart';

class Review {
  final String userName;
  final String profileImageUrl;
  final double rating;
  final String comment;

  Review({
    required this.userName,
    required this.profileImageUrl,
    required this.rating,
    required this.comment,
  });
}

class ClinicReviewsPage extends StatefulWidget {
  final Clinic clinic;

  const ClinicReviewsPage({super.key, required this.clinic});

  @override
  State<ClinicReviewsPage> createState() => _ClinicReviewsPageState();
}

class _ClinicReviewsPageState extends State<ClinicReviewsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Mock data - replace with actual data from backend
  final List<Review> reviews = [
    Review(
      userName: 'Juan',
      profileImageUrl: 'https://images.unsplash.com/photo-1508672019048-805c876b67e2',
      rating: 5,
      comment: 'Amazing experience! The service was excellent and I really felt valued. Definitely recommend to everyone.',
    ),
    Review(
      userName: 'Will',
      profileImageUrl: 'https://images.unsplash.com/photo-1517841905240-472988babdf9',
      rating: 4,
      comment: 'Very good overall. A few small things could be improved, but I\'m still satisfied.',
    ),
    Review(
      userName: 'Smith',
      profileImageUrl: 'https://images.unsplash.com/photo-1517423440428-a5a00ad493e8',
      rating: 3,
      comment: 'It was okay. Not bad, but nothing too special either. Average experience.',
    ),
    Review(
      userName: 'Wally',
      profileImageUrl: 'https://images.unsplash.com/photo-1543852786-1cf6624b9987',
      rating: 2,
      comment: 'Honestly not the best. I expected more, and a few things really need improvement.',
    ),
    Review(
      userName: 'Brian',
      profileImageUrl: 'https://images.unsplash.com/photo-1487412912498-0447578fcca8',
      rating: 1.5,
      comment: 'Pretty disappointing. The experience didn\'t meet my expectations at all.',
    ),
    Review(
      userName: 'Mia',
      profileImageUrl: 'https://images.unsplash.com/photo-1529626455594-4ff0802cfb7e',
      rating: 5,
      comment: 'Perfect! I had such a great time, everything went smoothly and exceeded my expectations.',
    ),
  ];

  List<Review> get filteredReviews {
    if (_searchQuery.isEmpty) return reviews;
    return reviews.where((review) {
      return review.userName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          review.comment.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  double calculateAverageRating() {
    if (reviews.isEmpty) return 0;
    double total = reviews.fold(0, (sum, item) => sum + item.rating);
    return total / reviews.length;
  }

  Map<int, double> calculateRatingPercentages() {
    Map<int, int> counts = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};

    for (var review in reviews) {
      counts[review.rating.round()] = counts[review.rating.round()]! + 1;
    }

    final total = reviews.length;
    if (total == 0) {
      return {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    }
    return counts.map((key, value) => MapEntry(key, value / total));
  }

  Widget buildStarRating(double rating, {double size = 20}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        double starFill = (rating - index).clamp(0.0, 1.0);
        return Stack(
          children: [
            Icon(Icons.star_border_rounded, size: size, color: Colors.amber),
            ClipRect(
              clipper: _StarClipper(starFill),
              child: Icon(Icons.star_rounded, size: size, color: Colors.amber),
            ),
          ],
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    double averageRating = calculateAverageRating();
    Map<int, double> ratingPercentages = calculateRatingPercentages();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close_rounded, color: Colors.black),
        ),
        title: const Text(
          'Ratings & Reviews',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const Divider(height: 1),
          // Rating Summary
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text(
                  averageRating.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                buildStarRating(averageRating, size: 24),
                const SizedBox(height: 8),
                Text(
                  "${reviews.length} reviews",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 20),
                // Rating bars
                ...((ratingPercentages.entries.toList()
                      ..sort((a, b) => b.key.compareTo(a.key)))
                    .map((entry) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Text(
                          entry.key.toString(),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.star, size: 14, color: Colors.amber),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Stack(
                            children: [
                              Container(
                                height: 8,
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              FractionallySizedBox(
                                widthFactor: entry.value,
                                child: Container(
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: Colors.black,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 35,
                          child: Text(
                            '${(entry.value * 100).toInt()}%',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                })),
              ],
            ),
          ),
          const Divider(height: 1),
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search reviews',
                hintStyle: const TextStyle(fontSize: 14),
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.black, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          // Reviews List
          Expanded(
            child: filteredReviews.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No reviews found',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    itemCount: filteredReviews.length,
                    separatorBuilder: (context, index) => const Divider(height: 32),
                    itemBuilder: (context, index) {
                      final review = filteredReviews[index];
                      return _ReviewCard(review: review);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final Review review;

  const _ReviewCard({required this.review});

  Widget buildStarRating(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < rating.round() ? Icons.star : Icons.star_border,
          color: Colors.amber,
          size: 16,
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 20,
          backgroundImage: NetworkImage(review.profileImageUrl),
          backgroundColor: Colors.grey.shade300,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                review.userName,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),
              buildStarRating(review.rating),
              const SizedBox(height: 8),
              Text(
                review.comment,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StarClipper extends CustomClipper<Rect> {
  final double fillPercentage;

  _StarClipper(this.fillPercentage);

  @override
  Rect getClip(Size size) {
    return Rect.fromLTRB(0, 0, size.width * fillPercentage, size.height);
  }

  @override
  bool shouldReclip(_StarClipper oldClipper) {
    return oldClipper.fillPercentage != fillPercentage;
  }
}