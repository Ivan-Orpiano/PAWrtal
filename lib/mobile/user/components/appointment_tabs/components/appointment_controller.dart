import 'package:capstone_app/data/models/appointment_model.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/utils/user_session_service.dart';
import 'package:get/get.dart';

class AppointmentController extends GetxController {
  final AuthRepository authRepository;
  final UserSessionService session;

  AppointmentController({
    required this.authRepository,
    required this.session,
  });

  var isLoading = false.obs;
  var appointments = <Appointment>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchAppointments();
  }

  Future<void> fetchAppointments() async {
    try {
      isLoading.value = true;
      final userId = session.userId;

      if (userId.isEmpty) {
        Get.snackbar("Error", "User not logged in.");
        return;
      }

      final result = await authRepository.getUserAppointments(userId);
      appointments.assignAll(result);
    } catch (e) {
      Get.snackbar("Error", "Failed to load appointments: $e");
    } finally {
      isLoading.value = false;
    }
  }

  List<Appointment> get pending =>
      appointments.where((a) => a.status == 'pending').toList();

  List<Appointment> get accepted =>
      appointments.where((a) => a.status == 'accepted').toList();

  List<Appointment> get declined =>
      appointments.where((a) => a.status == 'declined').toList();
}
