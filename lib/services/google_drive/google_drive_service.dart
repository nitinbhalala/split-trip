import 'dart:async';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/googleapis_auth.dart';

class GoogleDriveService {
  GoogleDriveService._();

  static const String _folderMimeType = 'application/vnd.google-apps.folder';

  /// Finds or creates a folder on Google Drive.
  static Future<String> getOrCreateFolder(drive.DriveApi driveApi, String folderName) async {
    final query = "name = '$folderName' and mimeType = '$_folderMimeType' and trashed = false";
    final fileList = await driveApi.files.list(q: query, spaces: 'drive');

    if (fileList.files != null && fileList.files!.isNotEmpty) {
      return fileList.files!.first.id!;
    }

    final folder = drive.File()
      ..name = folderName
      ..mimeType = _folderMimeType;

    final createdFolder = await driveApi.files.create(folder);
    return createdFolder.id!;
  }

  /// Uploads or replaces the backup file inside the target folder with associated metadata properties.
  static Future<drive.File> uploadOrReplaceFile({
    required AuthClient client,
    required List<int> bytes,
    required String fileName,
    required String folderName,
    required Map<String, String> appProperties,
  }) async {
    final driveApi = drive.DriveApi(client);
    final folderId = await getOrCreateFolder(driveApi, folderName);

    // Check if the file already exists in the folder
    final query = "name = '$fileName' and '$folderId' in parents and trashed = false";
    final fileList = await driveApi.files.list(q: query, spaces: 'drive');

    final media = drive.Media(Stream.value(bytes), bytes.length);

    if (fileList.files != null && fileList.files!.isNotEmpty) {
      final existingFileId = fileList.files!.first.id!;
      final updateMetadata = drive.File()..appProperties = appProperties;

      return await driveApi.files.update(
        updateMetadata,
        existingFileId,
        uploadMedia: media,
      );
    } else {
      final createMetadata = drive.File()
        ..name = fileName
        ..parents = [folderId]
        ..appProperties = appProperties;

      return await driveApi.files.create(
        createMetadata,
        uploadMedia: media,
      );
    }
  }

  /// Finds and downloads a file by name from the specified folder.
  static Future<List<int>?> downloadFile({
    required AuthClient client,
    required String fileName,
    required String folderName,
  }) async {
    final driveApi = drive.DriveApi(client);
    final folderQuery = "name = '$folderName' and mimeType = '$_folderMimeType' and trashed = false";
    final folderList = await driveApi.files.list(q: folderQuery, spaces: 'drive');

    if (folderList.files == null || folderList.files!.isEmpty) {
      return null; // Folder does not exist
    }

    final folderId = folderList.files!.first.id!;
    final fileQuery = "name = '$fileName' and '$folderId' in parents and trashed = false";
    final fileList = await driveApi.files.list(q: fileQuery, spaces: 'drive');

    if (fileList.files == null || fileList.files!.isEmpty) {
      return null; // File does not exist
    }

    final fileId = fileList.files!.first.id!;
    final drive.Media media = await driveApi.files.get(
      fileId,
      downloadOptions: drive.DownloadOptions.fullMedia,
    ) as drive.Media;

    final List<int> bytes = [];
    await for (final chunk in media.stream) {
      bytes.addAll(chunk);
    }
    return bytes;
  }

  /// Checks if a file exists inside the target folder without downloading it.
  static Future<bool> checkFileExists({
    required AuthClient client,
    required String fileName,
    required String folderName,
  }) async {
    try {
      final driveApi = drive.DriveApi(client);
      final folderQuery = "name = '$folderName' and mimeType = '$_folderMimeType' and trashed = false";
      final folderList = await driveApi.files.list(q: folderQuery, spaces: 'drive');

      if (folderList.files == null || folderList.files!.isEmpty) {
        return false;
      }

      final folderId = folderList.files!.first.id!;
      final fileQuery = "name = '$fileName' and '$folderId' in parents and trashed = false";
      final fileList = await driveApi.files.list(q: fileQuery, spaces: 'drive');

      return fileList.files != null && fileList.files!.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}

