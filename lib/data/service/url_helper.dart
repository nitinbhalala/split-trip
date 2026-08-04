import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class UrlHelper {
  static bool isYoutubeUrl(String url) {
    final uri = Uri.tryParse(url);

    if (uri == null) return false;

    final host = uri.host.toLowerCase();
    final path = uri.path.toLowerCase();

    return host.contains('youtube.com') ||
        host.contains('youtu.be') ||
        host.contains('youtube-nocookie.com') ||
        path.contains('/watch') ||
        path.contains('/shorts/') ||
        path.contains('/live/') ||
        path.contains('/embed/');
  }

  static Future<bool> launchAnyUrl(String url) async {
    if (url.trim().isEmpty) return false;
    String cleanedUrl = url.trim().replaceAll(" ", "");
    try {
      if (!cleanedUrl.contains("://")) {
        cleanedUrl = "https://$cleanedUrl";
      }
      final Uri uri = Uri.parse(cleanedUrl);
      final bool launched = await launchUrl(
        uri,
        mode: LaunchMode.platformDefault,
      );
      return launched;
    } catch (e) {
      return false;
    }
  }

  static Future<void> closeWebView() async {
    try {
      await closeInAppWebView();
    } catch (e) {
      await SystemNavigator.pop();
    }
  }

  // 📞 Most compatible dialer launch
  static Future<void> openDialPad(String phoneNumber) async {
    try {
      final Uri uri = Uri(scheme: 'tel', path: phoneNumber);

      await launchUrl(uri, mode: LaunchMode.platformDefault);
      // ignore: empty_catches
    } catch (e) {}
  }

  static Future<void> launchEmail(String email) async {
    final Uri emailUri = Uri(scheme: 'mailto', path: email);

    try {
      final bool launched = await launchUrl(
        emailUri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        // fallback example
        Clipboard.setData(ClipboardData(text: email));
      }
      // ignore: empty_catches
    } catch (e) {}
  }
}

class SocialHelper {
  /// Universal launcher
  static Future<void> _launch({
    required Uri nativeUri,
    required Uri webUri,
    Uri? alternativeUri,
  }) async {
    try {
      if (await canLaunchUrl(nativeUri)) {
        await launchUrl(nativeUri, mode: LaunchMode.externalApplication);
        return;
      }

      if (alternativeUri != null && await canLaunchUrl(alternativeUri)) {
        await launchUrl(alternativeUri, mode: LaunchMode.externalApplication);
        return;
      }

      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    } catch (e) {
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    }
  }

  // ============================
  // FACEBOOK
  // ============================
  static Future<void> openFacebook(String input) async {
    String value = input.trim().replaceAll('@', '');

    Uri webUri;
    Uri nativeUri;

    if (value.startsWith("http")) {
      webUri = Uri.parse(value);
      nativeUri = Uri.parse("fb://facewebmodal/f?href=$value");
    } else if (RegExp(r'^[0-9]+$').hasMatch(value)) {
      webUri = Uri.parse("https://www.facebook.com/$value");
      nativeUri = Uri.parse("fb://profile/$value");
    } else {
      webUri = Uri.parse("https://www.facebook.com/$value");
      nativeUri = Uri.parse(
        "fb://facewebmodal/f?href=https://www.facebook.com/$value",
      );
    }

    await _launch(nativeUri: nativeUri, webUri: webUri);
  }

  // ============================
  // INSTAGRAM
  // ============================
  static Future<void> openInstagram(String input) async {
    String username = input.trim().replaceAll('@', '');

    Uri nativeUri = Uri.parse("instagram://user?username=$username");

    Uri alternativeUri = Uri.parse("https://instagram.com/_u/$username");

    Uri webUri = Uri.parse("https://www.instagram.com/$username");

    await _launch(
      nativeUri: nativeUri,
      alternativeUri: alternativeUri,
      webUri: webUri,
    );
  }

  // ============================
  // TWITTER / X
  // ============================
  static Future<void> openTwitter(String input) async {
    String username = input.trim().replaceAll('@', '');

    Uri nativeUri = Uri.parse("twitter://user?screen_name=$username");

    Uri alternativeUri = Uri.parse("https://twitter.com/$username");

    Uri webUri = Uri.parse("https://twitter.com/$username");

    await _launch(
      nativeUri: nativeUri,
      alternativeUri: alternativeUri,
      webUri: webUri,
    );
  }

  // ============================
  // LINKEDIN
  // ============================
  static Future<void> openLinkedIn(String input) async {
    String value = input.trim().replaceAll('@', '');

    Uri nativeUri;
    Uri webUri;

    if (value.startsWith("http")) {
      webUri = Uri.parse(value);

      if (value.contains("/company/")) {
        final slug = value.split("/company/").last.split("/").first;
        nativeUri = Uri.parse("linkedin://company/$slug");
      } else if (value.contains("/in/")) {
        final slug = value.split("/in/").last.split("/").first;
        nativeUri = Uri.parse("linkedin://in/$slug");
      } else {
        nativeUri = webUri;
      }
    } else {
      webUri = Uri.parse("https://www.linkedin.com/in/$value");

      nativeUri = Uri.parse("linkedin://in/$value");
    }

    await _launch(nativeUri: nativeUri, webUri: webUri);
  }

  // ============================
  // YOUTUBE
  // ============================
  static Future<void> openYouTube(String input) async {
    String value = input.trim();

    Uri nativeUri;
    Uri webUri;

    if (value.startsWith("http")) {
      webUri = Uri.parse(value);

      // Extract video ID or channel ID from URL
      if (value.contains("youtube.com/watch?v=")) {
        final videoId = value.split("v=").last.split("&").first;
        nativeUri = Uri.parse("youtube://watch?v=$videoId");
      } else if (value.contains("youtu.be/")) {
        final videoId = value.split("youtu.be/").last.split("?").first;
        nativeUri = Uri.parse("youtube://watch?v=$videoId");
      } else if (value.contains("youtube.com/channel/")) {
        final channelId = value.split("channel/").last.split("/").first;
        nativeUri = Uri.parse("youtube://channel/$channelId");
      } else if (value.contains("youtube.com/c/")) {
        final customName = value.split("c/").last.split("/").first;
        nativeUri = Uri.parse("youtube://user/$customName");
      } else if (value.contains("youtube.com/@")) {
        final handle = value.split("@").last.split("/").first;
        nativeUri = Uri.parse("youtube://user/$handle");
      } else {
        nativeUri = webUri;
      }
    } else if (value.startsWith("@")) {
      // Handle @username format
      final username = value.substring(1);
      webUri = Uri.parse("https://www.youtube.com/@$username");
      nativeUri = Uri.parse("youtube://user/$username");
    } else if (RegExp(r'^[a-zA-Z0-9_-]{24}$').hasMatch(value)) {
      // Handle channel ID format (24 characters)
      webUri = Uri.parse("https://www.youtube.com/channel/$value");
      nativeUri = Uri.parse("youtube://channel/$value");
    } else if (RegExp(r'^[a-zA-Z0-9_-]{11}$').hasMatch(value)) {
      // Handle video ID format (11 characters)
      webUri = Uri.parse("https://www.youtube.com/watch?v=$value");
      nativeUri = Uri.parse("youtube://watch?v=$value");
    } else {
      // Handle username or custom name
      webUri = Uri.parse("https://www.youtube.com/$value");
      nativeUri = Uri.parse("youtube://user/$value");
    }

    await _launch(nativeUri: nativeUri, webUri: webUri);
  }

  // ============================
  // WHATSAPP
  // ============================
  static Future<void> openWhatsApp(String input) async {
    String value = input.trim();

    Uri nativeUri;
    Uri webUri;

    if (value.startsWith("http")) {
      // Direct WhatsApp link
      webUri = Uri.parse(value);
      nativeUri = webUri;
    } else {
      // Clean number — keep + if present, remove spaces/dashes/brackets
      value = value.replaceAll(RegExp(r'[\s\-().]+'), '');

      // Agar + nahi hai toh assume karo already country code included hai
      // e.g. 919876543210 → wa.me/919876543210
      // e.g. +919876543210 → remove + → wa.me/919876543210
      if (value.startsWith('+')) {
        value = value.substring(1);
      }

      webUri = Uri.parse("https://wa.me/$value");
      nativeUri = Uri.parse("whatsapp://send?phone=$value");
    }

    await _launch(nativeUri: nativeUri, webUri: webUri);
  }

  // ============================
  // TELEGRAM
  // ============================
  static Future<void> openTelegram(String input) async {
    String value = input.trim().replaceAll('@', '');

    Uri nativeUri;
    Uri webUri;

    if (value.startsWith("http")) {
      // Direct telegram link
      webUri = Uri.parse(value);

      if (value.contains("t.me/")) {
        final username = value.split("t.me/").last.split("/").first;
        nativeUri = Uri.parse("tg://resolve?domain=$username");
      } else {
        nativeUri = webUri;
      }
    } else {
      // Username format
      webUri = Uri.parse("https://t.me/$value");
      nativeUri = Uri.parse("tg://resolve?domain=$value");
    }

    await _launch(nativeUri: nativeUri, webUri: webUri);
  }

  // ============================
  // TIKTOK
  // ============================
  static Future<void> openTikTok(String input) async {
    String value = input.trim().replaceAll('@', '');

    Uri nativeUri;
    Uri webUri;

    if (value.startsWith("http")) {
      webUri = Uri.parse(value);

      if (value.contains("tiktok.com/@")) {
        final username = value
            .split("@")
            .last
            .split("/")
            .first
            .split("?")
            .first;

        nativeUri = Uri.parse("snssdk1233://user/profile/$username");
      } else {
        nativeUri = webUri;
      }
    } else {
      webUri = Uri.parse("https://www.tiktok.com/@$value");

      nativeUri = Uri.parse("snssdk1233://user/profile/$value");
    }

    await _launch(nativeUri: nativeUri, webUri: webUri);
  }
}
 