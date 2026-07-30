class DBConstants {
  static const String databaseName = "split_trip.db";
  static const int databaseVersion = 1;

  // Table Names
  static const String categoriesTable = "categories";
  static const String profileTable = "profile";

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


}

