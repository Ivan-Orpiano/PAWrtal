import 'package:capstone_app/utils/appwrite_constant.dart';

String getPetImageUrl(String? imageId) {
  if (imageId != null && imageId.isNotEmpty) {
    return '${AppwriteConstants.endPoint}/storage/buckets/${AppwriteConstants.imageBucketID}/files/$imageId/view?project=${AppwriteConstants.projectID}';
  }
  return 'assets/images/placeholder.png'; // fallback to asset
}
