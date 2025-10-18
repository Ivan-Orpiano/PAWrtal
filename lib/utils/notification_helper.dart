// import 'package:capstone_app/data/models/notification_model.dart';
// import 'package:capstone_app/data/models/appointment_model.dart';
// import 'package:capstone_app/data/repository/auth.repository.dart';
// import 'package:get/get.dart';

// class NotificationHelper {
//   static final AuthRepository _authRepository = Get.find<AuthRepository>();

//   /// Create appointment notification for both admin and user
//   static Future<void> createAppointmentNotification({
//     required String type,
//     required Appointment appointment,
//     required String clinicName,
//     required String petName,
//     required String ownerName,
//     String? notes,
//   }) async {
//     try {
//       switch (type) {
//         case 'booked':
//           // Only notify admin when user books
//           await _createAdminAppointmentNotification(
//             type: type,
//             appointment: appointment,
//             clinicName: clinicName,
//             petName: petName,
//             ownerName: ownerName,
//             notes: notes,
//           );
//           break;
        
//         case 'accepted':
//         case 'declined':
//         case 'completed':
//           // Only notify user for status updates
//           await _createUserAppointmentNotification(
//             type: type,
//             appointment: appointment,
//             clinicName: clinicName,
//             petName: petName,
//             ownerName: ownerName,
//             notes: notes,
//           );
//           break;
          
//         case 'cancelled':
//           if (appointment.cancelledBy == 'user') {
//             // User cancelled - notify admin
//             await _createAdminAppointmentNotification(
//               type: type,
//               appointment: appointment,
//               clinicName: clinicName,
//               petName: petName,
//               ownerName: ownerName,
//               notes: notes,
//             );
//           } else {
//             // Admin cancelled - notify user
//             await _createUserAppointmentNotification(
//               type: type,
//               appointment: appointment,
//               clinicName: clinicName,
//               petName: petName,
//               ownerName: ownerName,
//               notes: notes,
//             );
//           }
//           break;
//       }
//     } catch (e) {
//       print('Error creating appointment notification: $e');
//     }
//   }

//   static Future<void> _createAdminAppointmentNotification({
//     required String type,
//     required Appointment appointment,
//     required String clinicName,
//     required String petName,
//     required String ownerName,
//     String? notes,
//   }) async {
//     NotificationModel notification;

//     switch (type) {
//       case 'booked':
//         notification = NotificationModel.appointmentBooked(
//           clinicId: appointment.clinicId,
//           appointmentId: appointment.documentId!,
//           userId: appointment.userId,
//           petName: petName,
//           ownerName: ownerName,
//           service: appointment.service,
//           appointmentTime: appointment.dateTime,
//         );
//         break;
      
//       case 'cancelled':
//         notification = NotificationModel(
//           recipientId: appointment.clinicId,
//           recipientType: 'admin',
//           type: NotificationType.appointmentCancelled,
//           title: 'Appointment Cancelled by User',
//           message: '$ownerName cancelled appointment for $petName',
//           appointmentId: appointment.documentId,
//           userId: appointment.userId,
//           data: {
//             'petName': petName,
//             'ownerName': ownerName,
//             'service': appointment.service,
//             'cancellationReason': notes,
//           },
//         );
//         break;
      
//       default:
//         return;
//     }

//     await _authRepository.createNotification(notification);
//   }

//   static Future<void> _createUserAppointmentNotification({
//     required String type,
//     required Appointment appointment,
//     required String clinicName,
//     required String petName,
//     required String ownerName,
//     String? notes,
//   }) async {
//     final notification = NotificationModel.appointmentStatusUpdate(
//       userId: appointment.userId,
//       appointmentId: appointment.documentId!,
//       petName: petName,
//       clinicName: clinicName,
//       status: type,
//       notes: notes,
//     );

//     await _authRepository.createNotification(notification);
//   }

//   /// Create message notification
//   static Future<void> createMessageNotification({
//     required String conversationId,
//     required String messageId,
//     required String senderId,
//     required String receiverId,
//     required String senderName,
//     required String messageText,
//     required String senderType,
//   }) async {
//     try {
//       NotificationModel notification;

//       if (senderType == 'admin') {
//         // Admin sent message to user
//         notification = NotificationModel.newMessage(
//           clinicId: senderId,
//           conversationId: conversationId,
//           messageId: messageId,
//           userId: receiverId,
//           senderName: senderName,
//           messagePreview: messageText.length > 50
//               ? '${messageText.substring(0, 50)}...'
//               : messageText,
//         ).copyWith(
//           recipientId: receiverId,
//           recipientType: 'user',
//         );
//       } else {
//         // User sent message to admin
//         notification = NotificationModel.newMessage(
//           clinicId: receiverId,
//           conversationId: conversationId,
//           messageId: messageId,
//           userId: senderId,
//           senderName: senderName,
//           messagePreview: messageText.length > 50
//               ? '${messageText.substring(0, 50)}...'
//               : messageText,
//         );
//       }

//       await _authRepository.createNotification(notification);
//     } catch (e) {
//       print('Error creating message notification: $e');
//     }
//   }
// }