import 'dart:io';

class GZipService {
  GZipService._();

  /// Compresses a list of bytes using GZip.
  static List<int> compress(List<int> bytes) {
    return gzip.encode(bytes);
  }

  /// Decompresses GZip compressed bytes.
  static List<int> decompress(List<int> gzipBytes) {
    return gzip.decode(gzipBytes);
  }
}
