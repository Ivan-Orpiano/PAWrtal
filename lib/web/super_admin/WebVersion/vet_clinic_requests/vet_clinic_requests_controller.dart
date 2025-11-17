import 'package:get/get.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/data/models/vet_clinic_registration_request_model.dart';

class VetClinicRequestsController extends GetxController {
  final AuthRepository authRepository = Get.find<AuthRepository>();

  // Observable variables
  final RxList<VetClinicRegistrationRequest> allRequests = 
      <VetClinicRegistrationRequest>[].obs;
  final RxBool isLoading = true.obs;
  final RxString errorMessage = ''.obs;
  final RxString selectedFilter = 'all'.obs; // 'all', 'pending', 'approved', 'rejected'
  final RxString searchQuery = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchRequests();
  }

  /// Fetch all registration requests
  Future<void> fetchRequests({String? status}) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final requests = await authRepository.getAllVetRegistrationRequests(
        status: status ?? (selectedFilter.value == 'all' ? null : selectedFilter.value),
      );

      allRequests.value = requests;
    } catch (e) {
      errorMessage.value = 'Failed to fetch requests: ${e.toString()}';
    } finally {
      isLoading.value = false;
    }
  }

  /// Update filter and refresh
  void updateFilter(String filter) {
    selectedFilter.value = filter;
    fetchRequests(status: filter == 'all' ? null : filter);
  }

  /// Update search query
  void updateSearchQuery(String query) {
    searchQuery.value = query.toLowerCase().trim();
  }

  /// Get filtered requests based on search and filter
  List<VetClinicRegistrationRequest> get filteredRequests {
    List<VetClinicRegistrationRequest> filtered;

    // Apply status filter
    if (selectedFilter.value == 'all') {
      filtered = List.from(allRequests);
    } else {
      filtered = allRequests
          .where((req) => req.status == selectedFilter.value)
          .toList();
    }

    // Apply search filter
    if (searchQuery.value.isNotEmpty) {
      final query = searchQuery.value;
      filtered = filtered.where((req) {
        return req.clinicName.toLowerCase().contains(query) ||
            req.email.toLowerCase().contains(query) ||
            req.barangay.toLowerCase().contains(query) ||
            req.contactNumber.contains(query);
      }).toList();
    }

    // Sort by submission date (newest first)
    filtered.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));

    return filtered;
  }

  /// Get statistics
  Map<String, int> get requestStats {
    int total = allRequests.length;
    int pending = allRequests.where((r) => r.status == 'pending').length;
    int approved = allRequests.where((r) => r.status == 'approved').length;
    int rejected = allRequests.where((r) => r.status == 'rejected').length;

    return {
      'total': total,
      'pending': pending,
      'approved': approved,
      'rejected': rejected,
    };
  }

  /// Refresh requests
  Future<void> refreshRequests() async {
    await fetchRequests();
  }
}