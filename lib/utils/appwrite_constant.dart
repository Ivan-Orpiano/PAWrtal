class AppwriteConstants {
  static String endPoint = "https://cloud.appwrite.io/v1";
  static String projectID = "67ef82500017dc404c6a";
  static String dbID = "67ef839c00011ba4c465";
  static String usersCollectionID = "680f7517002e572514bc";
  static String petsCollectionID = "6810de7e001ee11cbe60";
  static String staffCollectionID = "67ef83a90017471edcd2";
  static String imageBucketID = "67ef83bd0022c1e63789";
  static String clinicsCollectionID = "680c91b500000a2cdf0d";
  static String clinicSettingsCollectionID = "6808d8c80020d54ae6ac";
  static String appointmentCollectionID = "6808d79c0026493948d1";
  static String medicalRecordsCollectionID = "68940e0f00334b37ff25";
  static String conversationsCollectionID = "68d25a3400298a84f4df";
  static String messagesCollectionID = "68d25ad3000ebd275a4e";
  static String conversationStartersCollectionID = "68d25b3d001e1bef8af8";
  static String userStatusCollectionID = "68d25b9d000b7005695c";

  static String idVerificationCollectionID = "68e74484002b415c4c9a";

  static bool get messagingCollectionsConfigured {
    return conversationsCollectionID !=
            "REPLACE_WITH_CONVERSATIONS_COLLECTION_ID" &&
        messagesCollectionID != "REPLACE_WITH_MESSAGES_COLLECTION_ID" &&
        conversationStartersCollectionID !=
            "REPLACE_WITH_STARTERS_COLLECTION_ID" &&
        userStatusCollectionID != "REPLACE_WITH_USER_STATUS_COLLECTION_ID";
  }

  // NEW: ARGOS Identity Configuration
  // Get your project ID from ARGOS Dashboard after signing up
  static String argosProjectId = "xn67l316fg";
  static String argosLiveformBaseUrl = "https://form.argosidentity.com/";
  static String argosApiBaseUrl = "https://rest-api.argosidentity.com/v3";
  static String argosApiKey = "Ow8puWfGgo62Kj8jtcOIW8NTvab7JFXC8E6Dxa47";

  // Webhook URL - This should be your backend endpoint that receives ARGOS webhooks
  // Example: https://your-backend.com/api/webhooks/argos
  static String argosWebhookUrl =
      "https://cloud.appwrite.io/v1/functions/68e775150035eb381246/executions";

  static bool get argosConfigured {
    return argosProjectId != "REPLACE_WITH_YOUR_ARGOS_PROJECT_ID" &&
        argosApiKey != "REPLACE_WITH_YOUR_ARGOS_API_KEY" &&
        argosWebhookUrl != "REPLACE_WITH_YOUR_WEBHOOK_URL";
  }
}
