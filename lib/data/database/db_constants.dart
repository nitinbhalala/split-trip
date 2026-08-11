class DBConstants {
  static const String databaseName = "split_trip.db";
  static const int databaseVersion = 5;

  // Table Names
  static const String categoriesTable = "categories";
  static const String profileTable = "profile";
  static const String groupsTable = "groups";
  static const String groupMembersTable = "group_members";
  static const String groupMessagesTable = "group_messages";

  // Common Columns
  static const String id = "id";
  static const String createdAt = "created_at";
  static const String updatedAt = "updated_at";

  // Profile Columns
  static const String profileId = "id";
  static const String profileFirstName = "first_name";
  static const String profileLastName = "last_name";
  static const String profileEmail = "email";
  static const String profilePicture = "profile_picture";
  static const String profileSelectedCurrency = "selected_currency";

  // Categories Columns
  static const String categoryName = "name";
  static const String categoryIconName = "icon_name";
  static const String categoryColorValue = "color_value";

  // Groups Columns
  static const String groupName = "name";
  static const String groupDescription = "description";
  static const String groupIconName = "icon_name";
  static const String groupColorValue = "color_value";
  static const String groupImagePath = "image_path";

  // Group Members Columns
  static const String memberGroupId = "group_id";
  static const String memberName = "name";
  static const String memberPhone = "phone";

  // Group Messages Columns
  static const String msgGroupId = "group_id";
  static const String msgSenderName = "sender_name";
  static const String msgText = "message_text";
  static const String msgAmount = "amount";
  static const String msgIsExpense = "is_expense";
}

