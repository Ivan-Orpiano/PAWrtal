import 'package:capstone_app/data/models/clinic_model.dart';
import 'package:flutter/material.dart';

class WebPictureGalleryUpdated extends StatefulWidget {
  final Clinic clinic;
  
  const WebPictureGalleryUpdated({super.key, required this.clinic});

  @override
  State<WebPictureGalleryUpdated> createState() => _WebPictureGalleryUpdatedState();
}

class _WebPictureGalleryUpdatedState extends State<WebPictureGalleryUpdated> {
  
  List<String> _getGalleryImages() {
    // For now, we'll use the clinic's main image and some placeholder images
    // In the future, you might want to add a gallery field to your Clinic model
    List<String> images = [];
    
    if (widget.clinic.image.isNotEmpty) {
      images.add(widget.clinic.image);
    }
    
    // Add some placeholder images to fill the gallery
    // You can replace these with actual clinic gallery images from your database
    List<String> placeholders = [
      'lib/images/test_image.jpg',
      'lib/images/test_image.jpg',
      'lib/images/test_image.jpg',
      'lib/images/test_image.jpg',
    ];
    
    images.addAll(placeholders);
    return images.take(5).toList(); // Limit to 5 images for the gallery layout
  }

  void _showImageDialog(String imagePath, int index) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: Stack(
            children: [
              Center(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.9,
                    maxHeight: MediaQuery.of(context).size.height * 0.8,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: imagePath.startsWith('lib/')
                        ? Image.asset(
                            imagePath,
                            fit: BoxFit.contain,
                          )
                        : Image.network(
                            imagePath,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Image.asset(
                                'lib/images/test_image.jpg',
                                fit: BoxFit.contain,
                              );
                            },
                          ),
                  ),
                ),
              ),
              Positioned(
                top: 20,
                right: 20,
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGalleryImage(String imagePath, {BorderRadius? borderRadius}) {
    return GestureDetector(
      onTap: () => _showImageDialog(imagePath, 0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: borderRadius,
        ),
        child: ClipRRect(
          borderRadius: borderRadius ?? BorderRadius.zero,
          child: imagePath.startsWith('lib/')
              ? Image.asset(
                  imagePath,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                )
              : Image.network(
                  imagePath,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  errorBuilder: (context, error, stackTrace) {
                    return Image.asset(
                      'lib/images/test_image.jpg',
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    );
                  },
                ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final images = _getGalleryImages();
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Large left box
          Flexible(
            flex: 3,
            child: Container(
              height: 520,
              child: _buildGalleryImage(
                images.isNotEmpty ? images[0] : 'lib/images/test_image.jpg',
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Middle column (2 stacked boxes)
          Flexible(
            flex: 2,
            child: Column(
              children: [
                Container(
                  height: 255,
                  margin: const EdgeInsets.only(bottom: 10),
                  child: _buildGalleryImage(
                    images.length > 1 ? images[1] : 'lib/images/test_image.jpg',
                  ),
                ),
                Container(
                  height: 255,
                  child: _buildGalleryImage(
                    images.length > 2 ? images[2] : 'lib/images/test_image.jpg',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Right column (2 stacked boxes with button)
          Flexible(
            flex: 2,
            child: Column(
              children: [
                Container(
                  height: 255,
                  margin: const EdgeInsets.only(bottom: 10),
                  child: _buildGalleryImage(
                    images.length > 3 ? images[3] : 'lib/images/test_image.jpg',
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(20),
                    ),
                  ),
                ),
                Stack(
                  children: [
                    Container(
                      height: 255,
                      child: _buildGalleryImage(
                        images.length > 4 ? images[4] : 'lib/images/test_image.jpg',
                        borderRadius: const BorderRadius.only(
                          bottomRight: Radius.circular(20),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.only(
                            bottomRight: Radius.circular(20),
                          ),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.center,
                      child: InkWell(
                        onTap: () => _showAllPhotosDialog(),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(width: 1),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.grid_view_rounded),
                              SizedBox(width: 4),
                              Text(
                                "Show all photos",
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAllPhotosDialog() {
    final images = _getGalleryImages();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)
          ),
          insetPadding: const EdgeInsets.all(40),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            height: MediaQuery.of(context).size.height * 0.8,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20)
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey, width: 0.5)
                    )
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "${widget.clinic.clinicName} - Gallery",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(20),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1,
                    ),
                    itemCount: images.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () => _showImageDialog(images[index], index),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: images[index].startsWith('lib/')
                              ? Image.asset(
                                  images[index],
                                  fit: BoxFit.cover,
                                )
                              : Image.network(
                                  images[index],
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Image.asset(
                                      'lib/images/test_image.jpg',
                                      fit: BoxFit.cover,
                                    );
                                  },
                                ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}