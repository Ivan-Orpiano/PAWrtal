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
  static String ratingsAndReviewsCollectionID = "ratingsandreviews";

  static bool get messagingCollectionsConfigured {
    return conversationsCollectionID != "REPLACE_WITH_CONVERSATIONS_COLLECTION_ID" &&
           messagesCollectionID != "REPLACE_WITH_MESSAGES_COLLECTION_ID" &&
           conversationStartersCollectionID != "REPLACE_WITH_STARTERS_COLLECTION_ID" &&
           userStatusCollectionID != "REPLACE_WITH_USER_STATUS_COLLECTION_ID";
  }
    static bool get ratingsAndReviewsConfigured {
    return ratingsAndReviewsCollectionID != "REPLACE_WITH_YOUR_COLLECTION_ID";
  }
}


