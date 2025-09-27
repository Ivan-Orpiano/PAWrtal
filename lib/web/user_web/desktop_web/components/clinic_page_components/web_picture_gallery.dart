import 'package:capstone_app/data/models/clinic_model.dart';
import 'package:capstone_app/data/models/clinic_settings_model.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class WebPictureGalleryUpdated extends StatefulWidget {
  final Clinic clinic;
  
  const WebPictureGalleryUpdated({super.key, required this.clinic});

  @override
  State<WebPictureGalleryUpdated> createState() => _WebPictureGalleryUpdatedState();
}

class _WebPictureGalleryUpdatedState extends State<WebPictureGalleryUpdated> {
  List<String> _galleryImages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadClinicGallery();
  }

  Future<void> _loadClinicGallery() async {
    try {
      // Try to get gallery from clinic settings first
      final authRepository = Get.find<AuthRepository>();
      final clinicSettings = await authRepository.getClinicSettingsByClinicId(widget.clinic.documentId ?? '');
      
      if (clinicSettings != null && clinicSettings.gallery.isNotEmpty) {
        setState(() {
          _galleryImages = clinicSettings.gallery;
          _isLoading = false;
        });
      } else {
        // Fallback to default images with clinic's main image
        setState(() {
          _galleryImages = _getDefaultGalleryImages();
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error loading clinic gallery: $e");
      setState(() {
        _galleryImages = _getDefaultGalleryImages();
        _isLoading = false;
      });
    }
  }
  
  List<String> _getDefaultGalleryImages() {
    List<String> images = [];
    
    if (widget.clinic.image.isNotEmpty) {
      images.add(widget.clinic.image);
    }
    
    // Add placeholder images if no gallery is set
    List<String> placeholders = [
      'lib/images/placeholder.png',
      'lib/images/placeholder.png',
      'lib/images/placeholder.png',
      'lib/images/placeholder.png',
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
                    child: _buildImage(imagePath, BoxFit.contain),
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

  Widget _buildImage(String imagePath, BoxFit fit) {
    if (imagePath.startsWith('lib/')) {
      return Image.asset(
        imagePath,
        fit: fit,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[200],
            child: const Icon(Icons.error, size: 50),
          );
        },
      );
    } else {
      return Image.network(
        imagePath,
        fit: fit,
        width: double.infinity,
        height: double.infinity,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: Colors.grey[200],
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded / 
                      loadingProgress.expectedTotalBytes!
                    : null,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Image.asset(
            'lib/images/placeholder.png',
            fit: fit,
            width: double.infinity,
            height: double.infinity,
          );
        },
      );
    }
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
          child: _buildImage(imagePath, BoxFit.cover),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        height: 520,
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_galleryImages.isEmpty) {
      return Container(
        height: 520,
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.photo_library_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  "No gallery images available",
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Large left box
          Flexible(
            flex: 3,
            child: SizedBox(
              height: 520,
              child: _buildGalleryImage(
                _galleryImages[0],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Middle column (2 stacked boxes)
          if (_galleryImages.length > 1)
          Flexible(
            flex: 2,
            child: Column(
              children: [
                Container(
                  height: 255,
                  margin: const EdgeInsets.only(bottom: 10),
                  child: _buildGalleryImage(_galleryImages[1]),
                ),
                if (_galleryImages.length > 2)
                SizedBox(
                  height: 255,
                  child: _buildGalleryImage(_galleryImages[2]),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Right column (2 stacked boxes with button)
          if (_galleryImages.length > 3)
          Flexible(
            flex: 2,
            child: Column(
              children: [
                Container(
                  height: 255,
                  margin: const EdgeInsets.only(bottom: 10),
                  child: _buildGalleryImage(
                    _galleryImages[3],
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(20),
                    ),
                  ),
                ),
                Stack(
                  children: [
                    SizedBox(
                      height: 255,
                      child: _buildGalleryImage(
                        _galleryImages.length > 4 ? _galleryImages[4] : _galleryImages[3],
                        borderRadius: const BorderRadius.only(
                          bottomRight: Radius.circular(20),
                        ),
                      ),
                    ),
                    if (_galleryImages.length > 4)
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
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.grid_view_rounded),
                              const SizedBox(width: 4),
                              Text(
                                _galleryImages.length > 5 
                                    ? "Show all ${_galleryImages.length} photos"
                                    : "Show all photos",
                                style: const TextStyle(fontWeight: FontWeight.w600),
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
                        "${widget.clinic.clinicName} - Gallery (${_galleryImages.length} photos)",
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
                    itemCount: _galleryImages.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () => _showImageDialog(_galleryImages[index], index),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: _buildImage(_galleryImages[index], BoxFit.cover),
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