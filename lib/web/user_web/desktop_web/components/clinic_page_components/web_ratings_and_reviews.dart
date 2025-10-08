import 'package:capstone_app/web/dimensions.dart';
import 'package:flutter/material.dart';
import '../dashboard_components/web_review_card.dart';

Widget buildStarRating(double rating, {double size = 30}) {
  return Row(
    children: List.generate(5, (index) {
      double starFill = (rating - index).clamp(0.0, 1.0); // between 0.0 and 1.0
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
  const WebRatingsAndReviews({super.key});

  @override
  State<WebRatingsAndReviews> createState() => _WebRatingsAndReviewsState();
}

class _WebRatingsAndReviewsState extends State<WebRatingsAndReviews> {
  final bool _showAllReviews = false;
  final List<Review> reviews = [
    Review(
      userName: 'Juan',
      profileImageUrl: 'https://images.unsplash.com/photo-1508672019048-805c876b67e2', 
      rating: 5,
      comment: 'Amazing experience! The service was excellent and I really felt valued. Definitely recommend to everyone.'
    ),
    Review(
      userName: 'Will',
      profileImageUrl: 'https://images.unsplash.com/photo-1517841905240-472988babdf9',
      rating: 4,
      comment: 'Very good overall. A few small things could be improved, but I’m still satisfied.'
    ),
    Review(
      userName: 'Smith',
      profileImageUrl: 'https://images.unsplash.com/photo-1517423440428-a5a00ad493e8',
      rating: 3,
      comment: 'It was okay. Not bad, but nothing too special either. Average experience.'
    ),
    Review(
      userName: 'Wally',
      profileImageUrl: 'https://images.unsplash.com/photo-1543852786-1cf6624b9987',
      rating: 2,
      comment: 'Honestly not the best. I expected more, and a few things really need improvement.'
    ),
    Review(
      userName: 'Brian',
      profileImageUrl: 'https://images.unsplash.com/photo-1487412912498-0447578fcca8',
      rating: 1.5,
      comment: 'Pretty disappointing. The experience didn’t meet my expectations at all.'
    ),
    Review(
      userName: 'Mia',
      profileImageUrl: 'https://images.unsplash.com/photo-1529626455594-4ff0802cfb7e',
      rating: 5,
      comment: 'Perfect! I had such a great time, everything went smoothly and exceeded my expectations.'
    ),
  ];

  Map<int, double> calculateRatingPercentages() {
    Map <int, int> counts = {1:0, 2:0, 3:0, 4:0, 5:0};

    for (var review in reviews) {
      counts[review.rating.round()] = counts[review.rating.round()]! + 1;
    }

    final total = reviews.length;
    if (total == 0) {
      return {1:0, 2:0, 3:0, 4:0, 5:0 };
    }
    return counts.map((key, value) => MapEntry (key,value / total));
  }
  
  double calculateAverageRating() {
    if (reviews.isEmpty) return 0;
    double total = reviews.fold (0, (sum, item) => sum + item.rating);
    return total / reviews.length;
  }

  final TextEditingController _controller = TextEditingController();
  bool _showClear = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() {
        _showClear = _controller.text.isNotEmpty;
      });
    });
  }

  double responsiveDialogWidth (BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

  if (screenWidth >= tabletWidth) {
    // Desktop
    return 1020;
  } else {
    // Tablet and below
    return screenWidth * 0.9;
  }
}

  @override
  Widget build(BuildContext context) {
    double averageRating = calculateAverageRating();
    Map<int, double> ratingPercentages = calculateRatingPercentages();

    return Column(
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
            Row(
              children: [
                Text(
                  "${averageRating.toStringAsFixed(2)} / 5",
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
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: (ratingPercentages.entries.toList()
            ..sort((a, b) => b.key.compareTo(a.key)))
            .map((entry)  {
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
          itemCount: reviews.length > 5 ? 5: reviews.length,
          separatorBuilder: (context, index) => const SizedBox(height: 24),
          itemBuilder: (context, index) {
            final review = reviews[index];
            return WebReviewCard(review: review);
          },
        ),
        const SizedBox(height: 32),
        GestureDetector(
          onTap: () {
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
                                onTap: () {
                                  Navigator.pop(context);
                                },
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
                                  Flexible(
                                    flex: 2,
                                    child: Column(
                                      spacing: 28,
                                      children: [
                                        Text(
                                          averageRating.toStringAsFixed(2),
                                          style: const TextStyle(
                                            fontSize: 48,
                                            fontWeight: FontWeight.bold
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            const Spacer(),
                                            buildStarRating(averageRating),
                                            const Spacer(),
                                          ],
                                        ),
                                        const SizedBox(
                                          width: 300,
                                          child: Divider(
                                            height: 1,
                                            thickness: 0.5,
                                          ),
                                        ),
                                        Text(
                                          "${reviews.length} reviews",
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w600 
                                          ),
                                        ),
                                        const SizedBox(
                                          width: 300,
                                          child: Divider(
                                            height: 1,
                                            thickness: 0.5,
                                          ),
                                        ),
                                        Column(
                                          children: [
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
                                                padding: const EdgeInsets.only(top: 16.0), // Optional spacing from above elements
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
                                      ],
                                    ),
                                  ),
                            
                                  const SizedBox(width: 32),
                            
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
                                              onTap: () {
                                                setState(() {
                                                  _showClear = _controller.text.isNotEmpty;
                                                });
                                              },
                                              decoration: InputDecoration(
                                                hintText: 'Search reviews',
                                                hintStyle: const TextStyle(
                                                  fontSize: 14
                                                ),
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
                                                    });
                                                  },
                                                )
                                                : const Icon(Icons.search_rounded)
                                              )
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
                                              height: 500,
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 40),
                                                child: ListView.separated(
                                                  itemCount: reviews.length,
                                                  separatorBuilder: (_, ___) => const SizedBox (height: 24),
                                                  itemBuilder: (context, index) {
                                                    return WebReviewCard(review: reviews[index]);
                                                  },
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 30,)
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
          },
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                    color: Colors.black,
                  )
                ),
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
}
