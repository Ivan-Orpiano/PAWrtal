import 'package:capstone_app/mobile/super_admin/WebVersion/vet_clinic_pages/vet_clinic_components/vet_clinic_dashboard/vet_review_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

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

class VetProfileRatingReview extends StatefulWidget {
  const VetProfileRatingReview({super.key});

  @override
  State<VetProfileRatingReview> createState() => _VetProfileRatingReviewState();
}

class _VetProfileRatingReviewState extends State<VetProfileRatingReview> {
  final bool _showAllReviews = false;
  final List<Review> reviews = [
    Review(
        userName: 'Mike',
        profileImageUrl:
            'https://cdn.prod.website-files.com/62bdc93e9cccfb43e155104c/66f106a855c31c342d2e1b40_Skeleton%20PFP%20400x400%20(7).png',
        rating: 5,
        comment: 'Hindi na makalaya'),
    Review(
        userName: 'David',
        profileImageUrl:
            'https://cdn.prod.website-files.com/62bdc93e9cccfb43e155104c/66f106a855c31c342d2e1b40_Skeleton%20PFP%20400x400%20(7).png',
        rating: 4,
        comment: 'Dinadalaw mo ' 'ko bawat gabi'),
    Review(
        userName: 'Ivan',
        profileImageUrl:
            'https://cdn.prod.website-files.com/62bdc93e9cccfb43e155104c/66f106a855c31c342d2e1b40_Skeleton%20PFP%20400x400%20(7).png',
        rating: 3,
        comment: 'Wala mang nakikita'),
    Review(
        userName: 'Dave',
        profileImageUrl:
            'https://cdn.prod.website-files.com/62bdc93e9cccfb43e155104c/66f106a855c31c342d2e1b40_Skeleton%20PFP%20400x400%20(7).png',
        rating: 2,
        comment: 'Haplos mo' 'y ramdam pa rin sa dilim'),
    Review(
        userName: 'Lenard',
        profileImageUrl:
            'https://cdn.prod.website-files.com/62bdc93e9cccfb43e155104c/66f106a855c31c342d2e1b40_Skeleton%20PFP%20400x400%20(7).png',
        rating: 1.5,
        comment: 'Hindi na na-nanaginip'),
    Review(
        userName: 'Lenard',
        profileImageUrl:
            'https://cdn.prod.website-files.com/62bdc93e9cccfb43e155104c/66f106a855c31c342d2e1b40_Skeleton%20PFP%20400x400%20(7).png',
        rating: 5,
        comment: 'Hindi na na-nanaginip'),
  ];

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

  double calculateAverageRating() {
    if (reviews.isEmpty) return 0;
    double total = reviews.fold(0, (sum, item) => sum + item.rating);
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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            Row(
              children: [
                Text(
                  "${averageRating.toStringAsFixed(2)} / 5",
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w600),
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
                .map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Text(
                      entry.key.toString(),
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600),
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
          itemCount: reviews.length > 5 ? 5 : reviews.length,
          separatorBuilder: (context, index) => const SizedBox(height: 24),
          itemBuilder: (context, index) {
            final review = reviews[index];
            return VetProfileReviewCard(review: review);
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
                        borderRadius: BorderRadius.circular(20)),
                    insetPadding: const EdgeInsets.symmetric(vertical: 60),
                    child: Container(
                      width: 1020,
                      height: 700,
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20)),
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
                            Container(
                              padding: const EdgeInsets.only(left: 42),
                              child: Row(
                                children: [
                                  Column(
                                    spacing: 28,
                                    children: [
                                      Text(
                                        averageRating.toStringAsFixed(2),
                                        style: const TextStyle(
                                            fontSize: 48,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      buildStarRating(averageRating),
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
                                            fontWeight: FontWeight.w600),
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
                                                fontWeight: FontWeight.w600),
                                          ),
                                          SizedBox(
                                            height: 200,
                                            width: 300,
                                            child: Padding(
                                              padding: const EdgeInsets.only(
                                                  top:
                                                      16.0), // Optional spacing from above elements
                                              child: Column(
                                                children: (ratingPercentages
                                                        .entries
                                                        .toList()
                                                      ..sort((a, b) => b.key
                                                          .compareTo(a.key)))
                                                    .map((entry) {
                                                  return Padding(
                                                    padding: const EdgeInsets
                                                        .symmetric(vertical: 4),
                                                    child: Row(
                                                      children: [
                                                        Text(
                                                          entry.key.toString(),
                                                          style:
                                                              const TextStyle(
                                                            fontSize: 16,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            width: 8),
                                                        Expanded(
                                                          child: Stack(
                                                            children: [
                                                              Container(
                                                                height: 8,
                                                                decoration:
                                                                    BoxDecoration(
                                                                  color: Colors
                                                                          .grey[
                                                                      300],
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              4),
                                                                ),
                                                              ),
                                                              FractionallySizedBox(
                                                                widthFactor:
                                                                    entry.value,
                                                                child:
                                                                    Container(
                                                                  height: 8,
                                                                  decoration:
                                                                      BoxDecoration(
                                                                    color: Colors
                                                                        .black,
                                                                    borderRadius:
                                                                        BorderRadius
                                                                            .circular(4),
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
                                  const SizedBox(width: 32),
                                  Column(
                                    children: [
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 32),
                                        child: SizedBox(
                                          width: 525,
                                          height: 50,
                                          child: TextField(
                                              controller: _controller,
                                              onTap: () {
                                                setState(() {
                                                  _showClear = _controller
                                                      .text.isNotEmpty;
                                                });
                                              },
                                              decoration: InputDecoration(
                                                  hintText: 'Search reviews',
                                                  hintStyle: const TextStyle(
                                                      fontSize: 14),
                                                  border: OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            15),
                                                  ),
                                                  focusedBorder:
                                                      OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(15),
                                                          borderSide:
                                                              const BorderSide(
                                                                  color: Colors
                                                                      .black,
                                                                  width: 1.5)),
                                                  suffixIcon: _showClear
                                                      ? IconButton(
                                                          icon: const Icon(Icons
                                                              .close_rounded),
                                                          onPressed: () {
                                                            _controller.clear();
                                                            setState(() {
                                                              _showClear =
                                                                  false;
                                                            });
                                                          },
                                                        )
                                                      : const Icon(Icons
                                                          .search_rounded))),
                                        ),
                                      ),
                                      const SizedBox(
                                        width: 600,
                                        child: Divider(
                                          height: 1,
                                          thickness: 0.5,
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(top: 12),
                                        child: SizedBox(
                                          width: 610,
                                          height: 500,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 40),
                                            child: ListView.separated(
                                              itemCount: reviews.length,
                                              separatorBuilder: (_, ___) =>
                                                  const SizedBox(height: 24),
                                              itemBuilder: (context, index) {
                                                final review = reviews[index];
                                                return Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Expanded(
                                                      child:
                                                          VetProfileReviewCard(
                                                              review: review),
                                                    ),
                                                    IconButton(
                                                      icon: const Icon(
                                                          Icons
                                                              .delete_outline_rounded,
                                                          color: Colors.grey),
                                                      onPressed: () {
                                                        // logic ng delete
                                                      },
                                                    ),
                                                  ],
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  );
                });
          },
          child: Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                      color: Colors.black,
                    )),
                child: Text(
                  "Show all ${reviews.length} reviews",
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        )
      ],
    );
  }
}
