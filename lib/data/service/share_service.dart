import 'package:share_plus/share_plus.dart';
import 'package:split_trip/core/common/widgets/app_logger.dart';
import 'package:split_trip/core/common/widgets/app_snackbar.dart';

/// A centralized service for all share operations.
///
/// Usage:
/// ```dart
/// // Text only
/// await ShareService.shareText("Check out X1 Sports!");
///
/// // Single image from URL
/// await ShareService.shareImage("https://example.com/image.png");
///
/// // Single image with caption
/// await ShareService.shareImage("https://example.com/image.png", text: "My QR Code");
///
/// // Multiple images from URLs
/// await ShareService.shareMultipleImages([
///   "https://example.com/img1.png",
///   "https://example.com/img2.png",
/// ]);
///
/// // Local file
/// await ShareService.shareImageFile(File("/path/to/file.png"));
///
/// // Multiple local files
/// await ShareService.shareMultipleImageFiles([file1, file2]);
/// ```
class ShareService {
  ShareService._(); // prevent instantiation

  // static final Dio _dio = Dio(
  //   BaseOptions(
  //     connectTimeout: const Duration(seconds: 15),
  //     receiveTimeout: const Duration(seconds: 30),
  //   ),
  // );

  // ─── Text ─────────────────────────────────────────────────────────────────

  /// Share plain text (link, message, referral code, etc.)
  ///
  /// [text]    — the text to share (required)
  /// [subject] — optional email subject when sharing via email client
  static Future<void> shareText(String text, {String? subject}) async {
    if (text.trim().isEmpty) {
      AppSnackbar.error(message: "Nothing to share.");
      return;
    }

    try {
      await SharePlus.instance.share(ShareParams(text: text, subject: subject));
    } catch (e) {
      AppLogger.error("Could not open share sheet. $e");
      AppSnackbar.error(
        message: "Could not open share sheet. Please try again.",
      );
    }
  }

  // ─── Single image ─────────────────────────────────────────────────────────

  /// Share a single image from a **remote URL**.
  ///
  /// [url]      — remote image URL
  /// [text]     — optional caption shown alongside the image
  /// [subject]  — optional email subject
  /// [fileName] — override the saved file name (without extension)
  //   static Future<void> shareImage(
  //     String url, {
  //     String? text,
  //     String? subject,
  //     String? fileName,
  //   }) async {
  //     try {
  //       final file = await _downloadTempImage(url, fileName: fileName);
  //       await _shareFiles([file], text: text, subject: subject);
  //     } on ShareServiceException catch (e) {
  //       AppSnackbar.error(message:  e.message);
  //     } catch (_) {
  //       AppSnackbar.error(message:  "Failed to share image. Please try again.");
  //     }
  //   }

  //   /// Share a single image from an already-downloaded **[File]**.
  //   ///
  //   /// [file]    — local image file
  //   /// [text]    — optional caption
  //   /// [subject] — optional email subject
  //   static Future<void> shareImageFile(
  //     File file, {
  //     String? text,
  //     String? subject,
  //   }) async {
  //     if (!file.existsSync()) {
  //       AppSnackbar.error("Image file not found.");
  //       return;
  //     }

  //     try {
  //       await _shareFiles([file], text: text, subject: subject);
  //     } catch (_) {
  //       AppSnackbar.error("Could not share image. Please try again.");
  //     }
  //   }

  //   /// Share a single image from raw **[Uint8List]** bytes.
  //   ///
  //   /// [bytes]    — image bytes (e.g. from a rendered QR code)
  //   /// [text]     — optional caption
  //   /// [subject]  — optional email subject
  //   /// [fileName] — override the saved file name (without extension)
  //   static Future<void> shareImageBytes(
  //     Uint8List bytes, {
  //     String? text,
  //     String? subject,
  //     String? fileName,
  //   }) async {
  //     try {
  //       final file = await _saveBytesToTemp(bytes, fileName: fileName);
  //       await _shareFiles([file], text: text, subject: subject);
  //     } catch (_) {
  //       AppSnackbar.error("Could not share image. Please try again.");
  //     }
  //   }

  //   // ─── Multiple images ──────────────────────────────────────────────────────

  //   /// Share multiple images from a list of **remote URLs**.
  //   ///
  //   /// Downloads all images concurrently before opening the share sheet.
  //   ///
  //   /// [urls]     — list of remote image URLs
  //   /// [text]     — optional caption shown alongside the images
  //   /// [subject]  — optional email subject
  //   static Future<void> shareMultipleImages(
  //     List<String> urls, {
  //     String? text,
  //     String? subject,
  //   }) async {
  //     if (urls.isEmpty) {
  //       AppSnackbar.error("No images to share.");
  //       return;
  //     }

  //     try {
  //       // Download all concurrently
  //       final files = await Future.wait(
  //         urls.map((url) => _downloadTempImage(url)),
  //       );
  //       await _shareFiles(files, text: text, subject: subject);
  //     } on ShareServiceException catch (e) {
  //       AppSnackbar.error(e.message);
  //     } catch (_) {
  //       AppSnackbar.error("Failed to share images. Please try again.");
  //     }
  //   }

  //   /// Share multiple images from already-downloaded **[File]** objects.
  //   ///
  //   /// [files]   — list of local image files
  //   /// [text]    — optional caption
  //   /// [subject] — optional email subject
  //   static Future<void> shareMultipleImageFiles(
  //     List<File> files, {
  //     String? text,
  //     String? subject,
  //   }) async {
  //     final existing = files.where((f) => f.existsSync()).toList();

  //     if (existing.isEmpty) {
  //       AppSnackbar.error("No valid image files found.");
  //       return;
  //     }

  //     try {
  //       await _shareFiles(existing, text: text, subject: subject);
  //     } catch (_) {
  //       AppSnackbar.error("Could not share images. Please try again.");
  //     }
  //   }

  //   // ─── Private helpers ──────────────────────────────────────────────────────

  //   /// Core share call — converts [File]s to [XFile]s and opens the share sheet.
  //   // static Future<void> _shareFiles(
  //   //   List<File> files, {
  //   //   String? text,
  //   //   String? subject,
  //   // }) async {
  //   //   final xFiles = files.map((f) => XFile(f.path)).toList();
  //   //   await SharePlus.instance.share(
  //   //     ShareParams(files: xFiles, text: text, subject: subject),
  //   //   );
  //   }

  //   /// Downloads a remote image to the temp directory and returns the [File].
  //   ///
  //   /// Throws [ShareServiceException] on non-2xx HTTP status or network error.
  //   // static Future<File> _downloadTempImage(String url, {String? fileName}) async {
  //   //   try {
  //   //     final response = await _dio.get<List<int>>(
  //   //       url,
  //   //       options: Options(
  //   //         responseType: ResponseType.bytes,
  //   //         followRedirects: true,
  //   //         validateStatus: (status) => status != null && status < 500,
  //   //       ),
  //   //     );

  //   //     if (response.statusCode == null || response.statusCode! >= 400) {
  //   //       throw ShareServiceException(
  //   //         "Image could not be downloaded (HTTP ${response.statusCode}).",
  //   //       );
  //   //     }

  //   //     if (response.data == null || response.data!.isEmpty) {
  //   //       throw ShareServiceException("Downloaded image data is empty.");
  //   //     }

  //   //     final bytes = Uint8List.fromList(response.data!);
  //   //     return _saveBytesToTemp(bytes, fileName: fileName);
  //   //   } on DioException catch (e) {
  //   //     throw ShareServiceException(_dioErrorMessage(e));
  //   //   }
  //   // }

  //   /// Writes [bytes] to a temp file and returns it.
  // //   static Future<File> _saveBytesToTemp(
  // //     Uint8List bytes, {
  // //     String? fileName,
  // //   }) async {
  // //     final tempDir = await getTemporaryDirectory();
  // //     final name = fileName ?? 'share_${DateTime.now().millisecondsSinceEpoch}';
  // //     final file = File('${tempDir.path}/$name.png');
  // //     await file.writeAsBytes(bytes);
  // //     return file;
  // //   }

  // //   /// Maps common [DioException] types to user-friendly messages.
  // //   static String _dioErrorMessage(DioException e) {
  // //     switch (e.type) {
  // //       case DioExceptionType.connectionTimeout:
  // //       case DioExceptionType.sendTimeout:
  // //       case DioExceptionType.receiveTimeout:
  // //         return "Image download timed out. Check your connection.";
  // //       case DioExceptionType.connectionError:
  // //         return "No internet connection.";
  // //       default:
  // //         return "Image download failed. Please try again.";
  // //     }
  // //   }
}

// // ─── Exception ────────────────────────────────────────────────────────────────

class ShareServiceException implements Exception {
  const ShareServiceException(this.message);
  final String message;
  @override
  String toString() => 'ShareServiceException: $message';
}
