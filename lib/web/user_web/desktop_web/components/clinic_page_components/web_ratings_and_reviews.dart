import 'package:capstone_app/data/models/ratings_and_review_model.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/web/dimensions.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

Widget buildStarRating(double rating, {double size = 30}) {
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

class WebRatingsAndReviews extends StatefulWidget {
  final GlobalKey? reviewsEndKey;
  final String clinicId; // ADDED: Need clinic ID to fetch reviews
  
  const WebRatingsAndReviews({
    super.key,
    this.reviewsEndKey,
    required this.clinicId, // REQUIRED
  });

  @override
  State<WebRatingsAndReviews> createState() => _WebRatingsAndReviewsState();
}

class _WebRatingsAndReviewsState extends State<WebRatingsAndReviews> {
  final AuthRepository _authRepo = Get.find<AuthRepository>();
  List<RatingAndReview> reviews = [];
  ClinicRatingStats? stats;
  bool isLoading = true;
  String searchQuery = '';
  final TextEditingController _controller = TextEditingController();
  bool _showClear = false;

  @override
  void initState() {
    super.initState();
    _loadReviews();
    _controller.addListener(() {
      setState(() {
        _showClear = _controller.text.isNotEmpty;
        searchQuery = _controller.text.toLowerCase();
      });
    });
  }

  Future<void> _loadReviews() async {
    setState(() => isLoading = true);
    
    try {
      final fetchedReviews = await _authRepo.getClinicReviews(widget.clinicId);
      final fetchedStats = await _authRepo.getClinicRatingStats(widget.clinicId);
      
      setState(() {
        reviews = fetchedReviews;
        stats = fetchedStats;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  List<RatingAndReview> get filteredReviews {
    if (searchQuery.isEmpty) return reviews;
    
    return reviews.where((review) {
      final userName = review.userName.toLowerCase();
      final reviewText = (review.reviewText ?? '').toLowerCase();
      final service = review.serviceName.toLowerCase();
      
      return userName.contains(searchQuery) ||
             reviewText.contains(searchQuery) ||
             service.contains(searchQuery);
    }).toList();
  }

  double calculateAverageRating() {
    if (reviews.isEmpty) return 0;
    return stats?.averageRating ?? 0;
  }

  Map<int, double> calculateRatingPercentages() {
    if (stats == null) {
      return {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    }
    
    final total = stats!.totalReviews;
    if (total == 0) return {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    
    return {
      1: (stats!.ratingDistribution[1] ?? 0) / total,
      2: (stats!.ratingDistribution[2] ?? 0) / total,
      3: (stats!.ratingDistribution[3] ?? 0) / total,
      4: (stats!.ratingDistribution[4] ?? 0) / total,
      5: (stats!.ratingDistribution[5] ?? 0) / total,
    };
  }

  double responsiveDialogWidth(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth >= tabletWidth) {
      return 1020;
    } else {
      return screenWidth * 0.9;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(),
        ),
      );
    }

    double averageRating = calculateAverageRating();
    Map<int, double> ratingPercentages = calculateRatingPercentages();
    final displayReviews = filteredReviews.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              "Ratings & Reviews",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600
              ),
            ),
            const Spacer(),
            if (reviews.isNotEmpty)
              Row(
                children: [
                  Text(
                    "${averageRating.toStringAsFixed(1)} / 5",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600
                    ),
                  ),
                  const Icon(
                    Icons.star_rate_rounded,
                    color: Colors.amber,
                    size: 34,
                  )
                ],
              ),
          ],
        ),

        if (reviews.isEmpty)
          _buildNoReviews()
        else ...[
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: (ratingPercentages.entries.toList()
                ..sort((a, b) => b.key.compareTo(a.key)))
                .map((entry) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Text(
                          entry.key.toString(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600
                          ),
                        ),
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
                      ],
                    ),
                  );
                }).toList(),
            ),
          ),
          
          const SizedBox(height: 16),
          
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: displayReviews.length,
            separatorBuilder: (context, index) => const SizedBox(height: 24),
            itemBuilder: (context, index) {
              return _buildReviewCard(displayReviews[index]);
            },
          ),
        ],

        const SizedBox(height: 32),
        
        if (reviews.isNotEmpty)
          GestureDetector(
            onTap: () => _showAllReviewsDialog(averageRating, ratingPercentages),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: Colors.black),
                  ),
                  key: widget.reviewsEndKey,
                  child: Text(
                    "Show all ${reviews.length} reviews",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600
                    ),
                  ),
                ),
              ],
            ),
          )
      ],
    );
  }

  Widget _buildNoReviews() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 40),
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.rate_review_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No reviews yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Be the first to review this clinic!',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewCard(RatingAndReview review) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color.fromARGB(255, 81, 115, 153).withOpacity(0.1),
                child: Text(
                  review.userName[0].toUpperCase(),
                  style: const TextStyle(
                    color: Color.fromARGB(255, 81, 115, 153),
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          review.userName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      review.getTimeAgo(),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              buildStarRating(review.rating, size: 20),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Service badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '${review.serviceName}${review.petName != null ? ' • ${review.petName}' : ''}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          
          if (review.hasReview) ...[
            const SizedBox(height: 12),
            Text(
              review.reviewText!,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          
          if (review.hasImages) ...[
            const SizedBox(height: 12),
            _buildReviewImages(review.images),
          ],
        ],
      ),
    );
  }

  Widget _buildReviewImages(List<String> imageIds) {
    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: imageIds.length > 3 ? 3 : imageIds.length,
        itemBuilder: (context, index) {
          final imageUrl = _authRepo.getImageUrl(imageIds[index]);
          
          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                imageUrl,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.image_not_supported),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  void _showAllReviewsDialog(double averageRating, Map<int, double> ratingPercentages) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)
          ),
          insetPadding: const EdgeInsets.symmetric(vertical: 60),
          child: Container(
            width: responsiveDialogWidth(context),
            height: 700,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20)
            ),
            clipBehavior: Clip.hardEdge,
            child: Padding(
              padding: const EdgeInsets.only(left: 16, right: 16),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      InkWell(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.only(left: 42),
                      child: Row(
                        children: [
                          // Left side - Statistics
                          Flexible(
                            flex: 2,
                            child: Column(
                              children: [
                                Text(
                                  averageRating.toStringAsFixed(1),
                                  style: const TextStyle(
                                    fontSize: 48,
                                    fontWeight: FontWeight.bold
                                  ),
                                ),
                                const SizedBox(height: 28),
                                buildStarRating(averageRating),
                                const SizedBox(height: 28),
                                const SizedBox(
                                  width: 300,
                                  child: Divider(
                                    height: 1,
                                    thickness: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 28),
                                Text(
                                  "${reviews.length} reviews",
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600 
                                  ),
                                ),
                                const SizedBox(height: 28),
                                const SizedBox(
                                  width: 300,
                                  child: Divider(
                                    height: 1,
                                    thickness: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 28),
                                const Text(
                                  "Overall Rating",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600
                                  ),
                                ),
                                SizedBox(
                                  height: 200,
                                  width: 300,
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 16.0),
                                    child: Column(
                                      children: (ratingPercentages.entries.toList()
                                        ..sort((a, b) => b.key.compareTo(a.key)))
                                        .map((entry) {
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 4),
                                            child: Row(
                                              children: [
                                                Text(
                                                  entry.key.toString(),
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
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
                                              ],
                                            ),
                                          );
                                        }).toList(),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                    
                          const SizedBox(width: 32),
                    
                          // Right side - Reviews list
                          Flexible(
                            flex: 3,
                            child: Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 32),
                                  child: SizedBox(
                                    width: 525,
                                    height: 50,
                                    child: TextField(
                                      controller: _controller,
                                      decoration: InputDecoration(
                                        hintText: 'Search reviews',
                                        hintStyle: const TextStyle(fontSize: 14),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(15),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(15),
                                          borderSide: const BorderSide(
                                            color: Colors.black,
                                            width: 1.5
                                          )
                                        ),
                                        suffixIcon: _showClear 
                                          ? IconButton(
                                              icon: const Icon(Icons.close_rounded),
                                              onPressed: () {
                                                _controller.clear();
                                                setState(() {
                                                  _showClear = false;
                                                  searchQuery = '';
                                                });
                                              },
                                            )
                                          : const Icon(Icons.search_rounded)
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(
                                  width: 600,
                                  child: Divider(
                                    height: 1,
                                    thickness: 0.5,
                                  ),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 12),
                                    child: SizedBox(
                                      width: 610,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 40),
                                        child: ListView.separated(
                                          itemCount: filteredReviews.length,
                                          separatorBuilder: (_, __) => const SizedBox(height: 24),
                                          itemBuilder: (context, index) {
                                            return _buildFullReviewCard(filteredReviews[index]);
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 30)
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        );
      }
    );
  }

  Widget _buildFullReviewCard(RatingAndReview review) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color.fromARGB(255, 81, 115, 153).withOpacity(0.1),
                child: Text(
                  review.userName[0].toUpperCase(),
                  style: const TextStyle(
                    color: Color.fromARGB(255, 81, 115, 153),
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          review.userName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      review.getTimeAgo(),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              buildStarRating(review.rating, size: 20),
            ],
          ),
          
          const SizedBox(height: 12),
          
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '${review.serviceName}${review.petName != null ? ' • ${review.petName}' : ''}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          
          if (review.hasReview) ...[
            const SizedBox(height: 12),
            Text(
              review.reviewText!,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
          
          if (review.hasImages) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: review.images.length,
                itemBuilder: (context, index) {
                  final imageUrl = _authRepo.getImageUrl(review.images[index]);
                  
                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        imageUrl,
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 100,
                            height: 100,
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.image_not_supported),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}